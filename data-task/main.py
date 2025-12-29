import os
import traceback
from datetime import datetime

from core.config import TMDB_API_KEY
from core.s3_client import S3Manager
from dotenv import load_dotenv
from src.collector import TMDBCollector
from src.preprocessor import Preprocessor
from src.train import ModelTrainer


def main():
    # 환경 설정 및 초기화
    load_dotenv()
    date_str = datetime.now().strftime("%Y%m%d")
    print(f"--- Pipeline Start: {date_str} ---")
    
    s3 = S3Manager()
    collector = TMDBCollector(TMDB_API_KEY)
    preprocessor = Preprocessor()
    trainer = ModelTrainer(target_column='vote_average')

    try:
        # 1. 데이터 수집 (Raw)
        print("Step 1: Fetching data from TMDB...")
        df_raw = collector.fetch_popular_movies(page_limit=20)
        local_raw = collector.save_raw_data(df_raw, date_str)
        s3.upload_file(local_raw, f"raw/{date_str}")
        print(f"Step 1 Complete: Raw data uploaded to S3 (raw/{date_str})")

        # 2. 데이터 전처리 (Processed)
        print("Step 2: Preprocessing data...")
        df_processed = preprocessor.transform(local_raw)
        local_processed = preprocessor.save_processed_data(df_processed, date_str)
        s3.upload_file(local_processed, f"processed/{date_str}")
        print(f"Step 2 Complete: Processed data uploaded to S3 (processed/{date_str})")

        # 3. 모델 학습 및 아카이브 저장
        print("Step 3: Training model and archiving...")
        metrics = trainer.train(local_processed)
        out_dir = f"data/output/{date_str}"
        trainer.save_model(out_dir, metrics)
        
        # 모델 파일 S3 아카이브 전송
        s3.upload_file(f"{out_dir}/model.pkl", f"models/archive/{date_str}")
        s3.upload_file(f"{out_dir}/metrics.json", f"models/archive/{date_str}")
        print(f"Step 3 Complete: Model and metrics archived to S3 (models/archive/{date_str})")

        # 4. 챔피언 모델 업데이트 비교
        print("Step 4: Comparing with champion model...")
        champ_dir = "data/champion"
        if trainer.update_champion_if_better(champ_dir, metrics):
            # 챔피언 교체 시 S3 업데이트
            s3.upload_file(f"{champ_dir}/champion_model.pkl", "models/champion")
            s3.upload_file(f"{champ_dir}/champion_model.json", "models/champion")
            print("Step 4 Result: New champion model deployed to S3.")
        else:
            print("Step 4 Result: Current champion model maintained.")

    except Exception as e:
        print(f"Error occurred during pipeline: {e}")
        traceback.print_exc()

    print(f"--- Pipeline Finished: {date_str} ---")

if __name__ == "__main__":
    main()
