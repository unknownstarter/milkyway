// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppL10nJa extends AppL10n {
  AppL10nJa([String locale = 'ja']) : super(locale);

  @override
  String get appName => 'milkyway';

  @override
  String get commonSave => '保存';

  @override
  String get commonCancel => 'キャンセル';

  @override
  String get commonNext => '次へ';

  @override
  String get commonClose => '閉じる';

  @override
  String get commonConfirm => 'OK';

  @override
  String get commonRetry => '再試行';

  @override
  String get settingsLanguage => '言語';

  @override
  String get languageSystem => '端末の設定';

  @override
  String get languageKorean => '한국어';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageJapanese => '日本語';

  @override
  String get languageChinese => '中文';

  @override
  String get unitBooks => '冊';

  @override
  String get unitCount => '件';

  @override
  String get unitDays => '日';

  @override
  String get statBooksRead => '読んだ本';

  @override
  String get statMemosLeft => '残したメモ';

  @override
  String get statTopPercent => '上位';

  @override
  String get statStreak => '連続';

  @override
  String get constellationTitle => '星座';

  @override
  String get constellationLoadError => '星座を読み込めませんでした';

  @override
  String get constellationEmptyTitle => 'まだつながった星がありません';

  @override
  String get constellationEmptyBody => 'メモが積もると互いにつながって夜空になります';

  @override
  String constellationConnected(int count) {
    return 'つながった瞬間$count';
  }

  @override
  String get constellationWhenPast => 'あのとき';

  @override
  String get constellationWhenNow => 'いま';

  @override
  String get constellationRelExtends => '広がり';

  @override
  String get constellationRelReverses => '変化';

  @override
  String get constellationRelEcho => '再び浮かぶ';

  @override
  String get constellationRelSimilar => '似ている';

  @override
  String get constellationRelDefault => 'つながり';

  @override
  String get constellationRevealTitle => '線が一本つながった';

  @override
  String get constellationViewInConstellation => '星座で見る';

  @override
  String get lyraQuestionLabel => 'Lyraの問い';

  @override
  String get lyraAnswerCta => 'この問いにメモを残す';

  @override
  String get orbTierNebulaSmall => '小さな星雲';

  @override
  String get orbTierStarCluster => '星の群れ';

  @override
  String get orbTierConstellation => '星座';

  @override
  String get orbTierCluster => '星団';

  @override
  String get orbTierGalaxy => '銀河';

  @override
  String get orbTierSuperGalaxy => '大銀河';

  @override
  String get orbMyUniverseTitle => 'わたしの宇宙';

  @override
  String get orbNowPrefix => 'いまは ';

  @override
  String orbTierBadge(String name) {
    return '$nameステージ';
  }

  @override
  String orbToNextTier(String next) {
    return '次の$nextまであと';
  }

  @override
  String get orbDeepestReached => 'いちばん深い宇宙に到達';

  @override
  String get orbShareLinkCopied => '共有リンクをコピーしました';

  @override
  String get orbShareError => '共有の準備中に問題が起きました。しばらくしてからもう一度お試しください';

  @override
  String get orbGateBannerTitle => 'オーブを作ってみよう';

  @override
  String orbGateBannerBody(int count) {
    return 'あとメモ$count件で銀河ができるよ';
  }

  @override
  String orbGateSheetTitle(int count) {
    return 'オーブまであと$count件';
  }

  @override
  String orbGateSheetBody(int count) {
    return 'メモをあと$count件残すと\n自分だけの銀河オーブができるよ';
  }

  @override
  String get orbGateWriteCta => 'いまメモを書く';

  @override
  String get shareCardDefaultNick => 'わたし';

  @override
  String shareCardOwnerUniverse(String nick) {
    return '$nickの宇宙';
  }

  @override
  String get shareCardTagline => 'きみの宇宙はどんな形だろう';

  @override
  String get shareCardStoreHint => 'App Store / Google Play で milkyway';

  @override
  String get wrappedTitle => '銀河のふりかえり';

  @override
  String wrappedHeroLead(String month) {
    return '$month、きみが';
  }

  @override
  String get wrappedHeroAccent => '立ちどまった瞬間';

  @override
  String wrappedStarsLeft(int count) {
    return 'その場所に残った$count個の星';
  }

  @override
  String get wrappedStatSentences => '立ちどまった文';

  @override
  String get wrappedStatReadDays => '読んだ日';

  @override
  String get wrappedTopBookLabel => 'いちばん長くとどまった本';

  @override
  String get wrappedQuoteLabel => 'その月の一文';

  @override
  String wrappedQuoteSource(String title) {
    return '$titleより';
  }

  @override
  String get wrappedShareCta => 'ふりかえりを共有';

  @override
  String get wrappedEmptyTitle => '今月のふりかえりはまだ準備中です';

  @override
  String get wrappedEmptyBody => 'メモを残すとその場所に星が積もります';

  @override
  String get wrappedLoadErrorTitle => 'ふりかえりを読み込めませんでした';

  @override
  String get wrappedLoadErrorBody => 'しばらくしてからもう一度お試しください';

  @override
  String get wrappedShareLinkCopied => '共有リンクをコピーしました';

  @override
  String get wrappedShareError => '共有の準備中に問題が起きました。しばらくしてからもう一度お試しください';

  @override
  String get commonShare => '共有';

  @override
  String get orbLoadErrorTitle => '宇宙を読み込めませんでした';

  @override
  String wrappedEntryTitle(String month) {
    return '$monthのふりかえり';
  }

  @override
  String wrappedEntryBody(int count) {
    return 'その場所に残った$count個の星';
  }

  @override
  String get authSignInApple => 'Appleではじめる';

  @override
  String get authSignInGoogle => 'Googleではじめる';

  @override
  String get authSignInFailed => 'ログインに失敗しました。もう一度お試しください';

  @override
  String get authNotificationPermissionTitle => '通知の許可';

  @override
  String get authNotificationPermissionBody => '読んでいる本に新しいメモがついたらお知らせします';

  @override
  String get authNotificationPermissionLater => 'あとで';

  @override
  String get authNotificationPermissionAllow => '許可';

  @override
  String get splashUpdateTitle => 'アップデートが必要';

  @override
  String get splashUpdateBody => '新しいバージョンがあります。\nアップデートしてください';

  @override
  String get splashUpdateAction => 'アップデート';

  @override
  String get onboardingSkip => 'スキップ';

  @override
  String get onboardingNicknameTitle => 'ニックネーム設定';

  @override
  String get onboardingNicknameHeading => 'ニックネームを決めましょう';

  @override
  String get onboardingNicknameSubtitle => 'milkywayの他のユーザーに見える名前です';

  @override
  String get onboardingNicknameLabel => 'ニックネーム';

  @override
  String get onboardingNicknameHint => 'ニックネームを入力';

  @override
  String get onboardingNicknameChecking => '確認中...';

  @override
  String get onboardingNicknameHelp => '2 - 20文字、記号は使えません';

  @override
  String get onboardingNicknameErrorTooShort => 'ニックネームは2文字以上で入力してください';

  @override
  String get onboardingNicknameErrorTooLong => 'ニックネームは20文字以内で入力してください';

  @override
  String get onboardingNicknameErrorSpecialChars => '記号は使えません';

  @override
  String get onboardingNicknameErrorTaken => 'すでに使われているニックネームです';

  @override
  String get onboardingNicknameErrorCheckFailed => 'ニックネームの確認中にエラーが発生しました';

  @override
  String onboardingNicknameSaveError(String error) {
    return 'ニックネームを保存できませんでした: $error';
  }

  @override
  String get onboardingProfileImageTitle => 'プロフィール写真';

  @override
  String get onboardingProfileImageHeading => 'プロフィール写真を選びましょう';

  @override
  String get onboardingProfileImageSubtitle => 'あとでいつでも変えられます';

  @override
  String get onboardingProfileImageDescription => '登録した写真は\n残したメモと一緒に表示されます';

  @override
  String get onboardingProfileImageNote => '公開したメモだけが表示されます';

  @override
  String get onboardingGenreTitle => '好み';

  @override
  String get onboardingGenreHeading => 'どんな本が\n好きですか';

  @override
  String get onboardingGenreSubtitle => '好みが分かると最初の一冊を選びやすくなります\n1つ以上選んでください';

  @override
  String onboardingGenreNextCount(int count) {
    return '次へ($count)';
  }

  @override
  String get onboardingGenreSelectAtLeastOne => '1つ以上選んでください';

  @override
  String get onboardingGenreNovel => '小説';

  @override
  String get onboardingGenrePoetry => '詩';

  @override
  String get onboardingGenreEssay => 'エッセイ';

  @override
  String get onboardingGenreHumanities => '人文';

  @override
  String get onboardingGenrePhilosophy => '哲学';

  @override
  String get onboardingGenreScience => '科学';

  @override
  String get onboardingGenreSciFi => 'SF';

  @override
  String get onboardingGenreHistory => '歴史';

  @override
  String get onboardingGenreArt => '芸術';

  @override
  String get onboardingGenrePsychology => '心理';

  @override
  String get onboardingGenreBusiness => 'ビジネス';

  @override
  String get onboardingGenreSelfHelp => '自己啓発';

  @override
  String get onboardingBookIntroTitle => 'はじめる';

  @override
  String get onboardingBookIntroDescription =>
      '本を読みながら\n浮かんだひらめきを\nメモに残しましょう ✨';

  @override
  String get onboardingBookIntroStart => '本を探してはじめる';

  @override
  String get onboardingBookIntroSkip => 'あとでする';

  @override
  String get bookStatusWantToRead => '読みたい';

  @override
  String get bookStatusReading => '読書中';

  @override
  String get bookStatusCompleted => '読了';

  @override
  String get bookFilterAll => 'すべて';

  @override
  String get bookShelfLoadError => '本を読み込めませんでした';

  @override
  String get bookShelfEmpty => '新しい本を追加してみて';

  @override
  String get bookDetailTitle => '本の詳細';

  @override
  String get bookActionDelete => '削除';

  @override
  String get bookDescriptionTitle => '本の紹介';

  @override
  String get bookShowMore => 'もっと見る';

  @override
  String get bookMemosTitle => 'この本のメモ';

  @override
  String get bookMemoSegmentTogether => 'みんな';

  @override
  String get bookMemoSegmentMine => '自分';

  @override
  String get bookMemosLoadError => 'メモを読み込めませんでした';

  @override
  String get bookMemosEmptyPublic => '公開されたメモはまだありません';

  @override
  String get bookMemosEmptyMine => 'まだメモがありません';

  @override
  String get bookMemoDefaultAuthor => 'milkyway';

  @override
  String get bookTimeJustNow => 'たった今';

  @override
  String bookTimeMinutesAgo(int count) {
    return '$count分前';
  }

  @override
  String bookTimeHoursAgo(int count) {
    return '$count時間前';
  }

  @override
  String bookTimeDaysAgo(int count) {
    return '$count日前';
  }

  @override
  String get bookWriteMemoCta => 'メモする';

  @override
  String get bookDetailLoadError => '本の情報を読み込めませんでした';

  @override
  String bookStatusChanged(String status) {
    return '$statusに変更しました';
  }

  @override
  String get bookDeleteTitle => '本を削除';

  @override
  String get bookDeleteBody =>
      'この本を削除すると、その本のメモもすべて削除され、元に戻せません。\n\n本当に削除しますか？';

  @override
  String get bookSearchTitle => '本を検索';

  @override
  String get bookSearchHint => 'タイトル / 著者 / ISBNで検索';

  @override
  String get bookSearchError => '検索中にエラーが発生しました';

  @override
  String get bookSearchEmptyTitle => '検索結果がありません';

  @override
  String get bookSearchEmptyBody => '別のキーワードで探してみて';

  @override
  String get bookAlreadyAdded => 'すでに登録済みの本です';

  @override
  String get bookAdded => '本を登録しました';

  @override
  String get bookAddedNew => '新しい本を登録しました';

  @override
  String get bookAddFailed => '本の登録に失敗しました';

  @override
  String get bookOpStatusChange => '状態の変更';

  @override
  String get bookOpDelete => '本の削除';

  @override
  String get bookOpRegister => '本の登録';

  @override
  String get bookOpConnect => '本の連携';

  @override
  String get readingLogTodayCta => '今日読んだ';

  @override
  String get readingLoggedToday => '今日読みました';

  @override
  String get calendarTitle => '記録';

  @override
  String get calendarSegmentMemos => 'メモ';

  @override
  String get calendarSegmentRead => '読んだ';

  @override
  String get calendarEmptyMemos => 'この日のメモはありません';

  @override
  String get calendarEmptyBooks => 'この日読んだ本はありません';

  @override
  String get commentAnonymousAuthor => 'milkyway';

  @override
  String get commentMineTag => '自分';

  @override
  String get commentEdit => '編集する';

  @override
  String get commentDelete => '削除する';

  @override
  String get commentHide => 'このコメントを非表示にする';

  @override
  String get commentReport => '通報する';

  @override
  String get commentComposerLocked => '本を保存するとコメントできるよ';

  @override
  String get commentComposerEditHint => 'コメントを編集';

  @override
  String get commentComposerHint => 'コメントを残す';

  @override
  String get commentSendError => 'コメントを送信できませんでした';

  @override
  String get commentDeleteTitle => 'コメントを削除';

  @override
  String get commentDeleteMessage => 'このコメントを削除しますか？';

  @override
  String get commentDeleteConfirm => '削除';

  @override
  String get commentDeleteError => '削除できませんでした';

  @override
  String get commentHideError => '非表示にできませんでした';

  @override
  String get commentReportReasonTitle => '通報理由';

  @override
  String get commentReportSpam => 'スパム/連投';

  @override
  String get commentReportInappropriate => '不適切な内容';

  @override
  String get commentReportHarassment => '嫌がらせ/差別';

  @override
  String get commentReportSexual => '性的な内容';

  @override
  String get commentReportOther => 'その他';

  @override
  String get commentReportDone => '通報しました。このコメントはもう表示されません';

  @override
  String get commentReportError => '通報できませんでした';

  @override
  String get commentSaveBookTitle => '本を保存';

  @override
  String get commentSaveBookMessage => 'この本を保存するとコメントできるよ。保存する？';

  @override
  String get commentSaveBookConfirm => '保存';

  @override
  String get commentSaveBookError => '本を保存できませんでした';

  @override
  String get commentLoadError => 'コメントを読み込めませんでした';

  @override
  String get commentSectionTitle => 'コメント';

  @override
  String commentSectionTitleCount(int count) {
    return 'コメント$count';
  }

  @override
  String get commentEmpty => '最初のコメントを残してみて';

  @override
  String get shareLandingCta => '自分の宇宙も作れます';

  @override
  String get shareLandingCtaButton => '自分も作る';

  @override
  String get shareLandingErrorTitle => 'カードを読み込めませんでした';

  @override
  String get shareLandingErrorBody => 'リンクの期限切れか、削除されたカードかもしれません';

  @override
  String get shareLandingGoHome => 'ホームへ';

  @override
  String get commonEdited => '編集済み';

  @override
  String get commonMyMemo => '自分のメモ';

  @override
  String commonPageLabel(int page) {
    return '$pageページ';
  }

  @override
  String get commonLoadFailed => '読み込めませんでした';

  @override
  String get commonComposeHint => '今日読んだ一文を残してみて';

  @override
  String get commonTimeJustNow => 'たった今';

  @override
  String commonTimeMinutesAgo(int minutes) {
    return '$minutes分前';
  }

  @override
  String commonTimeHoursAgo(int hours) {
    return '$hours時間前';
  }

  @override
  String commonTimeDaysAgo(int days) {
    return '$days日前';
  }

  @override
  String get commonNavHome => 'ホーム';

  @override
  String get commonNavBooks => '本';

  @override
  String get commonNavMemos => 'メモ';

  @override
  String get commonNavProfile => 'プロフィール';

  @override
  String get commonEmptyBookTitle => '新しい本を選んで 👇';

  @override
  String get commonEmptyBookCta => 'どんな本を読みたい？ 🤔';

  @override
  String get homeSaveBookTitle => '本を保存';

  @override
  String get homeSaveBookMessage => 'この本を本棚に入れる？';

  @override
  String get homeSaveAction => '保存';

  @override
  String get homeSaveBookError => '本を保存できませんでした';

  @override
  String get homeSectionOtherThoughts => 'ほかの星が残した思い';

  @override
  String get homeDefaultAuthor => 'milkyway';

  @override
  String get homeSectionRecentMemoBooks => '最近メモがついた本';

  @override
  String homeMemoMeta(String time) {
    return '$timeのメモ';
  }

  @override
  String get homeReadPromptTitle => '今日は何を読もう';

  @override
  String get homeReadPromptBody => '本棚から選んでみて';

  @override
  String get homeOrbTitle => '宇宙が育っている';

  @override
  String get homeOrbBody => '銀河を見て共有しよう';

  @override
  String get homeConstellationTitle => '思いがつながっている';

  @override
  String get homeConstellationBody => 'メモの星座を見てみよう';

  @override
  String get homeWeekdayMon => '月';

  @override
  String get homeWeekdayTue => '火';

  @override
  String get homeWeekdayWed => '水';

  @override
  String get homeWeekdayThu => '木';

  @override
  String get homeWeekdayFri => '金';

  @override
  String get homeWeekdaySat => '土';

  @override
  String get homeWeekdaySun => '日';

  @override
  String get homeRecordTitle => 'わたしの記録';

  @override
  String get homeViewAll => 'すべて見る';

  @override
  String get homeTimeJustNow => 'たった今';

  @override
  String homeTimeMinutesAgo(int count) {
    return '$count分前';
  }

  @override
  String homeTimeHoursAgo(int count) {
    return '$count時間前';
  }

  @override
  String homeTimeDaysAgo(int count) {
    return '$count日前';
  }

  @override
  String get homeWelcomeTitle => '気になる一冊から';

  @override
  String get homeWelcomeBody => '保存するとLyraが問いを届けるよ\n下の本ものぞいてみて';

  @override
  String get homeWelcomeCta => '本を探す';

  @override
  String get homeStatusReading => '読書中';

  @override
  String get homeSectionSavedByOthers => 'ほかの人が保存した本';

  @override
  String get homeAddBook => '本を登録';

  @override
  String get homeAddMemo => 'メモを書く';

  @override
  String get discoveryTitle => '本を保存';

  @override
  String get discoverySkip => 'あとで';

  @override
  String get discoveryLoadError => 'おすすめを読み込めませんでした';

  @override
  String get discoveryEmpty => 'まだおすすめがありません';

  @override
  String get discoveryHeading => 'メモが残された本';

  @override
  String get discoveryBody => '気になる本を保存してみて\nLyraが問いを届けるよ';

  @override
  String get discoverySearchCta => '見つからないなら検索';

  @override
  String discoveryStartCta(int count) {
    return '$count冊保存して始める';
  }

  @override
  String get discoverySaveError => '本を保存できませんでした';

  @override
  String discoveryProofSavers(int count) {
    return '$count人が保存';
  }

  @override
  String discoveryProofMemos(int count) {
    return 'メモ$count件';
  }

  @override
  String get discoveryProofNew => '新着';

  @override
  String get memoTitle => 'メモ';

  @override
  String get memoSelectBook => '本を選ぶ';

  @override
  String get memoAnsweringLyra => 'Lyraの問いに回答中';

  @override
  String get memoContentHint => '今日読んだ一文と、そこから残った考えを書いてみて';

  @override
  String get memoPageHint => '頁';

  @override
  String get memoVisibilityPublic => '公開';

  @override
  String get memoVisibilityPrivateOnlyMe => '自分だけ';

  @override
  String get memoNoBooksYet => '先に本を保存して';

  @override
  String get memoPickBookTitle => 'どの本のメモかな';

  @override
  String get memoImagePickTitle => '画像を選ぶ';

  @override
  String get memoImageFromGallery => 'ギャラリーから';

  @override
  String get memoImageFromCamera => 'カメラで撮影';

  @override
  String get memoSelectBookRequired => '本を選んでください';

  @override
  String get memoContentRequired => 'メモを入力してください';

  @override
  String get memoImageUploadFailed => '画像のアップロードに失敗しました';

  @override
  String get memoSaved => 'メモを保存しました';

  @override
  String get memoEditTitle => 'メモを編集';

  @override
  String get memoDelete => '削除';

  @override
  String get memoBookFallback => '本';

  @override
  String get memoEditHint => 'メモを入力';

  @override
  String get memoUpdated => 'メモを更新しました';

  @override
  String get memoDeleteTitle => 'メモを削除';

  @override
  String get memoDeleteConfirm => 'このメモを削除しますか？';

  @override
  String get memoDeleteAsk => 'このメモを削除しますか？';

  @override
  String get memoUnsavedTitle => '変更があります';

  @override
  String get memoUnsavedBody => '保存せずに出ますか？';

  @override
  String get memoLeave => '保存しない';

  @override
  String get memoLoadFailed => 'メモを読み込めませんでした';

  @override
  String get memoSaveBookTitle => '本を保存';

  @override
  String get memoSaveBookConfirm => '保存';

  @override
  String get memoRestrictedBody => '今は見られないメモだよ。この本を保存して詳細を開こうか';

  @override
  String get memoSaveBookBody => 'この本を保存すると詳細が見られるよ。保存する？';

  @override
  String get memoAuthorFallback => 'milkyway';

  @override
  String get memoMineTag => '自分';

  @override
  String get memoEditedTag => '編集済み';

  @override
  String memoDateMonthDay(int month, int day) {
    return '$month月$day日';
  }

  @override
  String get memoLyraQuestionLabel => 'Lyraの問い';

  @override
  String get memoPublicLabel => '公開メモ';

  @override
  String get memoPrivateLabel => '自分だけのメモ';

  @override
  String get memoEditAction => '編集する';

  @override
  String get memoDeleteAction => '削除する';

  @override
  String get memoConstellationTooltip => '星座';

  @override
  String get memoSegmentMine => '自分のメモ';

  @override
  String get memoFeedLoadFailed => 'フィードを読み込めませんでした';

  @override
  String get memoEmptyMine => 'まだメモがありません';

  @override
  String get memoEmptyPublic => 'まだ公開メモがありません';

  @override
  String get memoTimeJustNow => 'たった今';

  @override
  String memoTimeMinutesAgo(int count) {
    return '$count分前';
  }

  @override
  String memoTimeHoursAgo(int count) {
    return '$count時間前';
  }

  @override
  String memoTimeDaysAgo(int count) {
    return '$count日前';
  }

  @override
  String get memoLoadErrorTitle => 'メモを読み込めません';

  @override
  String get memoEmptyTitle => 'まだメモがありません';

  @override
  String get memoEmptyBody => '最初のメモを書いてみて';

  @override
  String get memoFilterWrittenByMe => '自分';

  @override
  String get memoFilterAllMemos => 'すべて';

  @override
  String get memoFilterPrivate => '非公開';

  @override
  String get memoErrorCameraPermission => 'カメラへのアクセス許可が必要です';

  @override
  String get memoErrorCameraUnavailable => 'カメラを使用できません';

  @override
  String get memoErrorPhotoPermission => '写真へのアクセス許可が必要です';

  @override
  String get memoErrorImagePick => '画像の選択中にエラーが発生しました';

  @override
  String get memoErrorNetwork => 'ネットワーク接続を確認してください';

  @override
  String get memoErrorPermission => 'アクセス許可が必要です';

  @override
  String get memoErrorSave => '保存中にエラーが発生しました';

  @override
  String get memoErrorGeneric => 'エラーが発生しました';

  @override
  String get memoImageLabel => '画像 (任意)';

  @override
  String get memoImageHint => '残したいページを選んで';

  @override
  String get memoContentLabel => 'メモ内容';

  @override
  String memoContentHintMax(int max) {
    return '読んだ内容や考えを書いて (最大$max文字)';
  }

  @override
  String get memoPageLabel => 'ページ番号 (任意)';

  @override
  String get memoPageHintExample => '例: 123 (数字のみ)';

  @override
  String get memoVisibilityLabel => 'メモの公開設定';

  @override
  String get memoVisibilityDescription => 'オンにするとメモが公開されます';

  @override
  String get memoAddBookAction => '本を登録';

  @override
  String get memoAddMemoAction => 'メモを書く';

  @override
  String get reportAction => '通報する';

  @override
  String get reportGuide => '不適切なコンテンツを通報してください。通報されたメモは確認後に対応します。';

  @override
  String get reportReasonTitle => '通報理由';

  @override
  String get reportDescriptionLabel => '補足 (任意)';

  @override
  String get reportDescriptionHint => '詳しく教えてください';

  @override
  String get reportSubmitted => '通報を受け付けました。確認後に対応します';

  @override
  String get reportAlreadyReported => 'すでに通報したメモです';

  @override
  String get reportFailed => '通報中にエラーが発生しました。しばらくしてからもう一度お試しください';

  @override
  String get reportReasonSpam => 'スパム/広告';

  @override
  String get reportReasonInappropriate => '不適切なコンテンツ';

  @override
  String get reportReasonHarassment => 'ヘイト/嫌がらせ';

  @override
  String get reportReasonSexual => '性的なコンテンツ';

  @override
  String get reportReasonViolence => '暴力的なコンテンツ';

  @override
  String get reportReasonCopyright => '著作権侵害';

  @override
  String get reportReasonOther => 'その他';

  @override
  String get profileLoadError => '読み込めませんでした';

  @override
  String get profileLoginRequired => 'ログインが必要です';

  @override
  String get profileEdit => 'プロフィール編集';

  @override
  String get profileMyRecord => 'わたしの記録';

  @override
  String get profileSavedBooks => '保存した本';

  @override
  String get profileCompletedBooks => '読了した本';

  @override
  String get profileMenuNotification => '通知';

  @override
  String get profileMenuFeedback => 'ご意見を送る';

  @override
  String get profileMenuTerms => '利用規約';

  @override
  String get profileMenuVersion => 'アプリバージョン';

  @override
  String get profileNotificationSaveFailed => '設定を保存できませんでした';

  @override
  String get profileNotificationPermissionTitle => '通知の許可が必要';

  @override
  String get profileNotificationPermissionBody => '通知を受け取るにはシステム設定で通知を許可してください';

  @override
  String get profileOpenSettings => '設定を開く';

  @override
  String get profileFeedbackTitle => 'ご意見を書く';

  @override
  String get profileFeedbackHint => 'ご意見を入力してください';

  @override
  String get profileFeedbackSend => '送信';

  @override
  String get profileFeedbackThanks => 'ご意見ありがとうございます';

  @override
  String get profileFeedbackError => '送信中に問題が起きました。しばらくしてからもう一度お試しください';

  @override
  String get profileEditTitle => 'プロフィール編集';

  @override
  String get profileEditChangePhoto => '写真を変更';

  @override
  String get profileEditRemovePhoto => '写真を削除';

  @override
  String get profileEditPickImage => '画像を選択';

  @override
  String get profileEditFromGallery => 'ギャラリーから選ぶ';

  @override
  String get profileEditFromCamera => 'カメラで撮る';

  @override
  String profileEditPickImageError(String error) {
    return '画像の選択中にエラーが発生しました: $error';
  }

  @override
  String get profileEditNicknameLabel => 'ニックネーム';

  @override
  String get profileEditNicknameHint => 'ニックネームを入力';

  @override
  String get profileEditNicknameRule => '2 - 20文字、記号は使えません';

  @override
  String get profileEditChecking => '確認中...';

  @override
  String get profileEditNicknameTooShort => 'ニックネームは2文字以上で入力してください';

  @override
  String get profileEditNicknameTooLong => 'ニックネームは20文字以内で入力してください';

  @override
  String get profileEditNicknameNoSpecial => '記号は使えません';

  @override
  String get profileEditNicknameTaken => 'すでに使われているニックネームです';

  @override
  String get profileEditNicknameCheckError => 'ニックネームの確認中にエラーが発生しました';

  @override
  String get profileEditNicknameRequired => 'ニックネームを入力してください';

  @override
  String get profileEditNicknameChecking => 'ニックネームを確認中です。少しお待ちください';

  @override
  String get profileEditEmailLabel => 'メール';

  @override
  String get profileEditNoEmail => 'メールなし';

  @override
  String get profileEditEmailFixed => 'メールは変更できません';

  @override
  String get profileEditNoChanges => '変更はありません';

  @override
  String get profileEditImageUploadFailed => 'プロフィール写真をアップロードできませんでした';

  @override
  String get profileEditSaved => 'プロフィールを更新しました';

  @override
  String get profileEditLogout => 'ログアウト';

  @override
  String get profileEditLogoutConfirm => 'ログアウトしますか？';

  @override
  String get profileEditDeleteAccount => 'アカウント削除';

  @override
  String get profileEditDelete => '削除';

  @override
  String get profileEditDeleteAccountMessage =>
      '今削除すると30日後に本とメモが完全に消えます。それまでに再ログインすればそのまま戻ります。続けますか';

  @override
  String get rankingCardTitle => '今週の記録';

  @override
  String rankingTopPercent(int percent) {
    return '上位$percent%';
  }

  @override
  String rankingDeltaUp(int count) {
    return '先週より$count件多い';
  }

  @override
  String rankingDeltaDown(int count) {
    return '先週より$count件少ない';
  }

  @override
  String get rankingDeltaSame => '先週と同じ';

  @override
  String get rankingEmptyTitle => '今週の最初の記録を残そう';

  @override
  String rankingLastWeek(int count) {
    return '先週は$count件だった';
  }

  @override
  String rankingThisWeekCount(int count) {
    return '今週$count件';
  }

  @override
  String rankingStreakDays(int days) {
    return '$days日連続';
  }

  @override
  String get errCameraPermission => 'カメラへのアクセス許可が必要です';

  @override
  String get errCameraUnavailable => 'カメラを使用できません';

  @override
  String get errPhotoPermission => '写真へのアクセス許可が必要です';

  @override
  String get errGeneric => '問題が発生しました';

  @override
  String get errNetwork => 'ネットワーク接続を確認してください';

  @override
  String get errPermission => 'アクセス許可が必要です';

  @override
  String get errUploadFailed => 'アップロードに失敗しました';

  @override
  String get errCreateFailed => '登録に失敗しました';

  @override
  String get errUpdateFailed => '更新に失敗しました';

  @override
  String get errDeleteFailed => '削除に失敗しました';

  @override
  String get errSaveFailed => '保存に失敗しました';

  @override
  String get errAuthRequired => '認証が必要です';

  @override
  String get errServer => 'サーバーエラーが発生しました';
}
