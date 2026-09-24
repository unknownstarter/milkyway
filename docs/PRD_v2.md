# Milkyway Business & Product Direction v2

> **문서 상태: 정본 (2026-09-24 채택).** 제품 정의·BM·가격·AI/검색 아키텍처·MVP 우선순위·비용 원칙의 정본.
> 톤·Lyra 인격·IA·영구 금지는 `VISION_v3.md`가 정본이며 그쪽이 우선한다.
> 코드와 어긋나면 **코드가 우선, 문서를 고친다.** 실행 결정과 코드 현실 대조는 문서 끝 §39 참조.

## 0. 이 문서의 목적

이 문서는 Milkyway의 앞으로의 제품 개발, 비즈니스 모델, AI 기능, 데이터 구조, 기술 아키텍처를 결정하는 최상위 기준 문서다.

앞으로 새로운 기능을 제안하거나 개발할 때는 반드시 이 문서의 방향과 일치하는지 먼저 검토한다.

우리는 기능을 많이 만드는 것이 목표가 아니다.

우리가 검증해야 하는 가장 중요한 질문은 다음이다.

> 독서 메모를 지속적으로 축적하는 사용자는, 과거에 남긴 생각을 다시 찾고 연결하고 활용할 수 있게 해주는 기능에 실제 돈을 지불하는가?

---

# 1. Milkyway의 새로운 정의

Milkyway는 단순한 독서 기록 앱이 아니다.

또한 AI가 책을 요약해주는 서비스도 아니다.

Milkyway는 사용자가 책을 읽으며 남긴 생각을 장기적으로 축적하고, 나중에 다시 찾고 연결하고 활용할 수 있도록 만드는 서비스다.

한 문장으로 표현하면:

> **Milkyway는 내가 읽으며 남긴 생각을 평생 사용할 수 있는 지식 자산으로 바꾸는 Personal Reading Intelligence다.**

더 장기적으로는:

> **Milkyway는 내가 무엇을 읽었는지가 아니라, 그 과정에서 무엇을 생각해왔는지를 기억하는 Personal Intellectual Memory가 된다.**

---

# 2. Vision

## Long-term Vision

> **사람이 평생 읽고 생각한 것을 잃어버리지 않게 한다.**

사람들은 많은 것을 읽는다.

그러나 대부분은 사라진다.

책을 읽으며 밑줄을 긋고 메모를 남기지만 시간이 지나면:

* 어디에 적었는지 기억하지 못하고
* 정확한 단어가 기억나지 않아 검색하지 못하고
* 다른 책에서 비슷한 생각을 했다는 사실을 알아차리지 못하고
* 당시의 생각이 어떻게 변했는지 확인하지 못하고
* 실제 업무나 삶에 다시 활용하지 못한다.

Milkyway는 이 문제를 해결한다.

```text
READ
↓
THINK
↓
RECORD
↓
REMEMBER
↓
CONNECT
↓
REUSE
```

기존 독서 앱이 READ와 RECORD를 돕는다면,

Milkyway는 그 이후인

> **REMEMBER → CONNECT → REUSE**

를 핵심 가치로 삼는다.

---

# 3. 우리가 해결하는 문제

## Target User

첫 번째 핵심 고객은 모든 독서가가 아니다.

다음과 같은 사람이다.

> 업무, 커리어, 사업, 자기계발 등을 위해 지속적으로 비문학 책을 읽으며 책에 밑줄을 긋거나 메모를 남기는 지식노동자.

예:

* Product Owner
* Product Manager
* Designer
* Developer
* Marketer
* Founder
* Consultant
* Researcher
* Writer
* 대학원생
* 전문직

이들에게 독서는 취미만이 아니다.

독서는 업무와 성장에 필요한 Input이다.

---

# 4. Customer Job

사용자의 핵심 Job은 단순히:

> “메모를 잘 저장하고 싶다.”

가 아니다.

진짜 Job은:

> **내가 과거에 읽고 생각했던 것을 필요할 때 다시 꺼내 쓰고 싶다.**

구체적으로:

```text
When
예전에 읽었던 내용이나 생각이 필요한 순간

I want to
정확한 책 이름이나 검색어를 기억하지 못해도
내가 남긴 관련 생각을 찾고

So I can
현재의 문제, 글쓰기, 업무, 의사결정에 다시 활용하고 싶다.
```

