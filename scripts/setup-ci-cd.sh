#!/bin/bash
# scripts/setup-ci-cd.sh
# CI/CD 파이프라인 자동 설정 스크립트

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 함수 정의
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

# GitHub CLI 설치 확인
check_github_cli() {
    if ! command -v gh &> /dev/null; then
        print_error "GitHub CLI가 설치되지 않았습니다"
        echo "설치하려면: https://cli.github.com"
        exit 1
    fi
    print_success "GitHub CLI 설치 확인"
}

# GitHub 로그인 확인
check_github_login() {
    if ! gh auth status > /dev/null 2>&1; then
        print_warning "GitHub 로그인이 필요합니다"
        gh auth login
    fi
    print_success "GitHub 로그인 확인"
}

# 시크릿 설정 함수
setup_secrets() {
    print_header "GitHub Secrets 설정"
    
    # 필수 정보 수집
    echo -e "${YELLOW}필수 정보를 입력하세요:${NC}\n"
    
    # AWS 프로덕션
    print_warning "AWS 프로덕션 자격증명 (필수)"
    read -p "AWS Access Key ID (Prod): " AWS_ACCESS_KEY_PROD
    read -sp "AWS Secret Access Key (Prod): " AWS_SECRET_KEY_PROD
    echo ""
    
    # TMDB
    read -p "TMDB API Key (Prod): " TMDB_API_KEY_PROD
    
    # S3
    read -p "S3 Bucket 이름: " S3_BUCKET
    read -p "AWS Region (기본값: us-east-1): " AWS_REGION
    AWS_REGION=${AWS_REGION:-us-east-1}
    
    # Slack (선택사항)
    read -p "Slack Webhook URL (선택사항, Enter 스킵): " SLACK_WEBHOOK_URL
    
    # 개발 환경 (선택사항)
    echo ""
    read -p "개발 환경 자격증명도 설정하시겠습니까? (y/n): " SETUP_DEV
    
    if [ "$SETUP_DEV" = "y" ] || [ "$SETUP_DEV" = "Y" ]; then
        print_warning "AWS 개발 자격증명"
        read -p "AWS Access Key ID (Dev): " AWS_ACCESS_KEY_DEV
        read -sp "AWS Secret Access Key (Dev): " AWS_SECRET_KEY_DEV
        echo ""
        read -p "TMDB API Key (Dev): " TMDB_API_KEY_DEV
    fi
    
    # 시크릿 설정
    echo ""
    echo -e "${YELLOW}시크릿을 GitHub에 설정 중...${NC}\n"
    
    # 필수 시크릿
    gh secret set AWS_ACCESS_KEY_ID_PROD --body "$AWS_ACCESS_KEY_PROD" && \
        print_success "AWS_ACCESS_KEY_ID_PROD 설정됨"
    
    gh secret set AWS_SECRET_ACCESS_KEY_PROD --body "$AWS_SECRET_KEY_PROD" && \
        print_success "AWS_SECRET_ACCESS_KEY_PROD 설정됨"
    
    gh secret set TMDB_API_KEY_PROD --body "$TMDB_API_KEY_PROD" && \
        print_success "TMDB_API_KEY_PROD 설정됨"
    
    gh secret set S3_BUCKET --body "$S3_BUCKET" && \
        print_success "S3_BUCKET 설정됨"
    
    gh secret set AWS_REGION --body "$AWS_REGION" && \
        print_success "AWS_REGION 설정됨"
    
    # Slack (선택사항)
    if [ ! -z "$SLACK_WEBHOOK_URL" ]; then
        gh secret set SLACK_WEBHOOK_URL --body "$SLACK_WEBHOOK_URL" && \
            print_success "SLACK_WEBHOOK_URL 설정됨"
    fi
    
    # 개발 환경 (선택사항)
    if [ "$SETUP_DEV" = "y" ] || [ "$SETUP_DEV" = "Y" ]; then
        gh secret set AWS_ACCESS_KEY_ID_DEV --body "$AWS_ACCESS_KEY_DEV" && \
            print_success "AWS_ACCESS_KEY_ID_DEV 설정됨"
        
        gh secret set AWS_SECRET_ACCESS_KEY_DEV --body "$AWS_SECRET_KEY_DEV" && \
            print_success "AWS_SECRET_ACCESS_KEY_DEV 설정됨"
        
        gh secret set TMDB_API_KEY_DEV --body "$TMDB_API_KEY_DEV" && \
            print_success "TMDB_API_KEY_DEV 설정됨"
    fi
}

