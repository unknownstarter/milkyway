#!/bin/bash
# OG 썸네일 6장을 Storage에 올린다(티어당 1장, 사용자마다 만들지 않음).
#   1) python3 marketing/generate_og_cards.py   -> marketing/og_t{1..6}.jpg
#   2) bash scripts/upload_og_cards.sh          -> share_cards/og/{tier}.jpg
# .env 의 SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY 를 쓴다.
set -e
cd "$(dirname "$0")/.."

U=$(grep '^SUPABASE_URL=' .env | cut -d= -f2- | tr -d '"')
S=$(grep '^SUPABASE_SERVICE_ROLE_KEY=' .env | cut -d= -f2- | tr -d '"')
if [ -z "$U" ] || [ -z "$S" ]; then
  echo "❌ .env 에 SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY 필요"
  exit 1
fi

for t in t1 t2 t3 t4 t5 t6; do
  f="marketing/og_${t}.jpg"
  [ -f "$f" ] || { echo "❌ $f 없음. generate_og_cards.py 먼저 실행"; exit 1; }
  code=$(curl -s -o /dev/null -w "%{http_code}" \
    -X POST "$U/storage/v1/object/share_cards/og/${t}.jpg?upsert=true" \
    -H "Authorization: Bearer $S" -H "Content-Type: image/jpeg" \
    --data-binary "@$f")
  echo "  og/${t}.jpg -> HTTP $code"
done
echo "✅ 업로드 완료. 엣지 함수가 og/{tier}.jpg 를 og:image로 쓴다."
