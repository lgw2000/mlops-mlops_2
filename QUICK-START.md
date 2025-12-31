# 🚀 CI/CD 파이프라인 빠른 시작 가이드

## 5분 안에 CI/CD 파이프라인 설정하기

### 📋 사전 요구사항

- GitHub 계정 및 저장소
- GitHub CLI (`gh`) 설치 ([설치 가이드](https://cli.github.com))
- AWS 자격증명
- TMDB API 키

### 🏃 빠른 시작

#### 1단계: 자동 설정 스크립트 실행 (권장)

```bash
cd mlops-mlops_2

# 자동 설정 실행
bash scripts/setup-ci-cd.sh

# 또는 한 줄로
curl -fsSL https://raw.githubusercontent.com/NullXeronier/mlops-mlops_2/main/scripts/setup-ci-cd.sh | bash
```

자동 설정 중에 다음 정보를 입력하세요:
- AWS Access Key ID (Prod)
- AWS Secret Access Key (Prod)
- TMDB API Key (Prod)
- S3 Bucket 이름

#### 2단계: 수동 설정 (자동 설정 스크립트 사용 안 함)

```bash
# GitHub CLI 로그인
gh auth login

# 필수 시크릿 설정
gh secret set AWS_ACCESS_KEY_ID_PROD --body "your_access_key"
gh secret set AWS_SECRET_ACCESS_KEY_PROD --body "your_secret_key"
gh secret set TMDB_API_KEY_PROD --body "your_tmdb_key"
gh secret set S3_BUCKET --body "your_bucket_name"
gh secret set AWS_REGION --body "us-east-1"

# 선택사항: Slack 알림
gh secret set SLACK_WEBHOOK_URL --body "your_webhook_url"
```

#### 3단계: 시크릿 검증

```bash
bash scripts/verify-secrets.sh
```

#### 4단계: Branch Protection 설정 (선택사항)

GitHub Repository Settings > Branches에서:
- `main` 브랜치에 대해 "Require pull request before merging" 활성화
- "Require status checks to pass before merging" 활성화

#### 5단계: 파이프라인 테스트

```bash
# 코드 변경 없이 파이프라인 수동 실행
gh workflow run ci-cd.yml --ref main

# 또는 코드 푸시로 자동 실행
git commit --allow-empty -m "test: trigger ci-cd pipeline"
git push origin main
```

파이프라인 상태 확인:
```bash
https://github.com/NullXeronier/mlops-mlops_2/actions
```

---

## 🎯 핵심 워크플로우

### 개발 프로세스

```bash
# 1. 새 기능 브랜치 생성
git checkout -b feature/add-new-feature

# 2. 개발 및 테스트
# ... 코드 작성 ...
pytest data-task/tests/

# 3. 로컬 포매팅
black data-task/
isort data-task/

# 4. 커밋 및 푸시
git add .
git commit -m "feat: add new feature"
git push origin feature/add-new-feature

# 5. GitHub에서 Pull Request 생성
# CI/CD 파이프라인 자동 실행 확인

# 6. Code Review 후 merge
```

### 배포 프로세스

```
개발 (develop 브랜치)
    ↓
Feature 브랜치에서 develop으로 PR
    ↓
CI/CD 테스트 통과
    ↓
Dev 환경 자동 배포
    ↓
운영 (main 브랜치)
    ↓
develop에서 main으로 PR
    ↓
CI/CD 테스트 + 승인
    ↓
Prod 환경 자동 배포
```

---

## 📊 파이프라인 상태 확인

### GitHub Actions 대시보드
```
Repository > Actions > Workflows
```

### 커맨드라인
```bash
# 최근 워크플로우 실행 확인
gh run list --limit 5

# 특정 워크플로우 상태 확인
gh run view <run-id>

# 워크플로우 로그 다운로드
gh run download <run-id> --dir ./logs
```

---

## 🔧 일반적인 문제 해결

### ❌ "Secret not found" 에러

```bash
# 시크릿 다시 설정
gh secret set SECRET_NAME --body "value"

# 설정된 시크릿 확인
gh secret list
```

### ❌ Docker 빌드 실패

```bash
# 로컬 빌드 테스트
docker build -t test ./data-task

# 에러 메시지 확인
docker logs <container-id>
```

### ❌ 테스트 실패

```bash
# 로컬에서 동일 테스트 실행
cd data-task
pytest tests/ -v

# 커버리지 확인
pytest tests/ --cov=src --cov-report=html
open htmlcov/index.html
```

### ❌ AWS 배포 실패

```bash
# AWS 자격증명 확인
aws sts get-caller-identity

# S3 버킷 접근 확인
aws s3 ls
```

---

## 📚 추가 리소스

| 문서 | 설명 |
|------|------|
| [CI-CD-GUIDE.md](CI-CD-GUIDE.md) | 전체 CI/CD 파이프라인 상세 가이드 |
| [GITHUB-ACTIONS-SETUP.md](GITHUB-ACTIONS-SETUP.md) | GitHub Actions 심화 설정 |
| [README.md](README.md) | 프로젝트 개요 |

---

## 🚨 중요 사항

### 🔐 보안
- ❌ 절대 Secrets을 코드에 하드코딩하지 마세요
- ✅ GitHub Secrets 또는 환경 변수 사용
- ❌ 로그에 민감한 정보 출력 금지

### 📝 커밋 메시지 규약
```
feat:  새 기능
fix:   버그 수정
docs:  문서 변경
test:  테스트 추가
ci:    CI/CD 설정 변경
```

예: `feat: add data validation in preprocessing`

### ✅ 테스트 필수
모든 PR은 다음 검사를 통과해야 합니다:
- ✓ Lint (Black, isort, Flake8)
- ✓ Unit Tests (pytest)
- ✓ Security Scan (Bandit)

---

## 💡 팁

### 스케줄 파이프라인 확인
```bash
# 매일 자정(UTC)에 실행
cron: '0 0 * * *'

# 변경하려면:
# .github/workflows/ci-cd.yml 수정
# schedule 섹션 변경
```

### 로컬 Docker 테스트
```bash
# 이미지 빌드
docker build -t mlops:local ./data-task

# 환경 변수와 함께 실행
docker run --env-file data-task/.env mlops:local

# Docker Compose로 전체 스택 실행
docker-compose up -d
```

### 로컬 Kubernetes 테스트 (선택사항)
```bash
# minikube 또는 Docker Desktop Kubernetes 활용
kubectl apply -f k8s/deployment.yaml
kubectl get pods -n mlops
```

---

## ✨ 다음 단계

1. [CI-CD-GUIDE.md](CI-CD-GUIDE.md) 읽기
2. GitHub Environments 보호 규칙 설정
3. Slack 알림 통합
4. 모니터링 대시보드 구성 (Prometheus + Grafana)
5. 성능 메트릭 수집 및 분석

---

## 🆘 추가 도움

### GitHub Actions 공식 문서
- https://docs.github.com/en/actions

### 문제 리포트
```bash
# 이슈 생성
gh issue create --title "CI/CD 문제" --body "상세 설명"
```

---

## 📞 연락처

질문이나 제안사항은 GitHub Issues에서 토론해주세요!
