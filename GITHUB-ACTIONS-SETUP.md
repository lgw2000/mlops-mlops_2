# GitHub Secrets & Actions 설정 가이드

## 📋 필수 GitHub Secrets 설정

CI/CD 파이프라인을 정상 작동하려면 다음 시크릿을 설정해야 합니다.

### 1. 설정 방법

#### 방법 1: GitHub 웹 UI
1. Repository > Settings > Secrets and variables > Actions
2. "New repository secret" 클릭
3. 이름과 값 입력

#### 방법 2: GitHub CLI
```bash
# 로그인 (처음 한 번만)
gh auth login

# 시크릿 추가
gh secret set SECRET_NAME --body "secret_value"
```

#### 방법 3: 배치 스크립트
```bash
#!/bin/bash
# scripts/setup-secrets.sh

gh secret set AWS_ACCESS_KEY_ID_PROD --body "$AWS_ACCESS_KEY_ID_PROD"
gh secret set AWS_SECRET_ACCESS_KEY_PROD --body "$AWS_SECRET_ACCESS_KEY_PROD"
gh secret set AWS_REGION --body "us-east-1"
gh secret set TMDB_API_KEY_PROD --body "$TMDB_API_KEY_PROD"
gh secret set S3_BUCKET --body "$S3_BUCKET"

echo "✅ All secrets set successfully"
```

### 2. AWS 자격증명

#### Development 환경
```
AWS_ACCESS_KEY_ID_DEV        → AWS IAM Access Key ID
AWS_SECRET_ACCESS_KEY_DEV    → AWS IAM Secret Access Key
```

#### Production 환경
```
AWS_ACCESS_KEY_ID_PROD       → AWS IAM Access Key ID
AWS_SECRET_ACCESS_KEY_PROD   → AWS IAM Secret Access Key
AWS_REGION                   → us-east-1 (또는 원하는 region)
```

**AWS 자격증명 생성 방법:**
```bash
# AWS CLI 설치
aws configure

# 생성된 자격증명 확인
cat ~/.aws/credentials
```

### 3. API 키

#### TMDB API
```
TMDB_API_KEY_DEV             → TMDB API Key (개발용)
TMDB_API_KEY_PROD            → TMDB API Key (운영용)
```

