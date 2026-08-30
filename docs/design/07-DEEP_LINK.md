# 07 - 딥링크 자체 구축 (MMP 0원, 재사용 문서)

> 상태: 세밀 설계 (2026-08-30) · Branch/AppsFlyer 안 쓰고 **무료로 자체 구축**. 다른 프로젝트 이식 가능.
> 목표: 공유 링크를 (1) 예쁜 브랜드 링크로, (2) 설치 유저 → 앱 내 그 카드로 랜딩(유니버설/앱링크), (3) 미설치 → 설치 후 그 카드로(디퍼드), (4) OG 미리보기, (5) 온보딩/로그인 상태별 분기.

## 0. 구성 요소 (전부 무료)
| 요소 | 무엇 | 비용 |
|---|---|---|
| **Vercel** | 링크 호스팅(`milkyway.vercel.app`) + 서버리스 함수(OG/라우팅/지문저장) + `.well-known` | 무료 |
| **Supabase** | `share_cards`(기존) + `deferred_clicks`(신규) + `get_share_card` RPC | 무료 |
| **app_links** | Flutter 딥링크 수신(유니버설/앱링크/커스텀스킴) | 무료 |
| **android_play_install_referrer** | Android 디퍼드(Install Referrer) | 무료 |

링크: `https://milkyway.vercel.app/s/{code}` (code=6자, 기존 share_cards).

## 1. 전체 플로우 (5경로)
```
[크롤러(카톡/페북/X)]  → Vercel /s/{code} → OG HTML(썸네일=카드, 타이틀=티어) → 미리보기만
[설치 O · iOS]        → Universal Link 잡힘 → 앱 열림 → 딥링크 라우팅(§5)
[설치 O · Android]    → App Link 잡힘 → 앱 열림 → 딥링크 라우팅(§5)
[설치 X · 클릭]        → Vercel가 지문+code 저장(§4) → OS별 스토어로
[설치 X → 설치 후 첫 실행]
   Android → Install Referrer로 code 확정 획득(§3, 98%)
   iOS    → 지문 매칭으로 code 추정 획득(§4, 70~90%)
   → 딥링크 라우팅(§5)
```

## 2. Vercel 링크 서버 (`/s/[code]`)
Next.js route handler (또는 서버리스). 역할 3가지:
1. **OG HTML 반환** (기존 supabase edge function `s` 로직 이관): `get_share_card(code)`로 tier/image_path 조회 → og:title/description/image + twitter card.
2. **클릭 지문 저장**(iOS 디퍼드용, §4): User-Agent/IP/Accept-Language 등 → supabase `deferred_clicks`.
3. **OS 라우팅**: iOS는 유니버설링크가 앱을 먼저 잡으므로 앱 미설치 시에만 이 페이지 도달 → 스토어(App Store). Android는 App Link 미설치 시 → Play URL에 **`referrer=code`** 부착(§3).
- `.well-known/apple-app-site-association` + `.well-known/assetlinks.json` 정적 서빙(§6).

## 3. Android 디퍼드 = Install Referrer (결정론적 98%)
- 링크에서 Play URL 만들 때: `https://play.google.com/store/apps/details?id=com.whatif.milkyway.android&referrer=` + `urlencode("orb_code=" + code)`.
- Play가 설치 시 이 referrer를 보존 → 앱 첫 실행에서 `android_play_install_referrer`로 읽음:
  ```dart
  final ref = await AndroidPlayInstallReferrer.installReferrer;
  // ref.installReferrer == "orb_code=ab12cd" → 파싱 → 그 카드로
  ```
- **주의**: Install Referrer는 **최초 설치 1회만** 신뢰. 재설치/업데이트에선 이전 값 남을 수 있음 → 소비 후 로컬 플래그로 1회성 처리.

## 4. iOS 디퍼드 = 지문 매칭 (확률적 70~90%)
Apple은 Install Referrer 없음 → **지문(fingerprint) 확률 매칭**. Branch가 하는 그 방식.
- **클릭 시(Vercel)**: `deferred_clicks`에 insert
  ```
  { code, ip, ua, accept_language, screen(추정 불가시 생략), created_at }
  ```
  (iOS는 브라우저에서 화면크기 정도만; IP+UA+lang+timezone이 핵심 시그널)
