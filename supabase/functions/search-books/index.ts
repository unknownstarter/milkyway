// 책 검색. 우선순위 폴백으로 한국+글로벌 모두 커버, 절대 500 안 던짐(빈 결과로).
//   1) Google Books (GOOGLE_BOOKS_API_KEY 있을 때) - 글로벌+한국. keyless는 쿼터0라 키 필수.
//   2) Naver (NAVER_CLIENT_ID/SECRET) - 한국 최강, 2027까지 유효. status 체크로 안전화.
//   3) Open Library (keyless) - 글로벌(영어) 폴백, 항상 동작.
// 응답은 기존 클라(NaverBook.fromJson) 형태로 정규화 -> 클라 무변경.
// 배포: supabase functions deploy search-books --no-verify-jwt

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Content-Type': 'application/json',
};

type Item = {
  title: string; author: string; isbn: string; image: string;
  description: string; publisher: string; pubdate: string;
};

const clean = (b: Item): Item => ({
  title: String(b.title ?? ''),
  author: String(b.author ?? ''),
  isbn: String(b.isbn ?? ''),
  image: String(b.image ?? '').replace('http://', 'https://'),
  description: String(b.description ?? ''),
  publisher: String(b.publisher ?? ''),
  pubdate: String(b.pubdate ?? ''),
});

async function fromGoogle(query: string): Promise<Item[] | null> {
  const key = Deno.env.get('GOOGLE_BOOKS_API_KEY');
  if (!key) return null;
  const p = new URLSearchParams({ q: query, maxResults: '40', printType: 'books', country: 'US', orderBy: 'relevance', key });
  const res = await fetch(`https://www.googleapis.com/books/v1/volumes?${p}`);
  if (!res.ok) { console.error('google', res.status, (await res.text()).slice(0, 200)); return null; }
  const data = await res.json();
  return (data.items ?? []).map((v: any) => {
    const vi = v?.volumeInfo ?? {};
    const ids: any[] = vi.industryIdentifiers ?? [];
    const isbn = ids.find((i) => i.type === 'ISBN_13')?.identifier ?? ids.find((i) => i.type === 'ISBN_10')?.identifier ?? '';
    return clean({
      title: vi.title, author: Array.isArray(vi.authors) ? vi.authors.join(', ') : '',
      isbn, image: vi.imageLinks?.thumbnail ?? vi.imageLinks?.smallThumbnail ?? '',
      description: vi.description ?? '', publisher: vi.publisher ?? '',
      pubdate: String(vi.publishedDate ?? '').replace(/-/g, ''),
    });
  }).filter((b: Item) => b.title && b.isbn);
}

async function fromNaver(query: string): Promise<Item[] | null> {
  const id = Deno.env.get('NAVER_CLIENT_ID'); const secret = Deno.env.get('NAVER_CLIENT_SECRET');
  if (!id || !secret) return null;
  const res = await fetch(
    `https://openapi.naver.com/v1/search/book.json?query=${encodeURIComponent(query)}&display=40`,
    { headers: { 'X-Naver-Client-Id': id, 'X-Naver-Client-Secret': secret } },
  );
  if (!res.ok) { console.error('naver', res.status, (await res.text()).slice(0, 200)); return null; }
  const data = await res.json();
  // 네이버 아이템은 이미 목표 형태(title/author/isbn/image/description/publisher/pubdate).
  return (data.items ?? []).map((x: any) => clean(x)).filter((b: Item) => b.title);
}

async function fromOpenLibrary(query: string): Promise<Item[]> {
  const p = new URLSearchParams({ q: query, limit: '40', fields: 'title,author_name,isbn,cover_i,first_publish_year,publisher' });
  const res = await fetch(`https://openlibrary.org/search.json?${p}`);
  if (!res.ok) return [];
  const data = await res.json();
  return (data.docs ?? []).map((d: any) => {
    const arr: string[] = d.isbn ?? [];
    const isbn = arr.find((s) => s.length === 13) ?? arr[0] ?? '';
    const image = d.cover_i
      ? `https://covers.openlibrary.org/b/id/${d.cover_i}-M.jpg`
      : (isbn ? `https://covers.openlibrary.org/b/isbn/${isbn}-M.jpg` : '');
    return clean({
      title: d.title, author: Array.isArray(d.author_name) ? d.author_name.join(', ') : '',
      isbn, image, description: '',
      publisher: Array.isArray(d.publisher) ? d.publisher[0] : '',
      pubdate: String(d.first_publish_year ?? ''),
    });
  }).filter((b: Item) => b.title && b.isbn);
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  const ok = (items: Item[]) =>
    new Response(JSON.stringify({ items, total: items.length }), { headers: corsHeaders });
  try {
    const { query } = await req.json();
    const q = String(query ?? '').trim();
    if (!q) return ok([]);

    let items: Item[] | null = null;
    try { items = await fromGoogle(q); } catch (e) { console.error('google throw', e); }
    if (!items || !items.length) { try { items = await fromNaver(q); } catch (e) { console.error('naver throw', e); } }
    if (!items || !items.length) { try { items = await fromOpenLibrary(q); } catch (e) { console.error('ol throw', e); } }
    return ok(items ?? []);
  } catch (error) {
    console.error('search-books error:', error instanceof Error ? error.message : error);
    return ok([]); // 절대 500 안 던짐
  }
});
