-- 디퍼드 딥링크(미설치->설치후 카드) 미채택 결정 -> 지문(IP/UA) 수집/매칭 제거.
-- 개인정보 최소화: 안 쓰는 IP/UA를 쌓지 않는다. get_share_card(뷰어)는 유지.
drop function if exists public.match_deferred_click(text, text);
drop table if exists public.deferred_clicks;