- **첫 앱 실행 시(앱)**: 같은 시그널(공인 IP는 서버가 봄, UA/lang/tz/model) 생성 → supabase 함수 `match_deferred_click(signals)` 호출 → **최근 N분(예: 15분) 내 + 시그널 근접** 매칭 1건 → code 반환.
- **정확도/한계**: 70~90%. VPN·IPv6 로테이션·ATT·공용와이파이(여러 기기 같은 IP)면 급락. → **오매칭 방지**: 시간창 짧게(15분) + 매칭 1건일 때만 신뢰, 다건이면 포기(홈으로).
- **프라이버시**: 지문은 개인식별 최소화(해시), 15분 후 purge(pg_cron). 개인정보 고지 필요할 수 있음(검토).

## 5. 인앱 딥링크 라우팅 (인증/온보딩 게이트)
`app_links`로 URL 수신 → code 추출 → **분기(운영자 스펙)**:
```
code 수신(유니버설/앱링크/디퍼드/커스텀스킴 공통) →
  로그인 안 됨            → 로그인 화면 (code를 pending 저장, 로그인 후 카드로)
  로그인 O + 온보딩 미완료 → 온보딩 화면(이어서) (code pending)
  로그인 O + 온보딩 완료   → SharedCardScreen(code)
      · 뒤로가기 = pop 아님. 무조건 홈으로 이동(context.go(home))
      · "나도 만들기" CTA → 내 우주 or 게이트
```
- **pending code**: 미로그인/온보딩중이면 code를 secure storage에 저장 → 로그인/온보딩 완료 콜백에서 소비 → 카드로.
- 수신 채널: 앱 실행 중(`uriLinkStream`) + 콜드스타트(`getInitialLink`) 둘 다 처리.

## 6. Universal Links(iOS) / App Links(Android) 설정
### iOS
- `milkyway.vercel.app/.well-known/apple-app-site-association` (Content-Type: application/json, **확장자 없음**):
  ```json
  { "applinks": { "details": [ { "appIDs": ["TEAMID.com.whatif.milkyway"], "components": [ { "/": "/s/*" } ] } ] } }
  ```
- Xcode: Signing & Capabilities → **Associated Domains** → `applinks:milkyway.vercel.app`. (entitlement + 프로비저닝 갱신)
- 수신: scene 환경이라 `FlutterSceneDelegate`가 `NSUserActivity`(universal link)를 Flutter로 전달 → app_links가 받음.
  - ⚠️⚠️ **OAuth/scene 충돌 주의**(§8). URL 콜백 처리 순서 실기기 검증 필수.

### Android
- `milkyway.vercel.app/.well-known/assetlinks.json`:
  ```json
  [ { "relation": ["delegate_permission/common.handle_all_urls"],
      "target": { "namespace":"android_app", "package_name":"com.whatif.milkyway.android",
                  "sha256_cert_fingerprints":["<릴리즈 서명 SHA256>"] } } ]
  ```
- `AndroidManifest.xml` intent-filter(`android:autoVerify="true"`, scheme https, host milkyway.vercel.app, pathPrefix `/s`).

## 7. DB (신규, 기존 스키마 변경 X)
```sql
create table public.deferred_clicks (
  id bigserial primary key,
  code text not null,
  ip text, ua text, lang text, tz text,
  created_at timestamptz not null default now()
);
create index on public.deferred_clicks(created_at);
-- pg_cron: 15분 지난 것 purge (프라이버시)

-- 공개 조회(카드 뷰어용, SECURITY DEFINER, share_cards 공개 필드만)
create or replace function public.get_share_card(p_code text)
returns table(tier text, image_path text) language sql security definer set search_path='' as $$
  select tier, image_path from public.share_cards where code = p_code
$$;
-- iOS 지문 매칭
create or replace function public.match_deferred_click(p_ip text, p_ua text, p_lang text)
returns text language sql security definer set search_path='' as $$
  select code from public.deferred_clicks
   where ip = p_ip and lang = p_lang and created_at > now() - interval '15 minutes'
   order by created_at desc limit 1
$$;  -- 정확도 위해 ua 유사도까지 넣을지 튜닝
```