---

# 5. 핵심 Insight

정보 저장의 문제는 상당 부분 해결되어 있다.

Notion, Apple Notes, Obsidian, Readwise 등으로 정보를 저장할 수 있다.

문제는:

> **저장한 정보를 다시 활용하기 어렵다는 것이다.**

특히 인간은 자신이 과거에 어떤 단어를 사용했는지 기억하지 못한다.

따라서 정확한 Keyword Search만으로는 과거 생각을 제대로 복구하기 어렵다.

Milkyway의 핵심 Insight는:

> **사람에게 필요한 것은 더 좋은 저장 공간이 아니라, 자신이 과거에 했던 생각을 다시 발견하게 해주는 시스템이다.**

---

# 6. Business Bet

Milkyway의 첫 번째 Business Bet은 다음이다.

> **독서 메모를 지속적으로 축적하는 사용자는, 정확한 키워드를 기억하지 못해도 자신의 과거 생각을 다시 찾고 연결하고 활용할 수 있는 기능에 돈을 지불한다.**

우리는 사용자 수보다 이 가설의 증명을 우선한다.

초기 핵심 목표는:

```text
첫 유료 사용자 10명
↓
다음 달에도 사용하는가
↓
다음 달에도 결제하는가
```

이다.

---

# 7. Business Model

Milkyway의 기본 BM은 B2C Subscription이다.

초기 테스트 가격:

> Milkyway+ 월 9,900원

가격은 확정값이 아니라 검증 대상이다.

초기에는:

```text
Free
+
Milkyway+
```

두 단계만 운영한다.

---

# 8. Free와 Paid의 원칙

중요한 원칙:

> **기록에는 가능한 한 돈을 받지 않는다.**

왜냐하면 메모가 많이 쌓일수록 Milkyway+의 가치가 커져야 하기 때문이다.

## Free

무료 사용자는 계속 다음을 할 수 있다.

* 책 등록
* 독서 상태 관리
* 페이지 단위 메모 작성
* 메모 수정 / 삭제
* 기본 독서 기록
* Keyword Search
* 공개/비공개 메모
* 기본 프로필

## Milkyway+

Milkyway+는 다음 질문에 답하는 기능이다.

> **“내가 남긴 생각을 어떻게 다시 활용할 것인가?”**

핵심 기능은 우선 세 가지다.

### 1. Semantic Search

정확한 단어가 기억나지 않아도 의미가 비슷한 메모를 찾는다.

예:

사용자 검색:

> 사업을 검증하는 방법

실제 메모:

> 가장 위험한 가설부터 먼저 테스트해야 한다.

Keyword는 다르지만 의미가 유사하므로 검색된다.

---

### 2. Related Thoughts

하나의 메모를 보고 있을 때 과거의 관련 메모를 자동으로 연결한다.

예:

```text
오늘

『Good Strategy Bad Strategy』

"전략은 결국 선택이다."

↓

관련된 과거 생각

『Inspired』
"제품 전략은 무엇을 만들지 않을지를 결정하는 것이다."

↓

『Lean Startup』
"모든 가설을 검증할 필요는 없다."
```

사용자는 자신도 잊고 있던 생각 사이의 연결을 발견한다.

---

### 3. Thinking Report

사용자가 일정 기간 동안 작성한 메모를 분석하여 정기적으로 자신의 생각을 돌아볼 수 있는 리포트를 제공한다.

예:

* Weekly Thinking Report
* Monthly Thinking Report
* Yearly Thinking Report

---

# 9. AI에 대한 Product Principle

Milkyway는 AI Chat 서비스가 아니다.

AI 자체를 상품으로 팔지 않는다.

우리는:

> **AI를 사용해서 사용자의 과거 생각을 더 쉽게 발견하고 연결하고 이해하도록 한다.**

따라서 기본 원칙은:

```text
검색은 싸게
연결은 자동으로
생성 AI는 필요한 순간에만
```

이다.

LLM 호출을 제품의 모든 화면과 행동에 넣지 않는다.

---

# 10. Semantic Search

Semantic Search와 RAG는 구분한다.

Semantic Search:

```text
User Query
↓
Embedding
↓
Vector Search
↓
Relevant Notes
↓
사용자에게 결과 표시
```

LLM은 필요하지 않다.

예:

검색어:

