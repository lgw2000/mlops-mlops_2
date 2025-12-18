import boto3
from pathlib import Path
try:
    from . import config as cfg
except ImportError:
    import config as cfg


class S3Manager:
    def __init__(self):   
        self.s3 = boto3.client(
            's3',
            aws_access_key_id = cfg.aws_access_key_id,
            aws_secret_access_key = cfg.aws_secret_access_key,
            region_name = cfg.region_name
        )
        self.bucket_name = cfg.bucket_name

    def check_all_data(self):
        try:   
            response = self.s3.list_objects_v2(Bucket=self.bucket_name)
            print("--- 내 S3 버킷 파일 목록 ---")
            if 'Contents' in response:
                for obj in response['Contents']:
                    print(obj['Key'])
            else:
                print("버킷이 비어 있습니다.")
        except Exception as e:
            print(f"연결 실패: {e}")


    def check_file_in_folder(self, folder_name: str):
        if not folder_name.endswith('/'):
            folder_name += '/'
        try:
            response = self.s3.list_objects_v2(
                Bucket=self.bucket_name,
                Prefix=folder_name
            )
            print(f"--- [{folder_name}] 폴더 내 파일 목록 ---")
            if 'Contents' in response:
                for obj in response['Contents']:
                    print(f"Key: {obj['Key']} | Size: {obj['Size']} bytes")
            else:
                print("파일이 없습니다.")

        except Exception as e:
            print(f"목록 조회 실패: {e}")


    def check_folders(self):
        try:
            response = self.s3.list_objects_v2(
                Bucket=self.bucket_name,
                Delimiter='/'
            )

            print(f"--- [{self.bucket_name}] 내 폴더 목록 ---")

            if 'CommonPrefixes' in response:
                for prefix in response['CommonPrefixes']:
                    print(f" 폴더명: {prefix['Prefix']}")
            else:
                print("생성된 폴더가 없습니다.")

        except Exception as e:
            print(f"폴더 조회 실패: {e}")


    def upload_file(self, local_path, s3_path):
        filename = Path(local_path).name
        s3_path = f"{s3_path}/{filename}"
        try:
            self.s3.upload_file(local_path, self.bucket_name, s3_path)
            print(f"{s3_path}에 업로드 완료.")
        except Exception as e:
            print(f"업로드 실패: {e}")


    def download_file(self, s3_path, local_path):
        try:
            self.s3.download_file(self.bucket_name, s3_path, local_path)
            print(f"{local_path}에 다운로드 완료.")
        except Exception as e:
            print(f"다운로드 실패: {e}")


if __name__ == '__main__':
    s3 = S3Manager()
    s3.check_all_data()
    s3.check_folders()
    s3.check_file_in_folder("raw")