## 8. 레슨런 & 주의점 ⚠️ (반드시 터짐)
1. **iOS AASA 캐싱 지옥**: Apple CDN이 AASA를 ~하루 캐시 → 수정해도 반영 안 됨. 디버그: 앱 재설치 + `applinks:milkyway.vercel.app?mode=developer`(개발 모드) + Charles로 확인. **iteration이 느리다는 걸 각오**.
2. **Associated Domains entitlement + 프로비저닝**: 캐파빌리티 추가하면 프로비저닝 프로파일 갱신 필요. Xcode Cloud/CLI 빌드에서 자동서명 확인.
3. **⚠️ scene 라이프사이클 + OAuth 충돌**: iOS는 scene 환경. universal link(NSUserActivity)와 OAuth 콜백(openURL) 둘 다 scene delegate 경유. app_links 도입이 google_sign_in URL 처리와 안 부딪히는지 **실기기 필수 검증**. 순서/가로채기 주의. (프로젝트 메모리의 "OAuth 깨짐" 구역)
4. **Android autoVerify 실패**: assetlinks.json의 SHA256이 **릴리즈 서명**과 정확히 일치해야 자동검증. Play App Signing 쓰면 Play Console의 SHA256 사용(업로드 키 아님). 틀리면 링크가 앱을 안 잡고 브라우저로 감.
5. **Install Referrer 1회성**: 재설치/업데이트에서 stale referrer 위험 → 첫 실행 소비 후 로컬 플래그.
6. **지문 오매칭**: 공용 와이파이/회사 IP면 여러 사람이 같은 IP → 오매칭. 시간창 짧게 + 단일매칭만 신뢰 + 애매하면 홈.
7. **카카오톡 인앱브라우저**: 카톡 내부 브라우저에서 universal link가 앱을 **안 열 수 있음**(인앱 웹뷰라). → OG 페이지에 "앱에서 열기" 버튼(스킴 폴백) 병행. 한국 최대 채널이라 이거 꼭 테스트.
8. **콜드스타트 vs 웜스타트**: `getInitialLink`(앱 꺼져있다 링크로 켜짐) + `uriLinkStream`(켜져있을 때) 둘 다 처리 안 하면 케이스 누락.
9. **pending code 유실**: 미로그인→로그인 사이 앱 종료 시 code 유실 → secure storage 영속 + 소비.
10. **프라이버시 고지**: 지문(IP/UA) 저장은 개인정보. 짧은 보관(15분 purge) + 정책 고지 검토.
11. **Vercel 프로젝트명**: `milkyway.vercel.app`는 프로젝트명이 milkyway로 선점돼야. 안 되면 서브도메인 조정.

## 9. 구현 순서
1. **Vercel 프로젝트** + `/s/[code]` 함수(OG 이관 + 지문저장 + OS라우팅) + `.well-known` 2개.
2. **DB**: `deferred_clicks` + `get_share_card` + `match_deferred_click` + purge cron.
3. **앱 링크 생성 교체**: ShareRepository가 supabase URL → `milkyway.vercel.app/s/{code}` 로.
4. **네이티브**: iOS Associated Domains + Android intent-filter + assetlinks/AASA. ⚠️ scene/OAuth 실기기 검증.
5. **Flutter**: app_links 수신 + 라우터 게이트(§5) + SharedCardScreen + pending code.
6. **디퍼드**: Android Install Referrer(referrer 부착 + 읽기) + iOS 지문 매칭.
7. **실기기 전수 테스트**: 카톡/사파리/크롬, 설치/미설치, 콜드/웜, 로그인/온보딩 상태별.

## 10. 재사용 가이드
- 무료 스택(Vercel + Supabase + app_links + install_referrer)만으로 Branch 핵심 복제.
- iOS 디퍼드(지문)는 확률적 → "있으면 좋은" 기능으로. 설치유저 딥링크(유니버설)+Android 디퍼드(referrer)가 결정론적 핵심.
- 가장 큰 함정 = iOS AASA 캐싱 + scene/OAuth 충돌 + Android SHA256. 이 3개에 시간의 80% 쓸 각오.
