# CI/CD 파이프라인 구현 가이드

## 📋 목차
- [파이프라인 개요](#파이프라인-개요)
- [GitHub Actions 워크플로우](#github-actions-워크플로우)
- [로컬 개발 환경 설정](#로컬-개발-환경-설정)
- [배포 전략](#배포-전략)
- [모니터링 및 알림](#모니터링-및-알림)
- [트러블슈팅](#트러블슈팅)

---

## 파이프라인 개요

이 MLOps 프로젝트의 CI/CD 파이프라인은 다음을 자동화합니다:

### 🔄 주요 단계
1. **코드 검증 (Lint & Test)** - 코드 품질과 테스트 커버리지 확인
2. **보안 스캔 (Security Scan)** - 의존성 취약점과 코드 보안 검사
3. **Docker 빌드 및 푸시** - 컨테이너 이미지 생성 및 레지스트리 업로드
4. **개발 배포 (Deploy Dev)** - develop 브랜치 변경 시 dev 환경 배포
5. **운영 배포 (Deploy Prod)** - main 브랜치 변경 시 prod 환경 배포
6. **스케줄 실행 (Scheduled)** - 매일 자동으로 데이터 수집 및 모델 학습

---

## GitHub Actions 워크플로우

### 파일 구조
```
.github/workflows/
├── ci-cd.yml              # 주 파이프라인
├── code-quality.yml       # 코드 품질 검사
└── release.yml            # 릴리스 자동화
```

### 1. 주 CI/CD 파이프라인 (`ci-cd.yml`)

#### 트리거 조건
```yaml
on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]
  schedule:
    - cron: '0 0 * * *'  # 매일 자정(UTC)
```

#### Job 구성

##### a) **Lint and Test**
- Python 3.9, 3.10, 3.11 다중 버전 테스트
- Black, isort로 코드 포맷 검증
- Flake8으로 코드 스타일 검사
- pytest로 단위 테스트 실행
- Codecov에 커버리지 업로드

```bash
# 로컬에서 실행
pytest data-task/tests/ -v --cov=src --cov=core
```

##### b) **Security Scan**
- Bandit로 보안 취약점 검사
- Safety로 의존성 취약점 확인

```bash
# 로컬에서 보안 검사
bandit -r data-task/src data-task/core
safety check
```

##### c) **Build and Push Docker**
- Docker 이미지 빌드
- GHCR (GitHub Container Registry)에 푸시
- 태그: branch 이름, commit SHA, latest

```bash
# 로컬에서 빌드 (선택사항)
docker build -t mlops:latest ./data-task
```

##### d) **Deploy Dev/Prod**
- 환경별 자격증명 사용
- Slack 알림 발송

---

### 2. 코드 품질 워크플로우 (`code-quality.yml`)

Pull Request 시 실행:
- SonarCloud 코드 분석
- Trivy로 의존성 취약점 검사
- GitHub Security tab에 결과 업로드

---

### 3. 릴리스 워크플로우 (`release.yml`)

Git 태그 생성 시 실행 (e.g., `v0.1.0`):
- 자동 GitHub Release 생성
- 변경사항 추출
- PyPI에 패키지 배포

---

## 로컬 개발 환경 설정

### 사전 요구사항
- Python 3.9+
- Docker & Docker Compose
- kubectl (Kubernetes 배포 시)
- Git

### 1. 환경 변수 설정

```bash
cd data-task
cp .env.template .env
```

`.env` 파일 작성:
```dotenv
TMDB_API_KEY=your_tmdb_api_key
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key
AWS_REGION=us-east-1
S3_BUCKET=your_bucket_name
```

### 2. 의존성 설치

```bash
# Python 환경 설정
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# 패키지 설치
pip install -r data-task/requirements.txt

# 개발 도구 설치
pip install -e data-task[dev]
```

### 3. 로컬 테스트 실행

```bash
cd data-task

# 전체 테스트 실행
pytest tests/ -v

# 커버리지 포함
pytest tests/ --cov=src --cov=core --cov-report=html

# 특정 테스트만 실행
pytest tests/test_collector.py -v
```

### 4. 코드 포매팅

```bash
# 코드 자동 포매팅
black data-task/

# import 정렬
isort data-task/

# 스타일 검사
flake8 data-task/src data-task/core
```

### 5. Docker로 로컬 실행

```bash
# 이미지 빌드
docker build -t mlops:local ./data-task

# 컨테이너 실행
docker run --env-file data-task/.env mlops:local

# Docker Compose로 전체 스택 실행
docker-compose up -d
```

Prometheus: http://localhost:9090
Grafana: http://localhost:3000 (admin/admin)

---

## 배포 전략

### 1. Develop 브랜치 (개발 환경)

```bash
git checkout develop
git push origin feature-branch

# PR 생성 → CI/CD 실행 → Merge → Dev 배포
```

**Deploy Dev Job:**
- 환경: Development
- 자격증명: `AWS_*_DEV`, `TMDB_API_KEY_DEV`
- URL: https://dev.example.com

### 2. Main 브랜치 (운영 환경)

```bash
git checkout main
git pull origin develop

# 커밋이 자동으로 이루어진 경우 Pull Request로 merge
```

**Deploy Prod Job:**
- 환경: Production (승인 필요)
- 자격증명: `AWS_*_PROD`, `TMDB_API_KEY_PROD`
- URL: https://api.example.com
- 알림: Slack 메시지 발송

### 3. 릴리스 버전 관리

```bash
# 버전 태그 생성 (Semantic Versioning)
git tag v0.1.0
git push origin v0.1.0

# 자동으로:
# - GitHub Release 생성
# - PyPI에 배포
# - Docker 이미지 태깅
```

---

## Kubernetes 배포

### 사전 준비

```bash
# kubeconfig 설정
export KUBECONFIG=$HOME/.kube/config

# 네임스페이스 및 리소스 생성
kubectl apply -f k8s/deployment.yaml

# 시크릿 생성
kubectl create secret generic mlops-secrets \
  --from-literal=tmdb-api-key=YOUR_KEY \
  --from-literal=aws-access-key=YOUR_KEY \
  --from-literal=aws-secret-key=YOUR_KEY \
  -n mlops
```

### 배포 확인

```bash
# Pod 상태 확인
kubectl get pods -n mlops

# 로그 확인
kubectl logs -n mlops deployment/mlops-pipeline

# 서비스 접근
kubectl port-forward -n mlops svc/mlops-pipeline-service 8000:80
```

### 스케일링

```bash
# Replica 개수 조정
kubectl scale deployment mlops-pipeline -n mlops --replicas=3
```

---

## 모니터링 및 알림

### Prometheus 메트릭

```yaml
# 수집되는 주요 메트릭:
- pipeline_runs_total         # 파이프라인 실행 횟수
- pipeline_errors_total       # 파이프라인 오류 횟수
- model_rmse                  # 모델 RMSE
- api_request_duration_seconds # API 응답시간
- s3_upload_failures_total    # S3 업로드 실패
```

### 알림 규칙

```yaml
# 주요 알림:
- PipelineHighErrorRate: 오류율 > 10%
- ModelPerformanceDegraded: RMSE > 2.0
- S3UploadFailure: 업로드 실패 발생
- APICallHighLatency: P99 응답시간 > 10s
- ContainerMemoryUsageHigh: 메모리 사용률 > 90%
```

### Slack 알림 설정

1. Slack 워크스페이스에서 Incoming Webhook 생성
2. GitHub Secrets에 `SLACK_WEBHOOK_URL` 추가
3. 파이프라인 자동 알림 활성화

```bash
# GitHub에서 Secret 추가
gh secret set SLACK_WEBHOOK_URL --body "https://hooks.slack.com/..."
```

---

## GitHub Secrets 설정

필수 시크릿 변수들:

```bash
# AWS 자격증명 (Dev/Prod)
AWS_ACCESS_KEY_ID_DEV
AWS_SECRET_ACCESS_KEY_DEV
AWS_ACCESS_KEY_ID_PROD
AWS_SECRET_ACCESS_KEY_PROD
AWS_REGION

# API 키
TMDB_API_KEY_DEV
TMDB_API_KEY_PROD

# S3 버킷
S3_BUCKET

# 외부 서비스
SONAR_TOKEN          # SonarCloud
CODECOV_TOKEN        # Codecov
PYPI_API_TOKEN       # PyPI 배포
SLACK_WEBHOOK_URL    # Slack 알림
GITHUB_TOKEN         # (자동 생성)
```

설정 방법:
```bash
# CLI로 설정 (gh 필요)
gh secret set AWS_ACCESS_KEY_ID_PROD --body "your_key"
```

---

## 트러블슈팅

### 1. 테스트 실패

```bash
# 로컬에서 동일하게 재현
pytest tests/ -v --tb=short

# 특정 테스트 디버깅
pytest tests/test_collector.py::TestTMDBCollector::test_fetch_popular_movies -vv

# Coverage 확인
pytest tests/ --cov=src --cov-report=html
open htmlcov/index.html
```

### 2. Docker 빌드 실패

```bash
# 로컬 빌드 테스트
docker build -t mlops:test ./data-task

# 이미지 검사
docker inspect mlops:test

# 레이어별 빌드 확인
docker build --progress=plain -t mlops:test ./data-task
```

### 3. 배포 실패

```bash
# 파이프라인 로그 확인
# GitHub Actions > 워크플로우 > 실패한 job 클릭

# 로컬에서 환경 변수 검증
echo $TMDB_API_KEY
echo $AWS_ACCESS_KEY_ID
```

### 4. 성능 이슈

```bash
# Prometheus에서 메트릭 확인
curl http://localhost:9090/api/v1/query?query=pipeline_execution_duration_seconds

# 느린 API 호출 파악
# Grafana 대시보드에서 그래프 확인
```

---

## 모범 사례

### ✅ 커밋 메시지 규약
```
feat: 새 기능 추가
fix: 버그 수정
docs: 문서 변경
style: 코드 포매팅 (기능 변화 없음)
refactor: 코드 재구성
test: 테스트 추가/수정
ci: CI/CD 설정 변경
```

예: `feat: add model validation in training pipeline`

### ✅ PR 작성 가이드
- 제목: 간결하고 명확하게
- 설명: 변경사항과 이유 포함
- 관련 Issue: `Closes #123` 명시
- 테스트: 테스트 케이스 추가 필수

### ✅ 릴리스 절차
```bash
# 1. develop에서 최신 코드 확인
git checkout develop
git pull origin

# 2. 버전 태그 생성
git tag v0.2.0

# 3. 푸시 (자동 배포 시작)
git push origin v0.2.0

# 4. GitHub Release 페이지에서 확인
```

---

## 참고 자료

- [GitHub Actions 공식 문서](https://docs.github.com/en/actions)
- [Docker 모범 사례](https://docs.docker.com/develop/dev-best-practices/)
- [Kubernetes 배포 가이드](https://kubernetes.io/docs/tasks/run-application/)
- [Prometheus 메트릭 쿼리](https://prometheus.io/docs/prometheus/latest/querying/)