> 사람을 잘 관리하는 법

실제 메모:

> 좋은 리더는 사람에게 답을 주는 대신 스스로 답을 찾게 한다.

Semantic Search에서는 검색 가능하다.

---

# 11. RAG

RAG는 Semantic Search 이후에 LLM을 사용하는 경우다.

```text
User Question
↓
Semantic Search
↓
Relevant Notes
↓
LLM Context
↓
Generated Answer
```

예:

사용자:

> 나는 리더십에 대해 어떤 생각을 해왔어?

Milkyway:

1. 관련 메모를 검색한다.
2. 가장 관련 높은 메모만 추출한다.
3. 해당 메모를 LLM Context로 전달한다.
4. LLM이 답변을 생성한다.

중요:

> 사용자의 모든 메모를 LLM에게 전달하지 않는다.

항상 먼저 Retrieval을 수행한다.

---

# 12. LLM Cost Principle

LLM 비용은 제품 규모와 함께 무한히 증가해서는 안 된다.

따라서 다음 원칙을 따른다.

```text
Cheap Computation First
↓
Embedding
↓
Vector Search
↓
Rule / Metadata Filtering
↓
Only when necessary
↓
LLM
```

즉:

```text
Embedding / Search
= 기본 기능

LLM Generation
= 선택 기능
```

으로 설계한다.

---

# 13. Embedding Architecture

사용자가 메모를 생성하거나 수정하면 해당 메모의 embedding을 생성한다.

```text
Note Created
↓
Normalize Text
↓
Embedding API
↓
Vector
↓
Vector DB 저장
```

매 검색 시 전체 메모를 다시 embedding하지 않는다.

메모가 변경되었을 때 해당 메모만 다시 처리한다.

---

# 14. 검색 구조

검색은 Hybrid Search를 지향한다.

```text
User Query
│
├─ Keyword Search
│
└─ Vector Search
       │
       ↓
   Result Merge
       ↓
Metadata Filter
       ↓
Ranking
       ↓
Search Result
```

가능하면:

> Keyword Search + Semantic Search

두 가지를 결합한다.

예:

PostgreSQL Full Text Search

*

pgvector

조합을 우선 고려한다.

현재 Supabase/PostgreSQL을 사용하고 있다면 pgvector 기반 구현을 우선 검토한다.

---

# 15. Metadata

Embedding만 저장하지 않는다.

검색 품질을 높이기 위해 메모에는 metadata를 함께 저장한다.

예:

```text
note_id

user_id

book_id

book_title

author

page

content

created_at

updated_at

visibility

embedding

topics

concepts
```

초기에는 topics / concepts가 없어도 된다.

---

# 16. Thinking Report

Thinking Report는 실시간 생성보다 Batch 방식으로 처리한다.

사용자가 화면을 열 때마다 전체 메모를 LLM에게 보내지 않는다.

예:

```text
매주 일요일

신규 메모 확인
↓
새로운 Embedding 확인
↓
Topic Clustering
↓
관련 과거 메모 Retrieval
↓
변화 / 연결 후보 생성
↓
LLM Summary
↓
Report 저장
```

사용자가 앱을 열면 이미 생성된 리포트를 불러온다.

---

# 17. Weekly Thinking Report

Weekly Report의 기본 구성:

```text
이번 주 작성한 메모

이번 주 읽은 책

이번 주 가장 많이 등장한 주제

새롭게 등장한 관심사

서로 연결된 생각

과거 메모와 연결된 생각

다시 볼 만한 메모
```

---

# 18. Monthly Thinking Report

Monthly Report에서는 조금 더 장기적인 패턴을 찾는다.

예:

```text
이번 달 주요 관심사

가장 많이 등장한 Concept

지난달보다 증가한 관심사

서로 연결된 책

반복적으로 등장하는 질문

최근 생각의 변화

과거 생각과 충돌하는 메모
```

---

# 19. Yearly Thinking Report

Milkyway+의 강력한 Premium Experience 후보다.

Spotify Wrapped처럼 개인이 자신의 한 해를 돌아보도록 만든다.

예:

```text
2026

읽은 책
38권

작성한 메모
642개

가장 많이 생각한 주제

Product
AI
Strategy
Leadership
Decision Making

올해 새롭게 관심을 갖기 시작한 것

올해 가장 많이 연결된 책

올해 가장 많이 다시 본 메모

올해 크게 바뀐 생각

작년의 나와 달라진 점
```

