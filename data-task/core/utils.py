import os
from datetime import datetime

import pandas as pd


def save_to_local(base_dir: str, df: pd.DataFrame) -> tuple[bool, str]:
    try:
        if not os.path.exists(base_dir):
            os.makedirs(base_dir)
            print(f"디렉터리 생성 완료: {base_dir}")
        
        timestamp = datetime.now().strftime("%Y%m%d"+"_"+"%H%M%S")
        filename = f"{timestamp}.csv"

        local_path = os.path.join(base_dir, filename)
        
        df.to_csv(local_path, index=False)
        print(f"로컬 저장 완료: {local_path}")
        return True, local_path

    except Exception as e:
        print(f"로컬 저장 실패: {e}")
        return False, ""