# 시크릿 검증
verify_secrets() {
    print_header "시크릿 검증"
    
    REQUIRED_SECRETS=(
        "AWS_ACCESS_KEY_ID_PROD"
        "AWS_SECRET_ACCESS_KEY_PROD"
        "TMDB_API_KEY_PROD"
        "S3_BUCKET"
        "AWS_REGION"
    )
    
    OPTIONAL_SECRETS=(
        "SLACK_WEBHOOK_URL"
        "AWS_ACCESS_KEY_ID_DEV"
        "AWS_SECRET_ACCESS_KEY_DEV"
        "TMDB_API_KEY_DEV"
    )
    
    local missing=0
    
    echo -e "${YELLOW}필수 시크릿:${NC}"
    for secret in "${REQUIRED_SECRETS[@]}"; do
        if gh secret list | grep -q "^$secret"; then
            print_success "$secret"
        else
            print_error "$secret (누락됨)"
            missing=$((missing + 1))
        fi
    done
    
    echo ""
    echo -e "${YELLOW}선택사항 시크릿:${NC}"
    for secret in "${OPTIONAL_SECRETS[@]}"; do
        if gh secret list | grep -q "^$secret"; then
            print_success "$secret"
        else
            print_warning "$secret (설정되지 않음)"
        fi
    done
    
    if [ $missing -eq 0 ]; then
        echo ""
        print_success "모든 필수 시크릿이 설정되어 있습니다!"
        return 0
    else
        echo ""
        print_error "$missing개의 필수 시크릿이 누락되었습니다"
        return 1
    fi
}

# Branch Protection 설정 안내
setup_branch_protection() {
    print_header "Branch Protection 설정"
    
    echo -e "${YELLOW}다음 단계를 수동으로 수행하세요:${NC}\n"
    
    echo "1. GitHub Repository 페이지 방문"
    echo "   https://github.com/NullXeronier/mlops-mlops_2/settings/branches\n"
    
    echo "2. 'Add rule' 클릭\n"
    
    echo "3. 다음 설정 적용:"
    echo "   - Branch name pattern: main"
    echo "   - ✓ Require a pull request before merging"
    echo "   - ✓ Require approvals (최소 1명)"
    echo "   - ✓ Require status checks to pass before merging"
    echo "   - ✓ Require branches to be up to date before merging"
    echo "   - ✓ Restrict who can push to matching branches (선택사항)\n"
    
    echo "4. 'Create' 클릭\n"
    
    read -p "완료하셨습니까? (y/n): " branch_done
    if [ "$branch_done" = "y" ] || [ "$branch_done" = "Y" ]; then
        print_success "Branch Protection 설정 완료"
    fi
}

# 환경 변수 설정 안내
setup_environments() {
    print_header "GitHub Environments 설정 (선택사항)"
    
    echo -e "${YELLOW}운영 환경 보호를 위해 다음을 설정하세요:${NC}\n"
    
    echo "1. Repository > Settings > Environments"
    echo "2. 'New environment' 클릭"
    echo "3. Environment name: 'production' 입력"
    echo "4. Protection rules 활성화:"
    echo "   - Required reviewers: 최소 1명"
    echo "   - Required branches: main만 배포 가능\n"
    
    read -p "완료하셨습니까? (y/n): " env_done
    if [ "$env_done" = "y" ] || [ "$env_done" = "Y" ]; then
        print_success "Environments 설정 완료"
    fi
}