공유 가능한 Card 형태도 고려한다.

다만 개인정보와 메모 원문은 사용자가 명시적으로 선택하지 않는 이상 공유하지 않는다.

---

# 20. Batch Architecture

예시:

```text
Scheduler / Cron
↓
Eligible Users
↓
New Notes Query
↓
Embedding / Retrieval
↓
Clustering
↓
Candidate Insight Generation
↓
LLM
↓
Report JSON
↓
Database
↓
Push Notification
```

Report는 생성 후 DB에 저장한다.

앱 화면에서는 실시간 AI 호출 없이 저장된 결과를 읽는다.

---

# 21. Model Routing

모든 AI 작업에 동일한 모델을 사용하지 않는다.

작업별로 모델을 선택할 수 있도록 abstraction layer를 만든다.

예:

```text
AIService

├── embed()
├── classify()
├── summarize()
├── generateReport()
└── generateAnswer()
```

실제 provider는 교체 가능해야 한다.

```text
Embedding
→ cheap embedding model

Classification
→ cheap model

Weekly summary
→ cheap / mid model

Yearly report
→ higher quality model

RAG answer
→ query complexity에 따라 선택
```

Provider가 OpenAI, Anthropic, Google 등으로 변경되어도 Domain Layer가 영향을 받지 않도록 한다.

---

# 22. Knowledge Graph와 Ontology

현재 MVP에서는 Ontology를 만들지 않는다.

Ontology는 미래 확장 방향이다.

현재는:

```text
User
Book
Note
Embedding
Report
Subscription
```

정도면 충분하다.

향후 사용자 데이터가 충분히 쌓이면 다음 Entity를 추가할 수 있다.

```text
Topic
Concept
Connection
```

그리고:

```text
Note
→ expresses
→ Concept

Concept
→ related_to
→ Concept

Concept
→ contradicts
→ Concept

Book
→ contains
→ Concept

User
→ interested_in
→ Concept
```

형태로 확장한다.

이 단계부터 Knowledge Graph를 고려한다.

Ontology는 실제로 필요한 관계가 데이터에서 반복적으로 나타난 후 설계한다.

미리 거대한 Ontology를 설계하지 않는다.

---

# 23. 기술 발전 단계

Milkyway의 AI / Knowledge Architecture는 다음 순서로 발전한다.

```text
Phase 1
Keyword Search

↓

Phase 2
Semantic Search

↓

Phase 3
Related Thoughts

↓

Phase 4
Batch Thinking Reports

↓

Phase 5
Selective RAG

↓

Phase 6
Knowledge Graph

↓

Phase 7
Ontology / Personal Intellectual Graph
```

절대로 Phase 6~7부터 만들지 않는다.

---

# 24. Core Data Structure

초기 권장 구조:

```text
users

books

user_books

notes

note_embeddings

reports

subscriptions

ai_usage
```

예:

## notes

```text
id
user_id
book_id
page
content
visibility
created_at
updated_at
```

## note_embeddings

```text
id
note_id
user_id
embedding
embedding_model
created_at
updated_at
```

## reports

```text
id
user_id
type

weekly
monthly
yearly

period_start
period_end

content_json

model

input_note_count

generation_cost

created_at
```

## subscriptions

```text
id
user_id

plan

status

started_at

renew_at

cancelled_at
```

## ai_usage

```text
id

user_id

feature

model

input_tokens

output_tokens

estimated_cost

created_at
```

AI 비용은 반드시 측정 가능해야 한다.

---

# 25. Cost Observability

Milkyway+는 사용자당 수익뿐 아니라 사용자당 AI Cost를 추적한다.

반드시 확인할 수 있어야 하는 값:

```text
Monthly Revenue / User

Embedding Cost / User

LLM Cost / User

Report Cost / User

Total Variable AI Cost / User

Gross Margin / User
```

예:

```text
ARPU
₩9,900

AI Cost
₩400

Payment Fee
₩1,500

Contribution before fixed costs
₩8,000
```

와 같이 계산 가능해야 한다.

AI 호출을 추가하는 기능은 항상 비용 영향을 같이 검토한다.

---

# 26. Product Flywheel

Milkyway의 핵심 Flywheel은 데이터 판매가 아니다.

