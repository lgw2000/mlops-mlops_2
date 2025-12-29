import os
from dotenv import load_dotenv


# .env파일 로드
load_dotenv()

# AWS Setting
aws_access_key_id = os.getenv('AWS_ACCESS_KEY_ID')
aws_secret_access_key = os.getenv('AWS_SECRET_ACCESS_KEY')
region_name=os.getenv('AWS_REGION', 'ap-northeast-2')
bucket_name=os.getenv('S3_BUCKET')

# TMDB Settings
TMDB_API_KEY = os.getenv("TMDB_API_KEY")
TMDB_BASE_URL = "https://api.themoviedb.org/3"

# WANDB Setting
WANDB_API_KEY = os.getenv('WANDB_API_KEY')
