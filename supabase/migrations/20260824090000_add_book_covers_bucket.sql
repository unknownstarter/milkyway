-- 책 표지 재호스팅용 공개 버킷(네이버 외부 URL을 우리 스토리지로 복사 -> on-the-fly
-- 변환/WebP 적용 대상화). 표시측은 CachedImage(supabaseRenderUrl)가 표시폭 WebP로 요청.
insert into storage.buckets (id, name, public)
values ('book_covers', 'book_covers', true)
on conflict (id) do update set public = true;

-- 정책 재적용(idempotent)
drop policy if exists "book_covers_read_public" on storage.objects;
drop policy if exists "book_covers_insert_auth" on storage.objects;
drop policy if exists "book_covers_update_auth" on storage.objects;

-- 공개 읽기
create policy "book_covers_read_public" on storage.objects
  for select to public
  using (bucket_id = 'book_covers');

-- 인증 사용자 업로드/덮어쓰기(같은 ISBN 경로 upsert)
create policy "book_covers_insert_auth" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'book_covers');

create policy "book_covers_update_auth" on storage.objects
  for update to authenticated
  using (bucket_id = 'book_covers')
  with check (bucket_id = 'book_covers');