# 로컬 환경 테스트
test_local_setup() {
    print_header "로컬 환경 테스트"
    
    echo -e "${YELLOW}필수 도구 확인:${NC}\n"
    
    # Docker 확인
    if command -v docker &> /dev/null; then
        print_success "Docker 설치됨"
    else
        print_warning "Docker 미설치 - 로컬 테스트에 필요합니다"
    fi
    
    # Python 확인
    if command -v python3 &> /dev/null; then
        PYTHON_VERSION=$(python3 --version)
        print_success "$PYTHON_VERSION"
    else
        print_error "Python3 미설치"
    fi
    
    # Git 확인
    if command -v git &> /dev/null; then
        print_success "Git 설치됨"
    else
        print_error "Git 미설치"
    fi
    
    echo ""
    echo -e "${YELLOW}로컬 테스트 실행:${NC}\n"
    
    read -p "로컬 테스트를 실행하시겠습니까? (y/n): " run_tests
    
    if [ "$run_tests" = "y" ] || [ "$run_tests" = "Y" ]; then
        cd data-task
        
        if [ ! -d "venv" ]; then
            print_warning "가상환경 생성 중..."
            python3 -m venv venv
        fi
        
        source venv/bin/activate
        
        print_warning "의존성 설치 중..."
        pip install -q -r requirements.txt
        pip install -q -e .[dev]
        
        print_warning "테스트 실행 중..."
        if pytest tests/ -q; then
            print_success "모든 테스트 통과!"
        else
            print_error "일부 테스트 실패 - 로그 확인 필요"
        fi
        
        deactivate
        cd ..
    fi
}

# 파이프라인 테스트
test_pipeline() {
    print_header "파이프라인 테스트"
    
    echo -e "${YELLOW}첫 번째 커밋 푸시:${NC}\n"
    
    read -p "테스트 커밋을 푸시하시겠습니까? (y/n): " push_commit
    
    if [ "$push_commit" = "y" ] || [ "$push_commit" = "Y" ]; then
        git add -A
        git commit -m "ci: setup ci-cd pipeline"
        git push origin main
        
        echo ""
        print_success "커밋 푸시 완료!"
        echo ""
        echo -e "${YELLOW}파이프라인 상태 확인:${NC}"
        echo "https://github.com/NullXeronier/mlops-mlops_2/actions"
        echo ""
        
        sleep 2
        
        # 최근 워크플로우 확인
        gh run list --limit 1
    fi
}

# 메인 함수
main() {
    print_header "MLOps CI/CD 파이프라인 자동 설정"
    
    # 필수 도구 확인
    check_github_cli
    check_github_login
    
    # 시크릿 설정
    setup_secrets
    
    # 시크릿 검증
    if verify_secrets; then
        echo ""
        print_success "시크릿 설정 완료!"
    else
        print_warning "설정을 다시 확인하세요"
    fi
    
    # Branch Protection 설정
    echo ""
    setup_branch_protection
    
    # Environments 설정
    echo ""
    setup_environments
    
    # 로컬 테스트
    echo ""
    read -p "로컬 환경 테스트를 실행하시겠습니까? (y/n): " local_test
    if [ "$local_test" = "y" ] || [ "$local_test" = "Y" ]; then
        test_local_setup
    fi
    
    # 파이프라인 테스트
    echo ""
    read -p "파이프라인 테스트를 실행하시겠습니까? (y/n): " pipeline_test
    if [ "$pipeline_test" = "y" ] || [ "$pipeline_test" = "Y" ]; then
        test_pipeline
    fi
    
    # 최종 요약
    print_header "설정 완료!"
    
    echo -e "${GREEN}다음 단계:${NC}\n"
    echo "1. 로컬에서 개발 진행"
    echo "2. Feature 브랜치에서 코드 작성"
    echo "3. Pull Request 생성"
    echo "4. CI/CD 파이프라인 자동 실행 확인"
    echo "5. 코드 리뷰 후 merge"
    echo "6. 운영 배포 자동 실행"
    echo ""
    echo -e "${BLUE}관련 문서:${NC}"
    echo "- CI/CD 가이드: CI-CD-GUIDE.md"
    echo "- Actions 설정: GITHUB-ACTIONS-SETUP.md"
    echo ""
}

# 실행
main "$@"