```text
메모 작성
↓
내 생각 축적
↓
검색 가치 증가
↓
관련 생각 연결 가치 증가
↓
Report 품질 증가
↓
Milkyway+ 가치 증가
↓
Retention 증가
↓
더 많은 메모
```

즉:

> **사용자가 서비스를 사용할수록 그 사용자에게 Milkyway의 가치가 증가해야 한다.**

이것이 개인 데이터의 역할이다.

데이터 자체를 판매하는 것이 핵심 BM이 아니다.

---

# 27. Social 기능의 위치

Milkyway는 장기적으로 Social 기능을 가질 수 있다.

그러나 현재 Business Bet의 핵심은 아니다.

순서는:

```text
Personal Knowledge
↓
Personal Value
↓
Interest Graph
↓
People Discovery
↓
Social
```

이어야 한다.

처음부터 Social Network를 만들기 위해 사용자 수를 확보하려고 하지 않는다.

Personal Product가 충분히 가치 있어야 한다.

---

# 28. 장기 Expansion

Business가 검증된 이후 다음 Job으로 확장할 수 있다.

초기:

```text
Books
+
Reading Notes
```

이후:

```text
Articles
PDF
YouTube
Podcast
Web
Meeting Notes
Documents
```

까지 확장할 수 있다.

하지만 현재 제품 범위를 무리하게 넓히지 않는다.

장기적으로는:

> **Personal Intellectual OS**

가 될 수 있다.

정리하면:

> Notion은 내가 적은 것을 저장한다.

> ChatGPT는 세상의 지식을 답한다.

> Milkyway는 내가 배운 것을 기억한다.

---

# 29. MVP Scope

현재 Milkyway에서 가장 먼저 구현하거나 개선할 기능은 다음이다.

## Priority 1

Semantic Search

사용자가 자연어로 자신의 메모를 검색한다.

## Priority 2

Related Thoughts

하나의 메모와 의미적으로 관련된 다른 메모를 보여준다.

## Priority 3

Weekly Thinking Report

배치로 사용자의 최근 생각을 정리한다.

## Priority 4

Milkyway+ Paywall

실제 결제를 받는다.

## Priority 5

Analytics

사용 및 결제를 추적한다.

---

# 30. 아직 만들지 않을 것

현재 단계에서는 다음을 우선 개발하지 않는다.

* 범용 AI Chat
* 모든 메모를 매번 LLM에 전달하는 기능
* 복잡한 Knowledge Graph
* Ontology
* AI Agent
* 출판사 B2B 분석
* 사용자 데이터 판매
* 복잡한 Social Network
* Recommendation Feed
* 범용 Personal Knowledge Management
* 책 외의 모든 콘텐츠 지원

Business Bet 검증 이후 다시 판단한다.

---

# 31. 핵심 Analytics Event

최소 다음 Event를 추적한다.

```text
note_created

keyword_search

semantic_search

semantic_search_result_clicked

related_thought_viewed

weekly_report_viewed

monthly_report_viewed

paywall_viewed

trial_started

subscription_started

subscription_renewed

subscription_cancelled
```

---

# 32. 핵심 Funnel

```text
Active Note Writer

↓

Semantic Search 사용

↓

Semantic Search 결과 클릭

↓

Related Thoughts 사용

↓

Thinking Report 확인

↓

Paywall

↓

Subscription

↓

Repeated Usage

↓

Renewal
```

---

# 33. 가장 중요한 KPI

초기에는 MAU보다 아래 지표가 중요하다.

## Product

```text
Semantic Search Adoption

Semantic Search Result CTR

Related Thoughts CTR

Thinking Report Open Rate

Weekly Returning Users
```

## Business

```text
Paywall → Trial

Trial → Paid

Paid User Weekly Retention

Month 1 → Month 2 Paid Retention

ARPU

AI Cost / Paid User

Contribution Margin
```

---

# 34. 현재 가장 중요한 Evidence

우리가 가장 먼저 증명해야 하는 것은:

```text
User가 기능을 좋아한다
```

가 아니다.

순서는:

```text
사용한다

↓

반복해서 사용한다

↓

Paywall을 본다

↓

결제한다

↓

다음 달에도 사용한다

↓

다음 달에도 결제한다
```

이다.

가장 강한 Evidence는 반복 결제다.

---

