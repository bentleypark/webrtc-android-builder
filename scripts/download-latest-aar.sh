#!/bin/bash

# WebRTC AAR 자동 다운로드 스크립트
# GitHub CLI를 사용하여 최신 빌드 아티팩트를 다운로드합니다.

set -euo pipefail

# 색상 설정
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 도움말
show_help() {
    cat << EOF
WebRTC AAR 자동 다운로드 스크립트

사용법: $0 [옵션]

옵션:
  -r, --repo REPO         GitHub 저장소 (예: username/webrtc-android-builder)
  -o, --output DIR        출력 디렉토리 (기본: current directory)
  -l, --list             사용 가능한 아티팩트 목록만 표시
  -h, --help             이 도움말 표시

필수 조건:
  - GitHub CLI (gh) 설치 및 인증 필요
  - 저장소 접근 권한 필요

예시:
  $0 -r username/webrtc-android-builder -o ~/Downloads
  $0 --list -r username/webrtc-android-builder

GitHub CLI 설치:
  brew install gh
  gh auth login

EOF
}

# 기본값
REPO=""
OUTPUT_DIR="."
LIST_ONLY=false

# 인수 파싱
while [[ $# -gt 0 ]]; do
    case $1 in
        -r|--repo)
            REPO="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -l|--list)
            LIST_ONLY=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            log_error "알 수 없는 옵션: $1"
            show_help
            exit 1
            ;;
    esac
done

# 필수 검사
if [[ -z "$REPO" ]]; then
    log_error "저장소를 지정해야 합니다. -r 또는 --repo 옵션을 사용하세요."
    show_help
    exit 1
fi

# GitHub CLI 설치 확인
if ! command -v gh &> /dev/null; then
    log_error "GitHub CLI (gh)가 설치되어 있지 않습니다."
    log_info "설치 방법: brew install gh"
    exit 1
fi

# GitHub 인증 확인
if ! gh auth status &> /dev/null; then
    log_error "GitHub CLI 인증이 필요합니다."
    log_info "인증 방법: gh auth login"
    exit 1
fi

# 워크플로우 실행 목록 가져오기
log_info "워크플로우 실행 목록을 가져오는 중..."
RUNS=$(gh run list --repo "$REPO" --workflow "build-webrtc-android.yml" --status completed --limit 10 --json databaseId,headBranch,conclusion,createdAt,displayTitle)

if [[ -z "$RUNS" || "$RUNS" == "[]" ]]; then
    log_error "완료된 워크플로우 실행을 찾을 수 없습니다."
    log_info "저장소에서 성공적으로 완료된 빌드가 있는지 확인하세요."
    exit 1
fi

# 성공한 실행만 필터링
SUCCESS_RUNS=$(echo "$RUNS" | jq '[.[] | select(.conclusion == "success")]')

if [[ "$SUCCESS_RUNS" == "[]" ]]; then
    log_error "성공한 워크플로우 실행을 찾을 수 없습니다."
    exit 1
fi

# 최신 성공 실행 가져오기
LATEST_RUN_ID=$(echo "$SUCCESS_RUNS" | jq -r '.[0].databaseId')
LATEST_RUN_TITLE=$(echo "$SUCCESS_RUNS" | jq -r '.[0].displayTitle')
LATEST_RUN_DATE=$(echo "$SUCCESS_RUNS" | jq -r '.[0].createdAt')

log_info "최신 성공 빌드 정보:"
echo "  📋 Title: $LATEST_RUN_TITLE"
echo "  🆔 Run ID: $LATEST_RUN_ID"  
echo "  📅 Date: $LATEST_RUN_DATE"

# 아티팩트 목록만 표시하고 종료
if [[ "$LIST_ONLY" == "true" ]]; then
    log_info "사용 가능한 아티팩트:"
    gh run view "$LATEST_RUN_ID" --repo "$REPO" --log-failed
    exit 0
fi

# 아티팩트 목록 가져오기
log_info "아티팩트 목록을 가져오는 중..."
ARTIFACTS=$(gh api "repos/$REPO/actions/runs/$LATEST_RUN_ID/artifacts" --jq '.artifacts[] | select(.name | startswith("webrtc-android-aar"))')

if [[ -z "$ARTIFACTS" ]]; then
    log_error "WebRTC AAR 아티팩트를 찾을 수 없습니다."
    exit 1
fi

# 첫 번째 아티팩트 정보 추출
ARTIFACT_NAME=$(echo "$ARTIFACTS" | jq -r '.name' | head -1)
ARTIFACT_SIZE=$(echo "$ARTIFACTS" | jq -r '.size_in_bytes' | head -1)
ARTIFACT_SIZE_MB=$((ARTIFACT_SIZE / 1024 / 1024))

log_info "다운로드할 아티팩트:"
echo "  📦 Name: $ARTIFACT_NAME"
echo "  📏 Size: ${ARTIFACT_SIZE_MB}MB"

# 출력 디렉토리 생성
mkdir -p "$OUTPUT_DIR"
cd "$OUTPUT_DIR"

# 아티팩트 다운로드
log_info "아티팩트 다운로드 중... (위치: $OUTPUT_DIR)"
if gh run download "$LATEST_RUN_ID" --repo "$REPO" --name "$ARTIFACT_NAME"; then
    log_info "✅ 다운로드 완료!"
    
    # 압축 해제
    if [[ -f "${ARTIFACT_NAME}.zip" ]]; then
        log_info "압축 해제 중..."
        unzip -o "${ARTIFACT_NAME}.zip"
        rm "${ARTIFACT_NAME}.zip"
    fi
    
    # 결과 확인
    if [[ -f "libwebrtc.aar" ]]; then
        AAR_SIZE=$(stat -f%z "libwebrtc.aar" 2>/dev/null || stat -c%s "libwebrtc.aar" 2>/dev/null)
        AAR_SIZE_MB=$((AAR_SIZE / 1024 / 1024))
        
        log_info "🎉 WebRTC AAR 다운로드 성공!"
        echo "  📁 위치: $(pwd)/libwebrtc.aar"
        echo "  📏 크기: ${AAR_SIZE_MB}MB"
        
        if [[ -f "build-info.txt" ]]; then
            echo "  📋 빌드 정보: $(pwd)/build-info.txt"
            echo ""
            echo "=== 빌드 정보 ==="
            head -20 build-info.txt
        fi
        
        echo ""
        log_info "Android 프로젝트 통합 방법:"
        echo "  1. AAR 파일을 app/libs/ 폴더에 복사"
        echo "  2. build.gradle에 의존성 추가: implementation files('libs/libwebrtc.aar')"
        echo "  3. minSdk를 24로 설정 (16KB 페이지 지원)"
        
    else
        log_error "libwebrtc.aar 파일을 찾을 수 없습니다."
        exit 1
    fi
else
    log_error "다운로드 실패"
    exit 1
fi