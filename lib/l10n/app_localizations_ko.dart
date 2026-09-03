// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppL10nKo extends AppL10n {
  AppL10nKo([String locale = 'ko']) : super(locale);

  @override
  String get appName => 'milkyway';

  @override
  String get commonSave => '저장';

  @override
  String get commonCancel => '취소';

  @override
  String get commonNext => '다음';

  @override
  String get commonClose => '닫기';

  @override
  String get commonConfirm => '확인';

  @override
  String get commonRetry => '다시 시도';

  @override
  String get settingsLanguage => '언어';

  @override
  String get languageSystem => '기기 설정';

  @override
  String get languageKorean => '한국어';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageJapanese => '日本語';

  @override
  String get languageChinese => '中文';

  @override
  String get unitBooks => '권';

  @override
  String get unitCount => '개';

  @override
  String get unitDays => '일';

  @override
  String get statBooksRead => '읽은 책';

  @override
  String get statMemosLeft => '남긴 메모';

  @override
  String get statTopPercent => '상위';

  @override
  String get statStreak => '연속';

  @override
  String get constellationTitle => '별자리';

  @override
  String get constellationLoadError => '별자리를 불러오지 못했어';

  @override
  String get constellationEmptyTitle => '아직 이어진 별이 없어';

  @override
  String get constellationEmptyBody => '메모가 쌓이면 서로 이어져 밤하늘이 생겨';

  @override
  String constellationConnected(int count) {
    return '이어진 순간 $count';
  }

  @override
  String get constellationWhenPast => '그때';

  @override
  String get constellationWhenNow => '지금';

  @override
  String get constellationRelExtends => '확장';

  @override
  String get constellationRelReverses => '달라짐';

  @override
  String get constellationRelEcho => '다시 떠오름';

  @override
  String get constellationRelSimilar => '닮음';

  @override
  String get constellationRelDefault => '연결';

  @override
  String get constellationRevealTitle => '선이 하나 그어졌어';

  @override
  String get constellationViewInConstellation => '별자리에서 보기';

  @override
  String get lyraQuestionLabel => 'Lyra의 물음';

  @override
  String get lyraAnswerCta => '이 물음에 메모 남기기';

  @override
  String get orbTierNebulaSmall => '작은 성운';

  @override
  String get orbTierStarCluster => '별무리';

  @override
  String get orbTierConstellation => '별자리';

  @override
  String get orbTierCluster => '성단';

  @override
  String get orbTierGalaxy => '은하';

  @override
  String get orbTierSuperGalaxy => '대은하';

  @override
  String get orbMyUniverseTitle => '내 우주';

  @override
  String get orbNowPrefix => '지금은 ';

  @override
  String orbTierBadge(String name) {
    return '$name 단계';
  }

  @override
  String orbToNextTier(String next) {
    return '다음 단계 $next까지 ';
  }

  @override
  String get orbDeepestReached => '가장 깊은 우주에 도달';

  @override
  String get orbShareLinkCopied => '공유하기 링크가 복사되었어요';

  @override
  String get orbShareError => '공유 준비 중 문제가 생겼어요. 잠시 후 다시 시도해요';

  @override
  String get orbGateBannerTitle => '첫 오브를 만들어보세요';

  @override
  String orbGateBannerBody(int count) {
    return '메모 $count개면 은하수가 생겨';
  }

  @override
  String orbGateSheetTitle(int count) {
    return '오브가 $count개 남았어요';
  }

  @override
  String orbGateSheetBody(int count) {
    return '메모를 $count개 더 남기면\n나만의 은하수 오브가 완성돼요';
  }

  @override
  String get orbGateWriteCta => '지금 메모 쓰기';

  @override
  String get shareCardDefaultNick => '나';

  @override
  String shareCardOwnerUniverse(String nick) {
    return '$nick의 우주';
  }

  @override
  String get shareCardTagline => '너의 우주는 어떤 모양일까';

  @override
  String get shareCardStoreHint => 'App Store / Google Play 에 milkyway';

  @override
  String get wrappedTitle => '은하 회고';

  @override
  String wrappedHeroLead(String month) {
    return '$month, 네가';
  }

  @override
  String get wrappedHeroAccent => '멈춘 순간들';

  @override
  String wrappedStarsLeft(int count) {
    return '그 자리에 남은 $count개의 별';
  }

  @override
  String get wrappedStatSentences => '멈춘 문장';

  @override
  String get wrappedStatReadDays => '읽은 날';

  @override
  String get wrappedTopBookLabel => '가장 오래 머문 책';

  @override
  String get wrappedQuoteLabel => '그 달의 문장';

  @override
  String wrappedQuoteSource(String title) {
    return '$title에서';
  }

  @override
  String get wrappedShareCta => '회고 공유하기';

  @override
  String get wrappedEmptyTitle => '이번 달 회고는 아직 준비 중이에요';

  @override
  String get wrappedEmptyBody => '메모를 남기면 그 자리에 별이 쌓여요';

  @override
  String get wrappedLoadErrorTitle => '회고를 불러오지 못했어요';

  @override
  String get wrappedLoadErrorBody => '잠시 후 다시 시도해요';

  @override
  String get wrappedShareLinkCopied => '공유하기 링크가 복사되었어요';

  @override
  String get wrappedShareError => '공유 준비 중 문제가 생겼어요. 잠시 후 다시 시도해요';

  @override
  String get commonShare => '공유하기';

  @override
  String get orbLoadErrorTitle => '우주를 불러오지 못했어요';

  @override
  String wrappedEntryTitle(String month) {
    return '$month 은하 회고';
  }

  @override
  String wrappedEntryBody(int count) {
    return '그 자리에 남은 별 $count개';
  }

  @override
  String get authSignInApple => 'Apple로 시작하기';

  @override
  String get authSignInGoogle => 'Google로 시작하기';

  @override
  String get authSignInFailed => '로그인에 실패했습니다. 다시 시도해 주세요';

  @override
  String get authNotificationPermissionTitle => '알림 권한';

  @override
  String get authNotificationPermissionBody => '내가 읽고 있는 책에 새로운 메모가 등록되면 알려드려요';

  @override
  String get authNotificationPermissionLater => '나중에';

  @override
  String get authNotificationPermissionAllow => '허용';

  @override
  String get splashUpdateTitle => '업데이트 필요';

  @override
  String get splashUpdateBody => '새로운 버전이 있습니다.\n원활한 사용을 위해 업데이트를 진행해주세요';

  @override
  String get splashUpdateAction => '업데이트';

  @override
  String get onboardingSkip => '건너뛰기';

  @override
  String get onboardingNicknameTitle => '닉네임 설정';

  @override
  String get onboardingNicknameHeading => '닉네임을 설정해주세요';

  @override
  String get onboardingNicknameSubtitle => '밀키웨이의 다른 유저가 볼 수 있는 이름이에요';

  @override
  String get onboardingNicknameLabel => '닉네임';

  @override
  String get onboardingNicknameHint => '닉네임을 입력하세요';

  @override
  String get onboardingNicknameChecking => '확인 중...';

  @override
  String get onboardingNicknameHelp => '2 - 20자, 특수문자 사용 불가';

  @override
  String get onboardingNicknameErrorTooShort => '닉네임은 최소 2자 이상이어야 합니다';

  @override
  String get onboardingNicknameErrorTooLong => '닉네임은 최대 20자까지 입력 가능합니다';

  @override
  String get onboardingNicknameErrorSpecialChars => '특수문자는 사용할 수 없습니다';

  @override
  String get onboardingNicknameErrorTaken => '이미 사용 중인 닉네임입니다';

  @override
  String get onboardingNicknameErrorCheckFailed => '닉네임 확인 중 오류가 발생했습니다';

  @override
  String onboardingNicknameSaveError(String error) {
    return '닉네임 설정 중 오류가 발생했습니다: $error';
  }

  @override
  String get onboardingProfileImageTitle => '프로필 사진';

  @override
  String get onboardingProfileImageHeading => '프로필 사진을 설정해주세요';

  @override
  String get onboardingProfileImageSubtitle => '나중에 언제든지 변경할 수 있어요';

  @override
  String get onboardingProfileImageDescription =>
      '등록된 프로필 사진은\n남겨주신 메모와 함께 보여져요';

  @override
  String get onboardingProfileImageNote => '공개 설정한 메모만 보여지니 걱정마세요';

  @override
  String get onboardingGenreTitle => '취향';

  @override
  String get onboardingGenreHeading => '어떤 결의 책을\n좋아하나요';

  @override
  String get onboardingGenreSubtitle => '취향을 알려주면 첫 책을 더 잘 골라드려요\n하나 이상 골라주세요';

  @override
  String onboardingGenreNextCount(int count) {
    return '$count개 고르고 다음';
  }

  @override
  String get onboardingGenreSelectAtLeastOne => '한 개 이상 골라주세요';

  @override
  String get onboardingGenreNovel => '소설';

  @override
  String get onboardingGenrePoetry => '시';

  @override
  String get onboardingGenreEssay => '에세이';

  @override
  String get onboardingGenreHumanities => '인문';

  @override
  String get onboardingGenrePhilosophy => '철학';

  @override
  String get onboardingGenreScience => '과학';

  @override
  String get onboardingGenreSciFi => 'SF';

  @override
  String get onboardingGenreHistory => '역사';

  @override
  String get onboardingGenreArt => '예술';

  @override
  String get onboardingGenrePsychology => '심리';

  @override
  String get onboardingGenreBusiness => '경제경영';

  @override
  String get onboardingGenreSelfHelp => '자기계발';

  @override
  String get onboardingBookIntroTitle => '시작하기';

  @override
  String get onboardingBookIntroDescription =>
      '이제 책을 읽으며\n떠오른 반짝이는 생각을\n메모하고 저장해요 ✨';

  @override
  String get onboardingBookIntroStart => '책 검색하고 시작하기';

  @override
  String get onboardingBookIntroSkip => '다음에 하기';

  @override
  String get bookStatusWantToRead => '읽고 싶은';

  @override
  String get bookStatusReading => '읽는 중';

  @override
  String get bookStatusCompleted => '완독';

  @override
  String get bookFilterAll => '모든 책';

  @override
  String get bookShelfLoadError => '책을 불러오지 못했어';

  @override
  String get bookShelfEmpty => '새로운 책을 추가해주세요';

  @override
  String get bookDetailTitle => '책 상세페이지';

  @override
  String get bookActionDelete => '삭제';

  @override
  String get bookDescriptionTitle => '책 소개';

  @override
  String get bookShowMore => '더보기';

  @override
  String get bookMemosTitle => '이 책의 메모';

  @override
  String get bookMemoSegmentTogether => '함께';

  @override
  String get bookMemoSegmentMine => '내 메모';

  @override
  String get bookMemosLoadError => '메모를 불러오지 못했어요';

  @override
  String get bookMemosEmptyPublic => '아직 공개된 메모가 없어요';

  @override
  String get bookMemosEmptyMine => '아직 남긴 메모가 없어요';

  @override
  String get bookMemoDefaultAuthor => '밀키웨이';

  @override
  String get bookTimeJustNow => '방금';

  @override
  String bookTimeMinutesAgo(int count) {
    return '$count분 전';
  }

  @override
  String bookTimeHoursAgo(int count) {
    return '$count시간 전';
  }

  @override
  String bookTimeDaysAgo(int count) {
    return '$count일 전';
  }

  @override
  String get bookWriteMemoCta => '메모하기';

  @override
  String get bookDetailLoadError => '책 정보를 불러오지 못했어요';

  @override
  String bookStatusChanged(String status) {
    return '$status 상태로 바꿨어요';
  }

  @override
  String get bookDeleteTitle => '책 삭제';

  @override
  String get bookDeleteBody =>
      '책을 삭제하면 그 책의 메모도 모두 삭제되고 되돌릴 수 없어요.\n\n정말 삭제할까요?';

  @override
  String get bookSearchTitle => '책 검색';

  @override
  String get bookSearchHint => '책 제목, 저자, ISBN으로 검색하세요';

  @override
  String get bookSearchError => '검색 중 오류가 발생했어요';

  @override
  String get bookSearchEmptyTitle => '검색 결과가 없어요';

  @override
  String get bookSearchEmptyBody => '다른 키워드로 검색해보세요';

  @override
  String get bookAlreadyAdded => '이미 등록된 책이에요';

  @override
  String get bookAdded => '책을 등록했어요';

  @override
  String get bookAddedNew => '새 책을 등록했어요';

  @override
  String get bookAddFailed => '책 등록에 실패했어요';

  @override
  String get bookOpStatusChange => '책 상태 변경';

  @override
  String get bookOpDelete => '책 삭제';

  @override
  String get bookOpRegister => '책 등록';

  @override
  String get bookOpConnect => '책 연결';

  @override
  String get readingLogTodayCta => '오늘 읽음';

  @override
  String get readingLoggedToday => '오늘 읽었어요';

  @override
  String get calendarTitle => '기록';

  @override
  String get calendarSegmentMemos => '메모';

  @override
  String get calendarSegmentRead => '읽음';

  @override
  String get calendarEmptyMemos => '이 날 남긴 메모가 없어요';

  @override
  String get calendarEmptyBooks => '이 날 읽은 책이 없어요';

  @override
  String get commentAnonymousAuthor => '밀키웨이';

  @override
  String get commentMineTag => '나';

  @override
  String get commentEdit => '수정하기';

  @override
  String get commentDelete => '삭제하기';

  @override
  String get commentHide => '이 댓글 숨기기';

  @override
  String get commentReport => '신고하기';

  @override
  String get commentComposerLocked => '책을 담으면 댓글을 남길 수 있어';

  @override
  String get commentComposerEditHint => '댓글 수정';

  @override
  String get commentComposerHint => '댓글 남기기';

  @override
  String get commentSendError => '댓글을 못 남겼어';

  @override
  String get commentDeleteTitle => '댓글 삭제';

  @override
  String get commentDeleteMessage => '이 댓글을 지울까';

  @override
  String get commentDeleteConfirm => '삭제';

  @override
  String get commentDeleteError => '못 지웠어';

  @override
  String get commentHideError => '못 숨겼어';

  @override
  String get commentReportReasonTitle => '신고 사유';

  @override
  String get commentReportSpam => '스팸/도배';

  @override
  String get commentReportInappropriate => '부적절한 내용';

  @override
  String get commentReportHarassment => '괴롭힘/혐오';

  @override
  String get commentReportSexual => '선정적';

  @override
  String get commentReportOther => '기타';

  @override
  String get commentReportDone => '신고했어. 이 댓글은 이제 안 보여';

  @override
  String get commentReportError => '신고하지 못했어';

  @override
  String get commentSaveBookTitle => '책 담기';

  @override
  String get commentSaveBookMessage => '이 책을 담아야 댓글을 남길 수 있어. 담을까';

  @override
  String get commentSaveBookConfirm => '담기';

  @override
  String get commentSaveBookError => '책을 못 담았어';

  @override
  String get commentLoadError => '댓글을 못 불러왔어';

  @override
  String get commentSectionTitle => '댓글';

  @override
  String commentSectionTitleCount(int count) {
    return '댓글 $count';
  }

  @override
  String get commentEmpty => '첫 댓글을 남겨봐';

  @override
  String get shareLandingCta => '나도 내 우주를 만들 수 있어요';

  @override
  String get shareLandingCtaButton => '나도 만들기';

  @override
  String get shareLandingErrorTitle => '카드를 불러오지 못했어요';

  @override
  String get shareLandingErrorBody => '링크가 만료되었거나 삭제된 카드일 수 있어요';

  @override
  String get shareLandingGoHome => '홈으로';

  @override
  String get commonEdited => '수정됨';

  @override
  String get commonMyMemo => '내 메모';

  @override
  String commonPageLabel(int page) {
    return '$page쪽';
  }

  @override
  String get commonLoadFailed => '불러오지 못했어';

  @override
  String get commonComposeHint => '오늘 읽은 문장을 남겨보세요';

  @override
  String get commonTimeJustNow => '방금';

  @override
  String commonTimeMinutesAgo(int minutes) {
    return '$minutes분 전';
  }

  @override
  String commonTimeHoursAgo(int hours) {
    return '$hours시간 전';
  }

  @override
  String commonTimeDaysAgo(int days) {
    return '$days일 전';
  }

  @override
  String get commonNavHome => '홈';

  @override
  String get commonNavBooks => '책 목록';

  @override
  String get commonNavMemos => '메모';

  @override
  String get commonNavProfile => '프로필';

  @override
  String get commonEmptyBookTitle => '새로운 책을 골라주세요 👇';

  @override
  String get commonEmptyBookCta => '어떤 책을 읽고 싶나요? 🤔';

  @override
  String get homeSaveBookTitle => '책 담기';

  @override
  String get homeSaveBookMessage => '이 책을 서재에 담을까';

  @override
  String get homeSaveAction => '담기';

  @override
  String get homeSaveBookError => '책을 담는 중 문제가 생겼어요';

  @override
  String get homeSectionOtherThoughts => '다른 별들이 남긴 생각들';

  @override
  String get homeDefaultAuthor => '밀키웨이';

  @override
  String get homeSectionRecentMemoBooks => '최근 메모가 올라온 책';

  @override
  String homeMemoMeta(String time) {
    return '$time 메모';
  }

  @override
  String get homeReadPromptTitle => '오늘은 어떤 책을 읽을까';

  @override
  String get homeReadPromptBody => '내 서재에서 골라보세요';

  @override
  String get homeOrbTitle => '내 우주가 자라고 있어요';

  @override
  String get homeOrbBody => '내 은하수를 확인하고 공유해요';

  @override
  String get homeConstellationTitle => '내 생각들이 이어지고 있어요';

  @override
  String get homeConstellationBody => '메모 사이에 생긴 별자리를 살펴봐요';

  @override
  String get homeWeekdayMon => '월';

  @override
  String get homeWeekdayTue => '화';

  @override
  String get homeWeekdayWed => '수';

  @override
  String get homeWeekdayThu => '목';

  @override
  String get homeWeekdayFri => '금';

  @override
  String get homeWeekdaySat => '토';

  @override
  String get homeWeekdaySun => '일';

  @override
  String get homeRecordTitle => '내 기록';

  @override
  String get homeViewAll => '전체 보기';

  @override
  String get homeTimeJustNow => '방금';

  @override
  String homeTimeMinutesAgo(int count) {
    return '$count분 전';
  }

  @override
  String homeTimeHoursAgo(int count) {
    return '$count시간 전';
  }

  @override
  String homeTimeDaysAgo(int count) {
    return '$count일 전';
  }

  @override
  String get homeWelcomeTitle => '마음이 가는 책 한 권부터';

  @override
  String get homeWelcomeBody => '담으면 Lyra가 물음을 건네요\n아래 사람들이 담은 책도 둘러보세요';

  @override
  String get homeWelcomeCta => '책 담으러 가기';

  @override
  String get homeStatusReading => '읽는 중';

  @override
  String get homeSectionSavedByOthers => '다른 사람이 담은 책';

  @override
  String get homeAddBook => '책 등록하기';

  @override
  String get homeAddMemo => '메모 작성하기';

  @override
  String get discoveryTitle => '책 담기';

  @override
  String get discoverySkip => '다음에 담기';

  @override
  String get discoveryLoadError => '추천을 불러오지 못했어요';

  @override
  String get discoveryEmpty => '아직 추천할 책이 없어요';

  @override
  String get discoveryHeading => '사람들이 메모를 남긴 책';

  @override
  String get discoveryBody => '마음이 가는 책을 담아보세요\n담은 책에 Lyra가 물음을 건네요';

  @override
  String get discoverySearchCta => '찾는 책이 없다면 직접 검색';

  @override
  String discoveryStartCta(int count) {
    return '$count권 담고 시작하기';
  }

  @override
  String get discoverySaveError => '책을 담는 중 문제가 생겼어요';

  @override
  String discoveryProofSavers(int count) {
    return '$count명이 담은 책';
  }

  @override
  String discoveryProofMemos(int count) {
    return '메모 $count개가 쌓인 책';
  }

  @override
  String get discoveryProofNew => '방금 올라온 책';

  @override
  String get memoTitle => '메모';

  @override
  String get memoSelectBook => '책 선택';

  @override
  String get memoAnsweringLyra => 'Lyra의 물음에 답하는 중';

  @override
  String get memoContentHint => '오늘 읽은 문장, 그 문장이 남긴 생각을 적어보세요';

  @override
  String get memoPageHint => '쪽';

  @override
  String get memoVisibilityPublic => '공개';

  @override
  String get memoVisibilityPrivateOnlyMe => '나만 보기';

  @override
  String get memoNoBooksYet => '먼저 책을 담아주세요';

  @override
  String get memoPickBookTitle => '어떤 책의 메모인가요';

  @override
  String get memoImagePickTitle => '이미지 선택';

  @override
  String get memoImageFromGallery => '갤러리에서 선택';

  @override
  String get memoImageFromCamera => '카메라로 촬영';

  @override
  String get memoSelectBookRequired => '책을 선택해주세요';

  @override
  String get memoContentRequired => '메모 내용을 입력해주세요';

  @override
  String get memoImageUploadFailed => '이미지 업로드에 실패했습니다';

  @override
  String get memoSaved => '메모가 저장되었습니다';

  @override
  String get memoEditTitle => '메모 편집';

  @override
  String get memoDelete => '삭제';

  @override
  String get memoBookFallback => '책';

  @override
  String get memoEditHint => '메모를 입력하세요';

  @override
  String get memoUpdated => '메모가 수정되었습니다';

  @override
  String get memoDeleteTitle => '메모 삭제';

  @override
  String get memoDeleteConfirm => '이 메모를 삭제하시겠습니까?';

  @override
  String get memoDeleteAsk => '이 메모를 삭제할까';

  @override
  String get memoUnsavedTitle => '변경사항이 있습니다';

  @override
  String get memoUnsavedBody => '저장하지 않고 나가시겠습니까?';

  @override
  String get memoLeave => '나가기';

  @override
  String get memoLoadFailed => '메모를 불러오지 못했어요';

  @override
  String get memoSaveBookTitle => '책 담기';

  @override
  String get memoSaveBookConfirm => '담기';

  @override
  String get memoRestrictedBody => '지금은 볼 수 없는 메모야. 이 책을 담고 책 상세로 가볼까';

  @override
  String get memoSaveBookBody => '이 책을 담아야 상세를 볼 수 있어. 담을까';

  @override
  String get memoAuthorFallback => '밀키웨이';

  @override
  String get memoMineTag => '내 메모';

  @override
  String get memoEditedTag => '수정됨';

  @override
  String memoDateMonthDay(int month, int day) {
    return '$month월 $day일';
  }

  @override
  String get memoLyraQuestionLabel => 'Lyra의 물음';

  @override
  String get memoPublicLabel => '공개 메모';

  @override
  String get memoPrivateLabel => '나만 보는 메모';

  @override
  String get memoEditAction => '수정하기';

  @override
  String get memoDeleteAction => '삭제하기';

  @override
  String get memoConstellationTooltip => '별자리';

  @override
  String get memoSegmentMine => '내 메모';

  @override
  String get memoFeedLoadFailed => '피드를 불러오지 못했어요';

  @override
  String get memoEmptyMine => '아직 남긴 메모가 없어요';

  @override
  String get memoEmptyPublic => '아직 공개된 메모가 없어요';

  @override
  String get memoTimeJustNow => '방금';

  @override
  String memoTimeMinutesAgo(int count) {
    return '$count분 전';
  }

  @override
  String memoTimeHoursAgo(int count) {
    return '$count시간 전';
  }

  @override
  String memoTimeDaysAgo(int count) {
    return '$count일 전';
  }

  @override
  String get memoLoadErrorTitle => '메모를 불러올 수 없습니다';

  @override
  String get memoEmptyTitle => '아직 메모가 없습니다';

  @override
  String get memoEmptyBody => '첫 번째 메모를 작성해보세요';

  @override
  String get memoFilterWrittenByMe => '내가 쓴';

  @override
  String get memoFilterAllMemos => '모든 메모';

  @override
  String get memoFilterPrivate => '비공개';

  @override
  String get memoErrorCameraPermission => '카메라 접근 권한이 필요합니다';

  @override
  String get memoErrorCameraUnavailable => '카메라를 사용할 수 없습니다';

  @override
  String get memoErrorPhotoPermission => '사진 접근 권한이 필요합니다';

  @override
  String get memoErrorImagePick => '이미지 선택 중 오류가 발생했습니다';

  @override
  String get memoErrorNetwork => '네트워크 연결을 확인해주세요';

  @override
  String get memoErrorPermission => '접근 권한이 필요합니다';

  @override
  String get memoErrorSave => '저장 중 오류가 발생했습니다';

  @override
  String get memoErrorGeneric => '오류가 발생했습니다';

  @override
  String get memoImageLabel => '이미지 (선택사항)';

  @override
  String get memoImageHint => '저장하고 싶은 페이지를 등록해주세요';

  @override
  String get memoContentLabel => '메모 내용';

  @override
  String memoContentHintMax(int max) {
    return '읽은 내용이나 생각을 적어주세요 (최대 $max자)';
  }

  @override
  String get memoPageLabel => '페이지 숫자 (선택사항)';

  @override
  String get memoPageHintExample => '예시: 123 (숫자만 입력 가능해요)';

  @override
  String get memoVisibilityLabel => '메모 공개 선택';

  @override
  String get memoVisibilityDescription => '이 스위치를 켜면 메모가 공개돼요';

  @override
  String get memoAddBookAction => '책 등록하기';

  @override
  String get memoAddMemoAction => '메모 작성하기';

  @override
  String get reportAction => '신고하기';

  @override
  String get reportGuide => '부적절한 콘텐츠를 신고해주세요. 신고된 메모는 검토 후 처리됩니다.';

  @override
  String get reportReasonTitle => '신고 사유';

  @override
  String get reportDescriptionLabel => '추가 설명 (선택사항)';

  @override
  String get reportDescriptionHint => '신고 사유를 자세히 설명해주세요';

  @override
  String get reportSubmitted => '신고가 접수되었습니다. 검토 후 처리됩니다.';

  @override
  String get reportAlreadyReported => '이미 신고한 메모입니다.';

  @override
  String get reportFailed => '신고 처리 중 오류가 발생했습니다. 잠시 후 다시 시도해주세요.';

  @override
  String get reportReasonSpam => '스팸/광고';

  @override
  String get reportReasonInappropriate => '부적절한 콘텐츠';

  @override
  String get reportReasonHarassment => '혐오 발언/괴롭힘';

  @override
  String get reportReasonSexual => '성적 콘텐츠';

  @override
  String get reportReasonViolence => '폭력적 콘텐츠';

  @override
  String get reportReasonCopyright => '저작권 침해';

  @override
  String get reportReasonOther => '기타';

  @override
  String get profileLoadError => '불러오지 못했어요';

  @override
  String get profileLoginRequired => '로그인이 필요해요';

  @override
  String get profileEdit => '프로필 편집';

  @override
  String get profileMyRecord => '내 기록';

  @override
  String get profileSavedBooks => '담은 책';

  @override
  String get profileCompletedBooks => '완독한 책';

  @override
  String get profileMenuNotification => '알림';

  @override
  String get profileMenuFeedback => '의견 보내기';

  @override
  String get profileMenuTerms => '이용약관';

  @override
  String get profileMenuVersion => '앱 버전';

  @override
  String get profileNotificationSaveFailed => '설정을 저장하지 못했어요';

  @override
  String get profileNotificationPermissionTitle => '알림 권한 필요';

  @override
  String get profileNotificationPermissionBody =>
      '알림을 받으려면 시스템 설정에서 알림 권한을 허용해주세요';

  @override
  String get profileOpenSettings => '설정 열기';

  @override
  String get profileFeedbackTitle => '의견 남기기';

  @override
  String get profileFeedbackHint => '의견을 입력해주세요';

  @override
  String get profileFeedbackSend => '보내기';

  @override
  String get profileFeedbackThanks => '의견 보내주셔서 감사해요';

  @override
  String get profileFeedbackError => '의견을 보내는 중 문제가 생겼어요. 잠시 후 다시 시도해요';

  @override
  String get profileEditTitle => '프로필 수정';

  @override
  String get profileEditChangePhoto => '프로필 사진 변경';

  @override
  String get profileEditRemovePhoto => '사진 제거';

  @override
  String get profileEditPickImage => '이미지 선택';

  @override
  String get profileEditFromGallery => '갤러리에서 선택';

  @override
  String get profileEditFromCamera => '카메라로 촬영';

  @override
  String profileEditPickImageError(String error) {
    return '이미지 선택 중 오류가 발생했어요: $error';
  }

  @override
  String get profileEditNicknameLabel => '닉네임';

  @override
  String get profileEditNicknameHint => '닉네임을 입력하세요';

  @override
  String get profileEditNicknameRule => '2 - 20자, 특수문자 사용 불가';

  @override
  String get profileEditChecking => '확인 중...';

  @override
  String get profileEditNicknameTooShort => '닉네임은 최소 2자 이상이어야 합니다';

  @override
  String get profileEditNicknameTooLong => '닉네임은 최대 20자까지 입력 가능합니다';

  @override
  String get profileEditNicknameNoSpecial => '특수문자는 사용할 수 없습니다';

  @override
  String get profileEditNicknameTaken => '이미 사용 중인 닉네임입니다';

  @override
  String get profileEditNicknameCheckError => '닉네임 확인 중 오류가 발생했습니다';

  @override
  String get profileEditNicknameRequired => '닉네임을 입력해주세요';

  @override
  String get profileEditNicknameChecking => '닉네임 확인 중입니다. 잠시만 기다려주세요';

  @override
  String get profileEditEmailLabel => '이메일';

  @override
  String get profileEditNoEmail => '이메일 없음';

  @override
  String get profileEditEmailFixed => '이메일은 변경할 수 없습니다';

  @override
  String get profileEditNoChanges => '변경된 내용이 없습니다';

  @override
  String get profileEditImageUploadFailed => '프로필 이미지 업로드에 실패했습니다';

  @override
  String get profileEditSaved => '프로필이 수정되었습니다';

  @override
  String get profileEditLogout => '로그아웃';

  @override
  String get profileEditLogoutConfirm => '정말 로그아웃 하시겠습니까?';

  @override
  String get profileEditDeleteAccount => '계정 삭제';

  @override
  String get profileEditDelete => '삭제';

  @override
  String get profileEditDeleteAccountMessage =>
      '지금 삭제하면 30일 뒤에 책과 메모가 완전히 지워져. 그 전에 다시 로그인하면 그대로 복구돼. 계속할까';

  @override
  String get rankingCardTitle => '이번 주 나의 기록';

  @override
  String rankingTopPercent(int percent) {
    return '상위 $percent%';
  }

  @override
  String rankingDeltaUp(int count) {
    return '지난주보다 $count개 늘었어';
  }

  @override
  String rankingDeltaDown(int count) {
    return '지난주보다 $count개 줄었어';
  }

  @override
  String get rankingDeltaSame => '지난주와 같아';

  @override
  String get rankingEmptyTitle => '이번 주 첫 기록을 남겨봐';

  @override
  String rankingLastWeek(int count) {
    return '지난주엔 $count개 남겼어';
  }

  @override
  String rankingThisWeekCount(int count) {
    return '이번 주 $count개';
  }

  @override
  String rankingStreakDays(int days) {
    return '$days일 연속 읽는 중';
  }

  @override
  String get errCameraPermission => '카메라 접근 권한이 필요합니다';

  @override
  String get errCameraUnavailable => '카메라를 사용할 수 없습니다';

  @override
  String get errPhotoPermission => '사진 접근 권한이 필요합니다';

  @override
  String get errGeneric => '작업 중 오류가 발생했습니다';

  @override
  String get errNetwork => '네트워크 연결을 확인해주세요';

  @override
  String get errPermission => '접근 권한이 필요합니다';

  @override
  String get errUploadFailed => '업로드에 실패했습니다';

  @override
  String get errCreateFailed => '등록에 실패했습니다';

  @override
  String get errUpdateFailed => '수정에 실패했습니다';

  @override
  String get errDeleteFailed => '삭제에 실패했습니다';

  @override
  String get errSaveFailed => '저장에 실패했습니다';

  @override
  String get errAuthRequired => '인증이 필요합니다';

  @override
  String get errServer => '서버 오류가 발생했습니다';
}
