# 심사 제출용 리뷰어 노트 (매 제출 재사용)

App Store Connect의 **App Review Information > Notes** 와
Play Console의 **앱 콘텐츠 > 테스트 안내** 에 붙여넣는다.

`<SUPPORT_EMAIL>` 자리에 실제 서포트 주소를 채워 넣을 것.

---

## 붙여넣을 문구 (영문, 리뷰어용)

```
About the app
milkyway is a reading journal. Users save books, write memos about them, and can
make a memo public so other users see it.

Important: memos and comments are social content
Anything saved as a memo or posted as a comment becomes visible to other users
inside the app, and it stays there after the review session ends.

So please avoid typing email addresses into memos or comments while testing.
Our support address (<SUPPORT_EMAIL>) has been entered as memo and comment text
in past reviews, and it then showed up publicly to real users, who replied to it.
Any placeholder text works for testing, for example "test memo 1".

The same applies to personal data of any kind. If you need to verify posting,
deleting, reporting or commenting, plain placeholder text exercises every path.

Removing test content
Every memo and comment can be deleted in the app by its author, from the memo
detail screen and the comment list. If anything needs to be removed after the
review, contact us at <SUPPORT_EMAIL> and we will delete it server side.

Sign in
Google and Apple sign in are both available on the login screen.
Test account: <TEST_ID> / <TEST_PW>

Languages
The app ships in Korean, English, Japanese and Chinese. It follows the device
language on first launch, and the language can be changed at any time in
Profile > Language.
```

---

## 왜 넣는가

메모와 댓글은 **공개 소셜 콘텐츠**다. 리뷰어가 테스트로 남긴 문자열이 실제 사용자에게
그대로 노출되고, 서포트 이메일이 적혀 있으면 사용자가 거기로 답장을 보낸다.
심사 때마다 반복되므로 제출 노트에 상시 포함한다.

## 제출 전 체크리스트

- [ ] `<SUPPORT_EMAIL>` / `<TEST_ID>` / `<TEST_PW>` 실제 값으로 치환했나
- [ ] 실기기 Google 로그인 / Apple 로그인 (iOS scene 라이프사이클 영역)
- [ ] 지난 심사 때 남은 테스트 메모/댓글이 아직 공개로 떠 있지 않은지 확인
- [ ] 푸시 알림 탭 라우팅 / 딥링크
