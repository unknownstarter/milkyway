-- 비공개 메모 노출 차단(권한): 'book 저장자 전체 열람' 정책 제거.
-- 조사 결과 앱의 모든 memos 직접 쿼리는 user_id=me로 필터하고, 본인/공개 메모는
-- "사용자는 자신의 메모와 공개 메모를 볼 수 있" 정책이 커버하므로, 이 정책이 유일하게
-- 하던 일 = 남의 비공개 메모 노출(구멍)이었음. 제거해도 정상 동작(SQL 검증 완료).
drop policy if exists "Users can view their own memos" on public.memos;