[TMDB 가입 및 API 키 발급](https://www.themoviedb.org/settings/api)

### 4. 저장소 설정

```
S3_BUCKET                    → S3 버킷 이름 (예: mlops-models)
```

### 5. 외부 서비스 (선택사항)

#### SonarCloud
```
SONAR_TOKEN                  → SonarCloud 토큰
```
[SonarCloud 설정](https://sonarcloud.io/)

#### PyPI (패키지 배포)
```
PYPI_API_TOKEN               → PyPI API 토큰
```
[PyPI 토큰 생성](https://pypi.org/help/#apitoken)

#### Codecov (커버리지)
```
CODECOV_TOKEN                → Codecov 토큰 (선택사항)
```
[Codecov 설정](https://codecov.io/)

#### Slack (알림)
```
SLACK_WEBHOOK_URL            → Slack Incoming Webhook URL
```

**Slack Webhook 생성:**
1. [Slack 앱 생성](https://api.slack.com/apps/new)
2. Features > Incoming Webhooks 활성화
3. "New Webhook to Workspace" 클릭
4. 채널 선택 및 생성
5. Webhook URL 복사

---

## GitHub Actions 환경 변수

### 파이프라인 변수 (Secrets 불필요)

`.github/workflows/ci-cd.yml`에서 정의:

```yaml
env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}
  PYTHON_VERSION: '3.10'
```

### 실행 시간 변수

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    env:
      BUILD_ENV: production
    steps:
      - run: echo $BUILD_ENV
```

---

## 🔧 자동 설정 스크립트

### 1. 전체 환경 설정

```bash
#!/bin/bash
# scripts/setup-ci-cd.sh

set -e

REPO_URL="https://github.com/NullXeronier/mlops-mlops_2"

echo "🚀 MLOps CI/CD 자동 설정 시작..."

# 1. GitHub CLI 로그인 확인
if ! gh auth status > /dev/null 2>&1; then
    echo "❌ GitHub CLI 로그인 필요"
    gh auth login
fi

# 2. 필수 시크릿 확인
read -p "AWS Access Key ID (Prod): " AWS_KEY
read -p "AWS Secret Access Key (Prod): " AWS_SECRET
read -p "TMDB API Key (Prod): " TMDB_KEY
read -p "S3 Bucket Name: " S3_BUCKET
read -p "Slack Webhook URL (선택사항): " SLACK_URL

# 3. 시크릿 설정
echo "⚙️  GitHub Secrets 설정 중..."

gh secret set AWS_ACCESS_KEY_ID_PROD --body "$AWS_KEY"
gh secret set AWS_SECRET_ACCESS_KEY_PROD --body "$AWS_SECRET"
gh secret set TMDB_API_KEY_PROD --body "$TMDB_KEY"
gh secret set S3_BUCKET --body "$S3_BUCKET"
gh secret set AWS_REGION --body "us-east-1"

if [ ! -z "$SLACK_URL" ]; then
    gh secret set SLACK_WEBHOOK_URL --body "$SLACK_URL"
fi

# 4. 개발 환경 시크릿 (선택사항)
read -p "개발 환경 시크릿도 설정하시겠습니까? (y/n): " SETUP_DEV

if [ "$SETUP_DEV" = "y" ]; then
    read -p "AWS Access Key ID (Dev): " AWS_KEY_DEV
    read -p "AWS Secret Access Key (Dev): " AWS_SECRET_DEV
    read -p "TMDB API Key (Dev): " TMDB_KEY_DEV
    
    gh secret set AWS_ACCESS_KEY_ID_DEV --body "$AWS_KEY_DEV"
    gh secret set AWS_SECRET_ACCESS_KEY_DEV --body "$AWS_SECRET_DEV"
    gh secret set TMDB_API_KEY_DEV --body "$TMDB_KEY_DEV"
fi

echo "✅ CI/CD 설정 완료!"
echo ""
echo "다음 단계:"
echo "1. Repository Settings에서 Branch Protection Rules 설정"
echo "2. Pull Request에서 최소 검토자 수 설정"
echo "3. 첫 번째 커밋 푸시로 파이프라인 테스트"
```

### 2. 설정 검증 스크립트

```bash
#!/bin/bash
# scripts/verify-secrets.sh

echo "🔍 GitHub Secrets 검증 중..."

REQUIRED_SECRETS=(
    "AWS_ACCESS_KEY_ID_PROD"
    "AWS_SECRET_ACCESS_KEY_PROD"
    "TMDB_API_KEY_PROD"
    "S3_BUCKET"
    "AWS_REGION"
)

MISSING=0

for secret in "${REQUIRED_SECRETS[@]}"; do
    if gh secret list | grep -q "^$secret"; then
        echo "✅ $secret"
    else
        echo "❌ $secret (누락됨)"
        MISSING=$((MISSING + 1))
    fi
done

if [ $MISSING -eq 0 ]; then
    echo ""
    echo "✅ 모든 필수 시크릿이 설정되어 있습니다!"
    exit 0
else
    echo ""
    echo "❌ $MISSING개의 시크릿이 누락되었습니다"
    exit 1
fi
```

---

## 🛡️ 보안 모범 사례

### 1. Secrets 관리
- ✅ 최소 권한 원칙 준수 (Least Privilege)
- ✅ 정기적으로 자격증명 갱신
- ✅ 로그에 민감한 정보 출력 금지

```yaml
# ❌ 나쁜 예
- run: echo "API Key: ${{ secrets.API_KEY }}"

# ✅ 좋은 예
- run: curl -H "Authorization: Bearer ${{ secrets.API_KEY }}" ...
```

### 2. 액세스 제어
- ✅ 환경별(Dev/Prod) 별도의 자격증명 사용
- ✅ GitHub Environment 보호 규칙 설정
- ✅ 브랜치 보호 규칙 활성화

### 3. 감사 로그
```bash
# GitHub 감사 로그 확인
gh api repos/NullXeronier/mlops-mlops_2/audit-log
```

---

## 🚀 첫 배포 체크리스트

- [ ] GitHub 저장소 생성 및 코드 푸시
- [ ] 모든 필수 Secrets 설정
- [ ] Branch Protection Rules 구성
- [ ] AWS IAM Role 설정
- [ ] S3 버킷 생성
- [ ] TMDB API 키 발급
- [ ] Slack Webhook 설정
- [ ] 첫 번째 커밋 푸시 및 파이프라인 실행 확인

---

## 📊 모니터링

### 파이프라인 실행 확인

```bash
# 최근 워크플로우 실행 확인
gh run list

# 특정 워크플로우 상세 확인
gh run view <run-id>

# 로그 다운로드
gh run download <run-id> --dir ./logs
```

### 액션 사용량 확인

Settings > Billing and plans > Actions에서 확인

---

## 🔗 참고 링크

- [GitHub Actions 공식 문서](https://docs.github.com/en/actions)
- [GitHub Secrets 관리](https://docs.github.com/en/actions/security-guides/using-secrets-in-github-actions)
- [GitHub Environments](https://docs.github.com/en/actions/deployment/targeting-different-environments)
- [OIDC 이용한 AWS 인증](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments)
