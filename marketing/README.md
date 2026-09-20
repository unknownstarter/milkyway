# marketing

HTML/CSS를 Chrome 헤드리스로 렌더해 이미지를 굽는 생성기 모음.
**정본은 스크립트다.** 산출물(png/jpg/gif/webp)은 `.gitignore` 대상이고 언제든 다시 구우면 된다.
버전을 올릴 땐 파일을 새로 만들지 말고 기존 스크립트를 고칠 것 (v3~v8 처럼 쌓이면 뭐가 현행인지 사라진다).

## 살아있는 생성기

| 스크립트 | 산출물 | 어디에 쓰이나 |
|---|---|---|
| `generate_galaxy_tiers.py` | `galaxy_t{1..6}_{core,glass}.webp` | 앱 오브 에셋 정본. `assets/images/orb/orb_*.webp` 로 복사. `docs/design/05` |
| `generate_og_cards.py` | `og_t{1..6}.jpg` | 공유 링크 OG 썸네일. `scripts/upload_og_cards.sh` 가 Supabase에 업로드 |
| `generate_share_card.py` | 공유 카드 | `lib/features/orb/presentation/widgets/share_card.dart` 디자인 정본 |
| `generate_share_card_connection.py` | 연결 카드 | 위와 동일 (그때 -> 지금 변형) |
| `generate_home_banner.py` | `home_banner*.png` | 홈 배너 디자인 정본. `docs/design/05` |
| `generate_wrapped.py` | `wrapped_card.png` | `wrapped_card.dart` 좌표 정본 (절대 좌표 일치) |
| `generate2.py` | `v2_{appstore,play,ipad}_*.png` | 스토어 스크린샷. 입력 = `shots/` |
| `default_cover.html` | `book_covers/_default.jpg` | 표지 없는 책의 기본 표지. Supabase Storage에 업로드된 그 이미지의 원본 |
| `generate_ad_v8.py` / `generate_ad_pop.py` | 인스타 광고 시안 | 최신 두 공식. 집행 시 여기서 다시 굽는다 |

## shots/

실기기 스크린샷 원본. **재생성 불가 = 지우지 말 것.** `generate2.py` 의 입력이다.

## 굽는 법

```bash
python3 marketing/generate_og_cards.py     # -> marketing/og_t{1..6}.jpg
bash   scripts/upload_og_cards.sh          # -> Supabase 업로드
```

Chrome 경로는 스크립트가 알아서 찾는다. PIL(Pillow)이 필요한 스크립트가 있다.

## 카피 룰

사용자 노출 카피는 `CLAUDE.md` 의 부호 룰을 따른다.
금지: em/en dash, 중간점, 곡선따옴표, 단일 말줄임, "당신" 호칭, 느낌표. 구분자는 ` - ` 또는 `/`.
