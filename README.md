# Milkyway (밀키웨이)

Personal Reading Intelligence. 읽으며 남긴 생각을 다시 찾고 연결하고 활용하는 독서 메모 앱.

- 스택: Flutter, Riverpod, GoRouter, Supabase

## 어디부터 읽나

1. `CLAUDE.md` - 작업 규칙과 읽기 순서
2. `docs/PRD_v2.md` - 제품 정의, BM, 검색 구조
3. `docs/VISION_v3.md` - 톤, Lyra, 영구 금지
4. `docs/handoff/README.md` - 인수인계
5. `docs/LESSONS_LEARNED.md` - 지난 사고와 교훈
6. `docs/release/` - 릴리즈 노트

## 시작하기

```bash
git config core.hooksPath scripts/git-hooks   # pre-push 게이트 설치
cp .env.example .env                          # SUPABASE_URL, SUPABASE_ANON_KEY, SHARE_LINK_BASE 채우기
flutter run
```
