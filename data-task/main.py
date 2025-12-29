import os
import fire
import wandb
import traceback
from datetime import datetime
from dotenv import load_dotenv

from core.config import TMDB_API_KEY
from core.s3_client import S3Manager
from src.collector import TMDBCollector
from src.preprocessor import Preprocessor
from src.train import ModelTrainer

class Pipeline:
    def __init__(self):
        load_dotenv()
        self.date_str = datetime.now().strftime("%Y%m%d")
        self.s3 = S3Manager()
        self.collector = TMDBCollector(TMDB_API_KEY)
        self.preprocessor = Preprocessor()
        self.trainer = ModelTrainer(target_column='vote_average')
        
        # 로컬 작업 디렉토리 생성 보장
        os.makedirs("data/raw", exist_ok=True)
        os.makedirs("data/processed", exist_ok=True)
        os.makedirs("data/output", exist_ok=True)

    def collect(self, page_limit=20):
        """Step 1: 데이터 수집 및 S3 업로드"""
        print(f"--- Step 1: Fetching data ({self.date_str}) ---")
        try:
            df_raw = self.collector.fetch_popular_movies(page_limit=page_limit)
            local_raw = self.collector.save_raw_data(df_raw, self.date_str)
            self.s3.upload_file(local_raw, f"raw/{self.date_str}")
            print(f"Success: Raw data uploaded to S3: raw/{self.date_str}")
            return local_raw
        except Exception as e:
            print(f"Error: Collection failed: {e}")
            traceback.print_exc()

    def preprocess(self, s3_raw_path=None):
        """Step 2: S3에서 Raw 데이터 다운로드 후 전처리"""
        print(f"--- Step 2: Preprocessing ({self.date_str}) ---")
        
        # 1. S3 경로가 지정되지 않았다면 기본값 설정
        if not s3_raw_path:
            s3_raw_path = f"raw/{self.date_str}/{self.date_str}.csv"
        
        local_raw_path = f"data/raw/{self.date_str}/{self.date_str}.csv"

        try:
            # 2. S3에서 파일 다운로드 
            print(f"Downloading raw data from S3: {s3_raw_path}")
            self.s3.download_file(s3_raw_path, local_raw_path)
            
            # 3. 전처리 수행
            df_processed = self.preprocessor.transform(local_raw_path)
            local_processed = self.preprocessor.save_processed_data(df_processed, self.date_str)
            
            # 4. 결과 업로드
            self.s3.upload_file(local_processed, f"processed/{self.date_str}")
            print(f"Success: Processed data uploaded to S3: processed/{self.date_str}")
            return local_processed
        except Exception as e:
            print(f"Error: Preprocessing failed: {e}")
            traceback.print_exc()

    def train(self, s3_processed_path=None, model_name="v1"):
        print(f"--- Step 3 & 4: Training & Champion Check ({self.date_str}) ---")
        
        # 1. 경로 설정 (반드시 파일명까지 포함)
        champ_dir = "data/champion"
        out_dir = "data/output"
        local_champ_json = f"{champ_dir}/champion_model.json"
        local_champ_pkl = f"{champ_dir}/champion_model.pkl"

        run = wandb.init(
            project="tmdb-mlops",
            name=f"run-{self.date_str}-{model_name}",
            config={"date": self.date_str}
        )
        
        # 2. S3에서 기존 챔피언 다운로드 시도
        try:
            print("Checking for existing champion in S3...")
            # S3에서 파일을 다운로드해보고, 없으면 except로 이동
            self.s3.download_file("models/champion/champion_model.json", local_champ_json)
            self.s3.download_file("models/champion/champion_model.pkl", local_champ_pkl)
        except Exception as e:
            print(f"No existing champion found in S3 (This is normal for the first run).")

        # 3. 모델 학습
        local_processed_path = f"data/processed/{self.date_str}/processed_data.csv"
        metrics = self.trainer.train(local_processed_path)
        wandb.log(metrics)

        # 4. 모델 저장
        print(f"Archiving current model to S3: models/archive/{self.date_str}/")
        self.trainer.save_model(out_dir, metrics) # data/output/{date}/ 에 저장됨
        
        self.s3.upload_file(f"{out_dir}/model.pkl", f"models/archive/{self.date_str}/model.pkl")
        self.s3.upload_file(f"{out_dir}/metrics.json", f"models/archive/{self.date_str}/metrics.json")

        # 5. 챔피언 비교 수행
        print("Comparing current model with champion...")
        update_needed = self.trainer.update_champion_if_better(champ_dir, metrics)
        print(f"Update needed? : {update_needed}")

        if (update_needed):
            print("SUCCESS: New champion detected. Starting S3 upload...")
            
            if os.path.exists(local_champ_json) and os.path.exists(local_champ_pkl):
                self.s3.upload_file(local_champ_json, "models/champion/champion_model.json")
                self.s3.upload_file(local_champ_pkl, "models/champion/champion_model.pkl")
                print("S3 Upload Complete: models/champion/champion_model.json")
            else:
                print(f"ERROR: Files to upload not found! Path: {local_champ_json}")
        else:
            print("INFO: Champion maintained. No S3 upload performed.")

        wandb.finish()


    def run_all(self):
        """전체 파이프라인 시뮬레이션 (순차 실행)"""
        self.collect()
        self.preprocess()
        self.train()

if __name__ == "__main__":
    fire.Fire(Pipeline)
