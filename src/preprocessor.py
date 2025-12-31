from pathlib import Path

import pandas as pd


class Preprocessor:
    def transform(self, local_raw_path: str) -> pd.DataFrame:
        """Raw 데이터를 읽어 선형 회귀용 수치 데이터로 변환합니다."""
        df = pd.read_csv(local_raw_path)
        
        # 1. 학습에 사용할 수치형 특성(Feature)과 타겟(Target) 선택
        # 특성: popularity(인기도), vote_count(투표수)
        # 타겟: vote_average(평점)
        features_and_target = ['popularity', 'vote_count', 'vote_average']
        
        # 2. 필요한 컬럼만 추출 (존재하지 않는 컬럼 제외)
        df_processed = df[df.columns.intersection(features_and_target)].copy()
        
        # 3. 결측치 제거
        # 평점이나 인기도가 0이거나 데이터가 없는 행은 학습에 방해가 되므로 삭제
        df_processed = df_processed.dropna()
        df_processed = df_processed[(df_processed != 0).all(axis=1)]
        
        print(f"전처리 전: {len(df)}행 -> 전처리 후: {len(df_processed)}행")
        return df_processed

    def save_processed_data(self, df: pd.DataFrame, date_str: str) -> str:
        """정제된 데이터를 processed 경로에 저장합니다."""
        save_path = Path(f"data/processed/{date_str}")
        save_path.mkdir(parents=True, exist_ok=True)
        
        file_path = save_path / "processed_data.csv"
        df.to_csv(file_path, index=False)
        return str(file_path)
