import json
from pathlib import Path

import joblib
import pandas as pd
from sklearn.linear_model import LinearRegression
from sklearn.metrics import mean_squared_error


class ModelTrainer:
    def __init__(self, target_column='vote_average'):
        self.target_column = target_column
        self.model = LinearRegression()

    def train(self, data_path: str) -> dict:
        """데이터를 읽어 학습시키고 지표를 반환합니다."""
        df = pd.read_csv(data_path)
        
        # 1. 특성(X)과 타겟(y) 분리
        X = df.drop(columns=[self.target_column])
        y = df[self.target_column]
        
        # 2. 학습 (반드시 self.model 사용)
        self.model.fit(X, y)
        
        # 3. 지표 계산
        y_pred = self.model.predict(X)
        mse = mean_squared_error(y, y_pred)
        r2 = self.model.score(X, y)
        
        return {
            "mse": float(mse),
            "r2": float(r2),
            "features": list(X.columns),
            "sample_count": len(df)
        }

    def save_model(self, output_dir: str, metrics: dict):
        """학습된 모델과 지표를 저장합니다."""
        # sklearn 모델은 학습이 완료되면 'coef_' 속성이 생깁니다.
        if not hasattr(self.model, "coef_"):
            raise ValueError("모델이 아직 학습되지 않았습니다. train()이 성공했는지 확인하세요.")

        path = Path(output_dir)
        path.mkdir(parents=True, exist_ok=True)
        
        # 모델 및 지표 로컬 저장
        joblib.dump(self.model, path / "model.pkl", compress=3)
        with open(path / "metrics.json", 'w') as f:
            json.dump(metrics, f, indent=4)
        
        print(f"로컬 모델 저장 완료: {output_dir}")

    def update_champion_if_better(self, champion_dir: str, new_metrics: dict) -> bool:
        """MSE를 비교하여 챔피언 모델을 업데이트합니다."""
        path = Path(champion_dir)
        path.mkdir(parents=True, exist_ok=True)
        
        json_path = path / "champion_model.json"
        model_path = path / "champion_model.pkl"
        
        is_better = False
        if not json_path.exists():
            is_better = True
        else:
            with open(json_path, 'r') as f:
                old_metrics = json.load(f)
            
            # MSE는 작을수록 좋음
            if new_metrics['mse'] < old_metrics.get('mse', float('inf')):
                is_better = True

        if is_better:
            joblib.dump(self.model, model_path, compress=3)
            with open(json_path, 'w') as f:
                json.dump(new_metrics, f, indent=4)
            return True
        return False
