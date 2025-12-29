#!/bin/bash
# scripts/verify-secrets.sh
# GitHub Secrets 검증 스크립트

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# GitHub CLI 확인
if ! command -v gh &> /dev/null; then
    print_error "GitHub CLI가 설치되지 않았습니다"
    exit 1
fi

if ! gh auth status > /dev/null 2>&1; then
    print_error "GitHub 로그인이 필요합니다"
    gh auth login
fi

print_header "GitHub Secrets 검증"

# 필수 시크릿
REQUIRED_SECRETS=(
    "AWS_ACCESS_KEY_ID_PROD"
    "AWS_SECRET_ACCESS_KEY_PROD"
    "TMDB_API_KEY_PROD"
    "S3_BUCKET"
    "AWS_REGION"
)

# 선택사항 시크릿
OPTIONAL_SECRETS=(
    "SLACK_WEBHOOK_URL"
    "AWS_ACCESS_KEY_ID_DEV"
    "AWS_SECRET_ACCESS_KEY_DEV"
    "TMDB_API_KEY_DEV"
    "SONAR_TOKEN"
    "PYPI_API_TOKEN"
)

# 모든 시크릿 목록 조회
echo -e "${YELLOW}시크릿 확인 중...${NC}\n"

ALL_SECRETS=$(gh secret list)

echo -e "${YELLOW}필수 시크릿:${NC}"
MISSING=0

for secret in "${REQUIRED_SECRETS[@]}"; do
    if echo "$ALL_SECRETS" | grep -q "^$secret"; then
        print_success "$secret"
    else
        print_error "$secret (누락됨)"
        MISSING=$((MISSING + 1))
    fi
done

echo ""
echo -e "${YELLOW}선택사항 시크릿:${NC}"

for secret in "${OPTIONAL_SECRETS[@]}"; do
    if echo "$ALL_SECRETS" | grep -q "^$secret"; then
        print_success "$secret"
    else
        print_warning "$secret (설정 안 됨)"
    fi
done

echo ""
print_header "검증 결과"

if [ $MISSING -eq 0 ]; then
    print_success "모든 필수 시크릿이 설정되어 있습니다!"
    echo ""
    echo "✅ CI/CD 파이프라인을 시작할 준비가 완료되었습니다"
    exit 0
else
    print_error "$MISSING개의 필수 시크릿이 누락되었습니다"
    echo ""
    echo "다음 명령어로 시크릿을 설정하세요:"
    echo ""
    
    for secret in "${REQUIRED_SECRETS[@]}"; do
        if ! echo "$ALL_SECRETS" | grep -q "^$secret"; then
            echo "gh secret set $secret --body \"<value>\""
        fi
    done
    
    exit 1
fi
