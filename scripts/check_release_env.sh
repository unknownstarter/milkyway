#!/bin/bash
# 릴리즈 빌드 설정 검사 (2026-11-01).
# 0.2.13(102) 은 .env 에 double-take 프로젝트 값이 들어간 채 빌드돼 로그인이 깨졌다.
# .env 는 pubspec assets 라 앱 번들에 그대로 들어가므로, 빌드 전과 빌드 후 둘 다 본다.
#
# 사용:
#   bash scripts/check_release_env.sh            # 빌드 전: 프로젝트 루트 .env
#   bash scripts/check_release_env.sh --built    # 빌드 후: build/ 의 aab, ipa 안의 .env
# 실패하면 exit 1. 값은 출력하지 않는다 (주소 호스트와 키 이름만).
set -euo pipefail

PROD_REF="hyjgfgzexvxhgfmqgiqu"
ALLOWED="SHARE_LINK_BASE SUPABASE_ANON_KEY SUPABASE_URL"

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

if [ "${1:-}" = "--built" ]; then
  found=0
  AAB="build/app/outputs/bundle/release/app-release.aab"
  if [ -f "$AAB" ]; then
    found=1
    unzip -p "$AAB" base/assets/flutter_assets/.env | check_env_text "aab"
  fi
  IPA="$(ls -t build/ios/ipa/*.ipa 2>/dev/null | head -1 || true)"
  if [ -n "$IPA" ]; then
    found=1
    p="$(unzip -l "$IPA" | grep -oE 'Payload/[^ ]*flutter_assets/\.env$' | head -1)"
    unzip -p "$IPA" "$p" | check_env_text "ipa"
  fi
  [ "$found" = 1 ] || { echo "❌ build/ 에 aab 도 ipa 도 없다"; exit 1; }
else
  [ -f .env ] || { echo "❌ .env 없음"; exit 1; }
  check_env_text ".env" < .env
fi
