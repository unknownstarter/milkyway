# 심사 제출용 리뷰어 노트 (매 제출 재사용)

App Store Connect의 **App Review Information > Notes**,
Play Console의 **앱 콘텐츠 > 테스트 안내** 에 붙여넣는다.
`<SUPPORT_EMAIL>` 자리에 실제 서포트 주소를 채울 것.

테스트 계정은 넣지 않는다. 줘도 리뷰어가 직접 가입해서 자기 계정으로 테스트한다.

---

## 붙여넣을 문구 (영문)

```
Hi, one quick note before you start.

Memos and comments in milkyway are public. Other users see them, and they stay
visible after the review ends. In a past review our support address
(<SUPPORT_EMAIL>) was typed into a memo as test text, and real users started
emailing it.

So when you need to post something, any placeholder works, for example
"test memo 1". Just please keep real email addresses out of memos and comments.

Google and Apple sign in both work on the login screen. Thanks, and enjoy the app.
```

---

## 왜 넣는가

메모와 댓글은 **공개 소셜 콘텐츠**다. 리뷰어가 테스트로 남긴 문자열이 실제 사용자에게
그대로 노출되고, 서포트 이메일이 적혀 있으면 사용자가 거기로 답장을 보낸다.
심사 때마다 반복되므로 제출 노트에 상시 포함한다.

## 제출 전 체크리스트

- [ ] `<SUPPORT_EMAIL>` 실제 주소로 치환했나
- [ ] 실기기 Google 로그인 / Apple 로그인 (iOS scene 라이프사이클 영역)
- [ ] 지난 심사 때 남은 테스트 메모/댓글이 아직 공개로 떠 있지 않은지 확인
- [ ] 푸시 알림 탭 라우팅 / 딥링크