# 35. 현재 가장 중요한 Experiment

## Hypothesis

> 독서 메모를 지속적으로 축적하는 사용자는 Semantic Search, Related Thoughts, Thinking Report를 사용하기 위해 월 구독료를 지불한다.

## Initial Target

기존 Milkyway 사용자 중:

```text
메모를 지속적으로 작성했고

메모가 일정량 이상 존재하며

최근에도 앱을 사용한 사용자
```

를 우선 대상으로 한다.

## Test

Milkyway+ 출시.

초기 가격 가설:

```text
₩9,900 / month
```

## Success의 방향

단순 가입자 수가 아니다.

우선:

```text
실제 Paid User 발생

↓

Paid Feature 반복 사용

↓

다음 Billing Cycle Renewal
```

을 본다.

정확한 성공 Threshold는 현재 사용자 수와 기존 행동 데이터를 확인한 뒤 결정한다.

---

# 36. Engineering Principle

모든 개발 결정은 다음 질문을 통과해야 한다.

### 1.

이 기능이 현재 Business Bet 검증에 필요한가?

### 2.

사용자가 실제로 더 자주 돌아오거나 돈을 내게 만드는가?

### 3.

더 싸고 빠르게 검증할 방법은 없는가?

### 4.

LLM이 반드시 필요한가?

### 5.

Embedding / Search / Rule로 해결할 수 없는가?

### 6.

AI 비용이 사용자 증가에 따라 어떻게 증가하는가?

### 7.

이 기능이 실패했을 때 쉽게 제거할 수 있는가?

---

# 37. Claude Code에게 요구하는 개발 원칙

이 프로젝트를 수정하거나 새로운 기능을 개발할 때 다음 과정을 따른다.

```text
1. 현재 코드 구조 분석

2. 기존 DB Schema 분석

3. 기존 기능과 중복 여부 확인

4. 문제 정의

5. 가장 작은 구현 방법 제안

6. 기술 설계

7. 비용 영향 확인

8. 구현

9. 테스트 코드 작성

10. 테스트 실행

11. 코드 리뷰

12. Analytics 확인

13. 결과 회고
```

새로운 기술이나 라이브러리를 바로 추가하지 않는다.

기존 Stack으로 해결 가능한지 먼저 확인한다.

---

# 38. Architecture Principle

Clean Architecture 원칙을 유지한다.

Domain이 외부 AI Provider에 의존하지 않도록 한다.

예:

```text
Presentation

↓

Application

↓

Domain

↓

Infrastructure
```

AI Provider, Vector DB, Payment Provider 등은 Infrastructure Layer에 위치시킨다.

Domain에서는 Interface만 사용한다.

예:

```text
EmbeddingRepository

SemanticSearchRepository

AICompletionService

ReportGenerationService
```

OpenAI 등의 특정 Provider 이름이 Domain Logic에 직접 들어가면 안 된다.

---

# 39. 현재 제품의 핵심 구조

최종적으로 현재 Milkyway는 다음 경험에 집중한다.

```text
읽는다

↓

기록한다

↓

잊는다

↓

Milkyway가 다시 찾아준다

↓

예전 생각과 연결한다

↓

지금의 문제에 다시 활용한다
```

우리가 판매하는 것은 AI가 아니다.

검색도 아니다.

메모 저장도 아니다.

우리가 판매하는 것은:

> **“내가 과거에 읽고 생각했던 것을 잃어버리지 않는 경험”**

이다.

---

# 40. Final Product Principle

Milkyway의 제품 방향을 결정할 때 가장 중요한 문장은 다음이다.

> **Don't help people save more information.
> Help them rediscover what they once thought.**

그리고 Milkyway+의 가장 단순한 정의는:

> **무료 사용자는 읽고 기록한다.**

> **Milkyway+ 사용자는 기록한 생각을 다시 찾고, 연결하고, 활용한다.**

앞으로 모든 Product / Business / Engineering Decision은 이 원칙을 기준으로 한다.

---

# 39. 실행 결정 로그 (2026-09-24)

이 문서 채택 시점에 코드 현실과 대조한 결과, 그리고 그 자리에서 내린 결정.

## 39.1 코드 현실 대조 - 이미 만들어져 있던 것

이 문서가 "앞으로 만들 것"으로 적은 항목 중 상당수는 `20260822152417_connectome_schema` 로 이미 살아 있다.

