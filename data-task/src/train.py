import pandas as pd
import joblib
import json
import os
import shutil
from pathlib import Path
from sklearn.linear_model import LinearRegression
from sklearn.metrics import mean_squared_error

class ModelTrainer:
    def __init__(self, target_column='vote_average'):
        self.target_column = target_column
        self.model = LinearRegression()

    def train(self, data_path: str) -> dict:
        """데이터를 읽어 학습시키고 지표를 반환합니다."""
        df = pd.read_csv(data_path)

        # 타겟 컬럼이 존재하지 않을 경우를 대비한 안전 장치
        if self.target_column not in df.columns:
            raise ValueError(f"Target column '{self.target_column}' not found in dataset.")

        X = df.drop(columns=[self.target_column])
        y = df[self.target_column]

        self.model.fit(X, y)

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
        """학습된 모델과 지표를 로컬에 저장합니다."""
        if not hasattr(self.model, "coef_"):
            raise ValueError("모델이 아직 학습되지 않았습니다.")

        path = Path(output_dir)
        path.mkdir(parents=True, exist_ok=True)

        joblib.dump(self.model, path / "model.pkl", compress=3)
        with open(path / "metrics.json", 'w') as f:
            json.dump(metrics, f, indent=4)

        print(f"Local model and metrics saved to: {output_dir}")

    def update_champion_if_better(self, champion_dir: str, new_metrics: dict) -> bool:
        """기존 챔피언과 MSE를 비교하여 업데이트 여부를 결정합니다."""
        path = Path(champion_dir)
        path.mkdir(parents=True, exist_ok=True)

        json_path = path / "champion_model.json"
        model_path = path / "champion_model.pkl"

        # 디렉토리로 꼬여있는 경우 삭제
        for p in [json_path, model_path]:
            if p.is_dir():
                shutil.rmtree(p)

        is_better = False

        # 1. 기존 챔피언 정보가 없는 경우 (무조건 승격)
        if not json_path.exists():
            print("No existing champion metrics found. Promoting current model to champion.")
            is_better = True
        else:
            try:
                with open(json_path, 'r') as f:
                    old_metrics = json.load(f)

                old_mse = old_metrics.get('mse', float('inf'))
                
                # [개선] 성능이 완벽히 같더라도 첫 등록 시에는 True가 되도록 하거나 
                # 부동소수점 오차를 감안하여 비교
                if new_metrics['mse'] < old_mse:
                    print(f"SUCCESS: New model is better. (New: {new_metrics['mse']:.6f}, Old: {old_mse:.6f})")
                    is_better = True
                else:
                    print(f"KEEP: Champion is still better or equal. (New: {new_metrics['mse']:.6f}, Old: {old_mse:.6f})")
            
            except Exception as e:
                print(f"Error comparing metrics: {e}. Defaulting to true.")
                is_better = True

        # 2. 승격이 확정된 경우 로컬 파일 쓰기
        if is_better:
            joblib.dump(self.model, model_path, compress=3)
            with open(json_path, 'w') as f:
                json.dump(new_metrics, f, indent=4)
            print(f"Champion files updated locally in {champion_dir}")
        
        return is_better
