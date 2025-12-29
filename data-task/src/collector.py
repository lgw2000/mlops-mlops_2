import requests
import pandas as pd
from pathlib import Path


class TMDBCollector:
    def __init__(self, api_key: str):
        self.api_key = api_key
        self.base_url = "https://api.themoviedb.org/3"
    def fetch_popular_movies(self, page_limit: int = 20) -> pd.DataFrame:
        """20페이지(약 400개)의 인기 영화 데이터를 수집합니다."""
        movie_list = []
         
        print(f"TMDB에서 {page_limit}페이지까지 수집을 시작합니다...")
        for page in range(1, page_limit + 1):
            url = f"{self.base_url}/movie/popular?api_key={self.api_key}&language=ko-KR&page={page}"
            response = requests.get(url)
             
            if response.status_code == 200:
                results = response.json().get('results', [])
                movie_list.extend(results)
                if page % 5 == 0:
                    print(f"진행 중: {page}/{page_limit} 페이지 완료")
            else:
                print(f"페이지 {page} 호출 실패 (Status Code: {response.status_code})")
          
        df = pd.DataFrame(movie_list)
        print(f"총 {len(df)}개의 영화 데이터를 수집했습니다.")
        return df

    def save_raw_data(self, df: pd.DataFrame, date_str: str) -> str:
        """수집된 데이터를 날짜별 raw 경로에 저장합니다."""
        save_path = Path(f"data/raw/{date_str}")
        save_path.mkdir(parents=True, exist_ok=True)
          
        file_full_path = save_path / f"{date_str}.csv"
        df.to_csv(file_full_path, index=False, encoding='utf-8-sig')
        return str(file_full_path)