| 이 문서의 항목 | 실제 상태 |
|---|---|
| §13 Embedding Architecture | **구현됨.** `memo_embeddings` (pgvector 1024차원 + HNSW), Voyage 임베딩 |
| §24 note_embeddings | **이름이 다를 뿐 존재.** 실제 테이블명은 `memo_embeddings` |
| §29 P2 Related Thoughts | **출시됨.** `memo_edges` + `get_constellation` + 별자리 화면 |
| 임베딩 생성 파이프라인 | **작동 중.** `connect-memo` 엣지 함수가 메모 저장 시 자동 생성 |
| §29 P1 Semantic Search | **미구현.** `match_memos`는 메모→메모용이라 검색에 못 쓴다 |
| 키워드 검색 (§8 Free) | **미구현.** 내 메모를 찾는 검색이 앱에 아예 없다 |
| §24 subscriptions / ai_usage | **미구현.** 결제 코드 흔적 0 |

실측 (2026-09-24): 메모 195개 중 임베딩 154개(79%), 엣지 28개. **미임베딩 41개 백필 필요.**

## 39.2 결정 - 유료 기능은 "검색 먼저, 라이라는 그 위에"

§10 Semantic Search(LLM 불필요)와 §11 RAG(LLM 사용)는 비용 구조가 다르다.
둘 중 하나를 고르지 않고 **쌓는다.**

```text
1. 메모 키워드 검색        [무료]   - PostgreSQL. AI 비용 0
        ↓ 같은 검색 화면 위에
2. 의미 검색               [Milkyway+] - 쿼리 임베딩 1회. LLM 없음
        ↓ 검색 결과를 컨텍스트로
3. Lyra 대화형 검색 (RAG)  [Milkyway+] - 여기서 처음 LLM 호출
```

근거: §36 Engineering Principle 3번("더 싸고 빠르게 검증할 방법은 없는가").
2단계가 3단계의 Retrieval 부품이라 버려지는 작업이 없다. 3단계가 실패해도 2단계는 남는다(§36 7번).

## 39.3 결정 - 인앱결제를 함께 붙인다

2·3단계가 유료인 이상 잠글 자물쇠가 같은 사이클에 필요하다.

- 스토어 정책상 디지털 구독은 **앱스토어/플레이 인앱결제 필수** (외부 결제 불가)
- 신규 테이블 2개: `subscriptions` (§24) · `ai_usage` (§24). 기존 스키마 불변
- **서버가 진실의 원천.** 클라이언트 구매 상태를 신뢰하지 않고 서버 검증 결과로 게이팅한다
- `ai_usage`는 페이월과 동시에 들어간다. 나중에 붙이면 §25 Cost Observability가 공백으로 시작한다

### 결제 스택: RevenueCat (2026-09-24 확정)

`in_app_purchase`(Flutter 공식)가 아니라 **RevenueCat**을 쓴다.

| | RevenueCat | in_app_purchase |
|---|---|---|
| 영수증 검증·갱신·환불·유예기간 | 대행 | 직접 구현 |
| 애플 Server API JWT(ES256) 서명 | 불필요 | 필요 |
| 구글 Pub/Sub 실시간 알림(RTDN) | 불필요 | 필요 |
| 비용 | 월 매출 $2.5k까지 무료 | 무료 |

근거: §36 3번("더 싸고 빠르게 검증할 방법은 없는가"). 지금 목표는 결제 인프라를 잘 만드는 것이 아니라
**사람이 돈을 내는지 검증하는 것**이다. §37("새 라이브러리를 바로 추가하지 않는다")에는 형식상 어긋나지만,
결제 스택은 기존 스택에 아예 없던 영역이고 RevenueCat 쪽이 **새로 만들 표면적이 더 작다.**

구현 형태:
```text
앱(RevenueCat SDK) -> 구매
        v
RevenueCat 웹훅 -> Supabase Edge Function -> subscriptions 테이블 갱신
        v
앱은 subscriptions 를 읽어 게이팅 (클라이언트 구매 상태 신뢰 안 함)
```

수수료: 9,900원 기준 실수령 약 8,400원 (애플/구글 소규모 사업자 프로그램 15%).
구독 상품 등록(App Store Connect / Play Console)은 **운영자가 직접** 해야 하는 수동 선행 작업이다.

