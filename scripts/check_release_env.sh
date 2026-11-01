#!/bin/bash
# 릴리즈 빌드 설정 검사 (2026-11-01).
# 0.2.13(102) 은 .env 에 double-take 프로젝트 값이 들어간 채 빌드돼 로그인이 깨졌다.
# .env 는 pubspec assets 라 앱 번들에 그대로 들어가므로, 빌드 전과 빌드 후 둘 다 본다.
#
# 사용:
#   bash scripts/check_release_env.sh            # 빌드 전: 프로젝트 루트 .env
#   bash scripts/check_release_env.sh --built    # 빌드 후: build/ 의 aab, ipa 안의 .env, aab 서명, 버전
#   bash scripts/check_release_env.sh --built --aab <경로>   # 검사할 aab 를 직접 지정
# 실패하면 exit 1. 값은 출력하지 않는다 (주소 호스트와 키 이름만).
set -euo pipefail

PROD_REF="hyjgfgzexvxhgfmqgiqu"
ALLOWED="SHARE_LINK_BASE SUPABASE_ANON_KEY SUPABASE_URL"
# Play 업로드 키 인증서 SHA256 지문 (공개값, 비밀 아님). 이것과 다르면 Play 가 거절한다.
UPLOAD_CERT_SHA256="CD:83:CA:8E:F7:92:22:9B:F7:43:74:4B:CF:A9:B3:82:54:CA:15:FD:81:F4:D3:64:78:CC:6F:97:CC:99:74:75"

check_env_text() {  # $1 = 이름, stdin = .env 내용
  local name="$1" body keys url ref role
  body="$(cat)"
  keys="$(printf '%s\n' "$body" | grep -oE '^[A-Z_]+=' | tr -d '=' | sort | tr '\n' ' ' | sed 's/ $//')"
  if [ "$keys" != "$ALLOWED" ]; then
    echo "❌ [$name] .env 키가 다르다: '$keys' (허용: '$ALLOWED'). 서비스 롤, Anthropic 같은 키는 앱 번들에 들어가면 안 된다"; return 1
  fi
  url="$(printf '%s\n' "$body" | grep -E '^SUPABASE_URL=' | cut -d= -f2-)"
  if [ "$url" != "https://${PROD_REF}.supabase.co" ]; then
    echo "❌ [$name] SUPABASE_URL 이 운영 milkyway 가 아니다: $(printf '%s' "$url" | grep -oE 'https?://[a-z0-9.-]+')"; return 1
  fi
  # anon 키 JWT 의 ref, role 확인 (서명은 안 본다)
  ref_role="$(printf '%s\n' "$body" | grep -E '^SUPABASE_ANON_KEY=' | cut -d= -f2- | python3 -c '
import sys,base64,json
t=sys.stdin.read().strip().split(".")
p=t[1]+"="*(-len(t[1])%4) if len(t)>1 else ""
try:
  d=json.loads(base64.urlsafe_b64decode(p)); print(d.get("ref",""), d.get("role",""))
except Exception: print("? ?")')"
  ref="${ref_role% *}"; role="${ref_role#* }"
  if [ "$ref" != "$PROD_REF" ] || [ "$role" != "anon" ]; then
    echo "❌ [$name] SUPABASE_ANON_KEY 가 운영 anon 키가 아니다 (ref=$ref role=$role)"; return 1
  fi
  echo "✅ [$name] 운영 milkyway ($PROD_REF), 키 3개, anon 키 일치"
}

check_aab_signing() {  # $1 = aab 경로
  local aab="$1" jv cert
  jv="$(jarsigner -verify "$aab" 2>&1 || true)"
  if ! grep -q "jar verified" <<< "$jv"; then
    echo "❌ [aab] 서명이 없거나 깨졌다 (jarsigner 검증 실패). key.properties, upload-keystore.jks 를 메인 체크아웃에서 복사했는지 확인"; return 1
  fi
  cert="$(keytool -printcert -jarfile "$aab" 2>/dev/null | grep -m1 'SHA256:' | sed 's/.*SHA256: *//' | tr -d ' ')"
  if [ "$cert" != "$UPLOAD_CERT_SHA256" ]; then
    echo "❌ [aab] 서명 인증서가 Play 업로드 키가 아니다 (SHA256=${cert:-없음})"; return 1
  fi
  echo "✅ [aab] 서명 확인, Play 업로드 키 지문 일치"
}

check_aab_version() {  # $1 = aab 경로
  local aab="$1" want name code vn vc
  if ! command -v bundletool >/dev/null 2>&1; then
    echo "⚠️  [aab] bundletool 이 없어 버전 검사를 건너뛴다 (brew install bundletool)"; return 0
  fi
  want="$(grep -E '^version:' pubspec.yaml | head -1 | sed 's/version: *//' | tr -d ' \r')"
  name="${want%+*}"; code="${want#*+}"
  vn="$(bundletool dump manifest --bundle="$aab" --xpath /manifest/@android:versionName 2>/dev/null || true)"
  vc="$(bundletool dump manifest --bundle="$aab" --xpath /manifest/@android:versionCode 2>/dev/null || true)"
  if [ "$vn" != "$name" ] || [ "$vc" != "$code" ]; then
    echo "❌ [aab] 버전이 pubspec 과 다르다: aab=${vn:-?}+${vc:-?} pubspec=$want"; return 1
  fi
  echo "✅ [aab] 버전 $vn+$vc 가 pubspec 과 일치"
}

if [ "${1:-}" = "--built" ]; then
  found=0
  AAB="build/app/outputs/bundle/release/app-release.aab"
  if [ "${2:-}" = "--aab" ]; then AAB="${3:?--aab 뒤에 경로가 필요하다}"; fi
  fail=0
  if [ -f "$AAB" ]; then
    found=1
    unzip -p "$AAB" base/assets/flutter_assets/.env | check_env_text "aab" || fail=1
    check_aab_signing "$AAB" || fail=1
    check_aab_version "$AAB" || fail=1
  fi
  IPA="$(ls -t build/ios/ipa/*.ipa 2>/dev/null | head -1 || true)"
  if [ -n "$IPA" ]; then
    found=1
    p="$(unzip -l "$IPA" | grep -oE 'Payload/[^ ]*flutter_assets/\.env$' | head -1)"
    unzip -p "$IPA" "$p" | check_env_text "ipa" || fail=1
  fi
  [ "$found" = 1 ] || { echo "❌ build/ 에 aab 도 ipa 도 없다"; exit 1; }
  [ "$fail" = 0 ] || exit 1
else
  [ -f .env ] || { echo "❌ .env 없음"; exit 1; }
  check_env_text ".env" < .env
fi
