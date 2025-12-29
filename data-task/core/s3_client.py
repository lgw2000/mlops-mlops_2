from pathlib import Path

import boto3

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

    def get_file_list(self, prefix: str) -> list[str]:

        # 접두사(prefix)가 폴더 형태인 경우 '/'로 끝나도록 보정
        if prefix and not prefix.endswith('/'):
            prefix += '/'
        response = self.s3_client.list_objects_v2(
            Bucket=self.bucket_name,
            Prefix=prefix
        )
        if 'Contents' not in response:
            print(f"조회 결과: {prefix} 경로에 파일이 없습니다.")
            return []

        # 파일 경로(Key) 목록 추출
        file_list = [obj['Key'] for obj in response['Contents'] if obj['Key'] != prefix]

        # 정렬하여 반환
        return sorted(file_list)


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


    def download_file(self, s3_key: str, local_dir: str) -> tuple[bool, str | None]:
        """S3파일이 있으면 다운로드, 없으면 해당 경로의 파일 목록을 출력"""
        filename = Path(s3_key).name
        local_save_path = Path(local_dir) / filename
        
        try:
            # 파일 존재 여부 확인
            self.s3.head_object(Bucket=self.bucket_name, Key=s3_key)

            # 파일이 존재하면 다운로드 진행
            local_save_path.parent.mkdir(parents=True, exist_ok=True)
            self.s3.download_file(self.bucket_name, s3_key, str(local_save_path))
            print(f"{s3_key} -> {local_save_path}에 다운로드 완료.")
            return True, str(local_save_path)

        except Exception as e:
            # 파일이 없을 경우 예외처리
            print(f"S3에 {s3_key} 파일이 없습니다")

            # 파일 목록 보여주기
            forder_path = '/'.join(s3_key.split('/')[:-1])
            self.check_file_in_folder(forder_path)
            return False, None


if __name__ == '__main__':
    s3 = S3Manager()
    s3.check_all_data()
    s3.check_folders()
    s3.check_file_in_folder("raw")
