#!/bin/bash
# TestFlight 자동 업로드 (App Store Connect API 키 사용)
# 사전 준비:
#   1) ~/.appstoreconnect/private_keys/AuthKey_<KeyID>.p8  (다운받은 .p8 여기 이동)
#   2) ~/.appstoreconnect/upload.env  에 ASC_KEY_ID / ASC_ISSUER_ID 저장
# 사용: bash scripts/upload_testflight.sh   (프로젝트 루트에서)
set -e

ENV_FILE="$HOME/.appstoreconnect/upload.env"
if [ ! -f "$ENV_FILE" ]; then
  echo "❌ $ENV_FILE 없음. ASC_KEY_ID / ASC_ISSUER_ID 저장 필요(README/가이드 참고)"
  exit 1
fi
# shellcheck disable=SC1090
source "$ENV_FILE"

if [ -z "$ASC_KEY_ID" ] || [ -z "$ASC_ISSUER_ID" ]; then
  echo "❌ ASC_KEY_ID / ASC_ISSUER_ID 비어있음"
  exit 1
fi

IPA=$(ls -t build/ios/ipa/*.ipa 2>/dev/null | head -1)
if [ -z "$IPA" ]; then
  echo "❌ build/ios/ipa/*.ipa 없음. 먼저 flutter build ipa --release"
  exit 1
fi

echo "▶ 업로드: $IPA"
echo "  버전: $(grep '^version:' pubspec.yaml)"
xcrun altool --upload-app --type ios -f "$IPA" \
  --apiKey "$ASC_KEY_ID" --apiIssuer "$ASC_ISSUER_ID"
echo "✅ 업로드 요청 완료. App Store Connect에서 처리(5~15분) 후 TestFlight에 노출."
