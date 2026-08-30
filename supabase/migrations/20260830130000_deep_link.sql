-- 딥링크(커스텀 스킴) 지원. 기존 스키마 변경 없음(신규 함수/테이블만).
--   1) get_share_card: 타인 카드 뷰어용 공개 조회(share_cards RLS는 소유자 select만 허용).
--   2) deferred_clicks + match_deferred_click: iOS 디퍼드 딥링크(지문 매칭, 짧은 보관).
-- 상세: docs/design/07-DEEP_LINK.md

-- 공개 카드 조회(뷰어용). tier/image_path/payload만 노출(user_id 비노출). SECURITY DEFINER.
create or replace function public.get_share_card(p_code text)
returns table(tier text, image_path text, payload jsonb)
language sql
security definer
set search_path = ''
as $$
  select tier, image_path, payload
  from public.share_cards
  where code = p_code
$$;

grant execute on function public.get_share_card(text) to anon, authenticated;

-- iOS 디퍼드 딥링크용 클릭 지문. 짧은 보관(프라이버시), 15분 내 매칭만 신뢰.
create table if not exists public.deferred_clicks (
  id         bigserial primary key,
  code       text not null,
  ip         text,
  ua         text,
  lang       text,
  created_at timestamptz not null default now()
);
create index if not exists deferred_clicks_created_at_idx on public.deferred_clicks(created_at);

-- RLS 활성화 + 정책 없음(=일반 클라이언트 직접 접근 deny).
--   삽입: 엣지펑션 service_role(RLS 우회).  조회: 아래 SECURITY DEFINER 함수로만.
alter table public.deferred_clicks enable row level security;

-- iOS 첫 실행 시 지문 매칭(최근 15분 + IP/lang 일치, 최신 1건만). 다건/불일치면 null.
create or replace function public.match_deferred_click(p_ip text, p_lang text)
returns text
language sql
security definer
set search_path = ''
as $$
  select code from public.deferred_clicks
  where ip = p_ip and lang = p_lang
    and created_at > now() - interval '15 minutes'
  order by created_at desc
  limit 1
$$;

grant execute on function public.match_deferred_click(text, text) to anon, authenticated;
