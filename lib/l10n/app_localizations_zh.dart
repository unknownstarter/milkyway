// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppL10nZh extends AppL10n {
  AppL10nZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => 'milkyway';

  @override
  String get commonSave => '保存';

  @override
  String get commonCancel => '取消';

  @override
  String get commonNext => '下一步';

  @override
  String get commonClose => '关闭';

  @override
  String get commonConfirm => '确定';

  @override
  String get commonRetry => '重试';

  @override
  String get settingsLanguage => '语言';

  @override
  String get languageSystem => '跟随系统';

  @override
  String get languageKorean => '한국어';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageJapanese => '日本語';

  @override
  String get languageChinese => '中文';

  @override
  String get unitBooks => '本';

  @override
  String get unitCount => '条';

  @override
  String get unitDays => '天';

  @override
  String get statBooksRead => '读过的书';

  @override
  String get statMemosLeft => '写的笔记';

  @override
  String get statTopPercent => '排名';

  @override
  String get statStreak => '连续';

  @override
  String get constellationTitle => '星座';

  @override
  String get constellationLoadError => '星座加载失败';

  @override
  String get constellationEmptyTitle => '还没有连起来的星星';

  @override
  String get constellationEmptyBody => '笔记攒多了就会彼此相连，连成一片夜空';

  @override
  String constellationConnected(int count) {
    return '相连的瞬间 $count';
  }

  @override
  String get constellationWhenPast => '那时';

  @override
  String get constellationWhenNow => '现在';

  @override
  String get constellationRelExtends => '延伸';

  @override
  String get constellationRelReverses => '转变';

  @override
  String get constellationRelEcho => '再次浮现';

  @override
  String get constellationRelSimilar => '相似';

  @override
  String get constellationRelDefault => '关联';

  @override
  String get constellationRevealTitle => '连成了一条线';

  @override
  String get constellationViewInConstellation => '在星座中查看';

  @override
  String get lyraQuestionLabel => 'Lyra 的提问';

  @override
  String get lyraAnswerCta => '为这个问题写笔记';

  @override
  String get orbTierNebulaSmall => '小星云';

  @override
  String get orbTierStarCluster => '星群';

  @override
  String get orbTierConstellation => '星座';

  @override
  String get orbTierCluster => '星团';

  @override
  String get orbTierGalaxy => '银河';

  @override
  String get orbTierSuperGalaxy => '大银河';

  @override
  String get orbMyUniverseTitle => '我的宇宙';

  @override
  String get orbNowPrefix => '现在是';

  @override
  String orbTierBadge(String name) {
    return '$name阶段';
  }

  @override
  String orbToNextTier(String next) {
    return '距离$next还差 ';
  }

  @override
  String get orbDeepestReached => '已抵达最深的宇宙';

  @override
  String get orbShareLinkCopied => '分享链接已复制';

  @override
  String get orbShareError => '分享出了点问题，稍后再试';

  @override
  String get orbGateBannerTitle => '你的银河还差一点';

  @override
  String orbGateBannerBody(int count) {
    return '再写 $count 条，你的银河就出现';
  }

  @override
  String orbGateSheetTitle(int count) {
    return '还差 $count 条笔记';
  }

  @override
  String orbGateSheetBody(int count) {
    return '再写 $count 条笔记\n你的银河就成形了';
  }

  @override
  String get orbGateWriteCta => '现在写笔记';

  @override
  String get shareCardDefaultNick => '我';

  @override
  String shareCardOwnerUniverse(String nick) {
    return '$nick 的宇宙';
  }

  @override
  String get shareCardTagline => '你的宇宙是什么形状呢';

  @override
  String get shareCardStoreHint => 'App Store / Google Play 搜索 milkyway';

  @override
  String get wrappedTitle => '银河回顾';

  @override
  String wrappedHeroLead(String month) {
    return '$month，你';
  }

  @override
  String get wrappedHeroAccent => '停下的瞬间';

  @override
  String wrappedStarsLeft(int count) {
    return '留在那里的 $count 颗星';
  }

  @override
  String get wrappedStatSentences => '停留的句子';

  @override
  String get wrappedStatReadDays => '阅读天数';

  @override
  String get wrappedTopBookLabel => '停留最久的书';

  @override
  String get wrappedQuoteLabel => '当月的句子';

  @override
  String wrappedQuoteSource(String title) {
    return '出自 $title';
  }

  @override
  String get wrappedShareCta => '分享回顾';

  @override
  String get wrappedEmptyTitle => '本月的回顾还在准备中';

  @override
  String get wrappedEmptyBody => '写下笔记，星星就会一颗颗攒起来';

  @override
  String get wrappedLoadErrorTitle => '回顾加载失败';

  @override
  String get wrappedLoadErrorBody => '稍后再试';

  @override
  String get wrappedShareLinkCopied => '分享链接已复制';

  @override
  String get wrappedShareError => '分享出了点问题，稍后再试';

  @override
  String get commonShare => '分享';

  @override
  String get orbLoadErrorTitle => '宇宙加载失败';

  @override
  String wrappedEntryTitle(String month) {
    return '$month 银河回顾';
  }

  @override
  String wrappedEntryBody(int count) {
    return '收集了留在那里的 $count 颗星';
  }

  @override
  String get authSignInApple => '通过 Apple 继续';

  @override
  String get authSignInGoogle => '通过 Google 继续';

  @override
  String get authSignInFailed => '登录失败，请重试';

  @override
  String get authNotificationPermissionTitle => '通知权限';

  @override
  String get authNotificationPermissionBody => '你在读的书有新笔记时，会通知你';

  @override
  String get authNotificationPermissionLater => '稍后';

  @override
  String get authNotificationPermissionAllow => '允许';

  @override
  String get splashUpdateTitle => '需要更新';

  @override
  String get splashUpdateBody => '有新版本了\n更新后继续使用';

  @override
  String get splashUpdateAction => '更新';

  @override
  String get onboardingSkip => '跳过';

  @override
  String get onboardingNicknameTitle => '设置昵称';

  @override
  String get onboardingNicknameHeading => '设置一个昵称';

  @override
  String get onboardingNicknameSubtitle => '其他 milkyway 用户会看到这个名字';

  @override
  String get onboardingNicknameLabel => '昵称';

  @override
  String get onboardingNicknameHint => '请输入昵称';

  @override
  String get onboardingNicknameChecking => '检查中...';

  @override
  String get onboardingNicknameHelp => '2 - 20 个字符，不能用特殊字符';

  @override
  String get onboardingNicknameErrorTooShort => '至少需要 2 个字符';

  @override
  String get onboardingNicknameErrorTooLong => '最多 20 个字符';

  @override
  String get onboardingNicknameErrorSpecialChars => '不能使用特殊字符';

  @override
  String get onboardingNicknameErrorTaken => '该昵称已被使用';

  @override
  String get onboardingNicknameErrorCheckFailed => '检查昵称时出错';

  @override
  String onboardingNicknameSaveError(String error) {
    return '昵称保存失败：$error';
  }

  @override
  String get onboardingProfileImageTitle => '头像';

  @override
  String get onboardingProfileImageHeading => '设置头像';

  @override
  String get onboardingProfileImageSubtitle => '之后随时可以更换';

  @override
  String get onboardingProfileImageDescription => '你的头像会\n和你的笔记一起显示';

  @override
  String get onboardingProfileImageNote => '只有公开的笔记才会显示';

  @override
  String get onboardingGenreTitle => '偏好';

  @override
  String get onboardingGenreHeading => '你喜欢\n哪一类书';

  @override
  String get onboardingGenreSubtitle => '知道你的偏好，才好推荐第一本书\n至少选一个';

  @override
  String onboardingGenreNextCount(int count) {
    return '下一步 ($count)';
  }

  @override
  String get onboardingGenreSelectAtLeastOne => '请至少选一个';

  @override
  String get onboardingGenreNovel => '小说';

  @override
  String get onboardingGenrePoetry => '诗歌';

  @override
  String get onboardingGenreEssay => '随笔';

  @override
  String get onboardingGenreHumanities => '人文';

  @override
  String get onboardingGenrePhilosophy => '哲学';

  @override
  String get onboardingGenreScience => '科学';

  @override
  String get onboardingGenreSciFi => '科幻';

  @override
  String get onboardingGenreHistory => '历史';

  @override
  String get onboardingGenreArt => '艺术';

  @override
  String get onboardingGenrePsychology => '心理';

  @override
  String get onboardingGenreBusiness => '经管';

  @override
  String get onboardingGenreSelfHelp => '励志';

  @override
  String get onboardingBookIntroTitle => '开始';

  @override
  String get onboardingBookIntroDescription => '一边读书\n一边把闪现的想法\n记下来 ✨';

  @override
  String get onboardingBookIntroStart => '搜一本书开始';

  @override
  String get onboardingBookIntroSkip => '以后再说';

  @override
  String get bookStatusWantToRead => '想读';

  @override
  String get bookStatusReading => '在读';

  @override
  String get bookStatusCompleted => '读完';

  @override
  String get bookFilterAll => '全部';

  @override
  String get bookShelfLoadError => '书架加载失败';

  @override
  String get bookShelfEmpty => '添加一本书吧';

  @override
  String get bookDetailTitle => '图书详情';

  @override
  String get bookActionDelete => '删除';

  @override
  String get bookDescriptionTitle => '内容简介';

  @override
  String get bookShowMore => '查看更多';

  @override
  String get bookMemosTitle => '这本书的笔记';

  @override
  String get bookMemoSegmentTogether => '大家';

  @override
  String get bookMemoSegmentMine => '我的';

  @override
  String get bookMemosLoadError => '笔记加载失败';

  @override
  String get bookMemosEmptyPublic => '还没有公开的笔记';

  @override
  String get bookMemosEmptyMine => '还没有留下笔记';

  @override
  String get bookMemoDefaultAuthor => 'milkyway';

  @override
  String get bookTimeJustNow => '刚刚';

  @override
  String bookTimeMinutesAgo(int count) {
    return '$count分钟前';
  }

  @override
  String bookTimeHoursAgo(int count) {
    return '$count小时前';
  }

  @override
  String bookTimeDaysAgo(int count) {
    return '$count天前';
  }

  @override
  String get bookWriteMemoCta => '写笔记';

  @override
  String get bookDetailLoadError => '图书信息加载失败';

  @override
  String bookStatusChanged(String status) {
    return '已改为$status';
  }

  @override
  String get bookDeleteTitle => '删除图书';

  @override
  String get bookDeleteBody => '删除这本书，书里的笔记也会一起消失，无法恢复。\n\n确定要删除吗？';

  @override
  String get bookSearchTitle => '搜索图书';

  @override
  String get bookSearchHint => '按书名 / 作者 / ISBN 搜索';

  @override
  String get bookSearchError => '搜索出错了';

  @override
  String get bookSearchEmptyTitle => '没有搜索结果';

  @override
  String get bookSearchEmptyBody => '换个关键词试试';

  @override
  String get bookAlreadyAdded => '这本书已在书架上';

  @override
  String get bookAdded => '已添加到书架';

  @override
  String get bookAddedNew => '已添加新书';

  @override
  String get bookAddFailed => '添加图书失败';

  @override
  String get bookOpStatusChange => '修改状态';

  @override
  String get bookOpDelete => '删除图书';

  @override
  String get bookOpRegister => '添加图书';

  @override
  String get bookOpConnect => '关联图书';

  @override
  String get readingLogTodayCta => '标记今天已读';

  @override
  String get readingLoggedToday => '今天已读';

  @override
  String get calendarTitle => '记录';

  @override
  String get calendarSegmentMemos => '笔记';

  @override
  String get calendarSegmentRead => '已读';

  @override
  String get calendarEmptyMemos => '这天没有笔记';

  @override
  String get calendarEmptyBooks => '这天没有读过的书';

  @override
  String get commentAnonymousAuthor => 'milkyway';

  @override
  String get commentMineTag => '我';

  @override
  String get commentEdit => '编辑';

  @override
  String get commentDelete => '删除';

  @override
  String get commentHide => '隐藏这条评论';

  @override
  String get commentReport => '举报';

  @override
  String get commentComposerLocked => '收藏这本书就能评论';

  @override
  String get commentComposerEditHint => '编辑评论';

  @override
  String get commentComposerHint => '写评论';

  @override
  String get commentSendError => '评论发送失败';

  @override
  String get commentDeleteTitle => '删除评论';

  @override
  String get commentDeleteMessage => '要删除这条评论吗？';

  @override
  String get commentDeleteConfirm => '删除';

  @override
  String get commentDeleteError => '删除失败';

  @override
  String get commentHideError => '隐藏失败';

  @override
  String get commentReportReasonTitle => '举报原因';

  @override
  String get commentReportSpam => '垃圾信息';

  @override
  String get commentReportInappropriate => '内容不当';

  @override
  String get commentReportHarassment => '骚扰/仇恨';

  @override
  String get commentReportSexual => '色情内容';

  @override
  String get commentReportOther => '其他';

  @override
  String get commentReportDone => '已举报，这条评论不再显示';

  @override
  String get commentReportError => '举报失败';

  @override
  String get commentSaveBookTitle => '收藏这本书';

  @override
  String get commentSaveBookMessage => '收藏这本书才能评论，要收藏吗？';

  @override
  String get commentSaveBookConfirm => '收藏';

  @override
  String get commentSaveBookError => '收藏失败';

  @override
  String get commentLoadError => '评论加载失败';

  @override
  String get commentSectionTitle => '评论';

  @override
  String commentSectionTitleCount(int count) {
    return '评论 $count';
  }

  @override
  String get commentEmpty => '来写第一条评论';

  @override
  String get shareLandingCta => '你也能有自己的宇宙';

  @override
  String get shareLandingCtaButton => '我也来做一个';

  @override
  String get shareLandingErrorTitle => '卡片加载失败';

  @override
  String get shareLandingErrorBody => '链接可能已过期，或卡片已删除';

  @override
  String get shareLandingGoHome => '回首页';

  @override
  String get commonEdited => '已编辑';

  @override
  String get commonMyMemo => '我的笔记';

  @override
  String commonPageLabel(int page) {
    return '第$page页';
  }

  @override
  String get commonLoadFailed => '加载失败';

  @override
  String get commonComposeHint => '留下今天读到的句子';

  @override
  String get commonTimeJustNow => '刚刚';

  @override
  String commonTimeMinutesAgo(int minutes) {
    return '$minutes分钟前';
  }

  @override
  String commonTimeHoursAgo(int hours) {
    return '$hours小时前';
  }

  @override
  String commonTimeDaysAgo(int days) {
    return '$days天前';
  }

  @override
  String get commonNavHome => '首页';

  @override
  String get commonNavBooks => '书架';

  @override
  String get commonNavMemos => '笔记';

  @override
  String get commonNavProfile => '我的';

  @override
  String get commonEmptyBookTitle => '挑一本新书 👇';

  @override
  String get commonEmptyBookCta => '想读什么书？🤔';

  @override
  String get homeSaveBookTitle => '收藏这本书';

  @override
  String get homeSaveBookMessage => '要把这本书加入书架吗？';

  @override
  String get homeSaveAction => '收藏';

  @override
  String get homeSaveBookError => '收藏失败';

  @override
  String get homeSectionOtherThoughts => '其他星星留下的想法';

  @override
  String get homeDefaultAuthor => 'milkyway';

  @override
  String get homeSectionRecentMemoBooks => '最近有笔记的书';

  @override
  String homeMemoMeta(String time) {
    return '$time的笔记';
  }

  @override
  String get homeReadPromptTitle => '今天读哪本书';

  @override
  String get homeReadPromptBody => '从书架里挑一本';

  @override
  String get homeOrbTitle => '你的宇宙正在长大';

  @override
  String get homeOrbBody => '看看你的银河，分享出去';

  @override
  String get homeConstellationTitle => '你的想法正在相连';

  @override
  String get homeConstellationBody => '看看笔记之间连成的星座';

  @override
  String get homeWeekdayMon => '一';

  @override
  String get homeWeekdayTue => '二';

  @override
  String get homeWeekdayWed => '三';

  @override
  String get homeWeekdayThu => '四';

  @override
  String get homeWeekdayFri => '五';

  @override
  String get homeWeekdaySat => '六';

  @override
  String get homeWeekdaySun => '日';

  @override
  String get homeRecordTitle => '我的记录';

  @override
  String get homeViewAll => '查看全部';

  @override
  String get homeTimeJustNow => '刚刚';

  @override
  String homeTimeMinutesAgo(int count) {
    return '$count分钟前';
  }

  @override
  String homeTimeHoursAgo(int count) {
    return '$count小时前';
  }

  @override
  String homeTimeDaysAgo(int count) {
    return '$count天前';
  }

  @override
  String get homeWelcomeTitle => '从一本喜欢的书开始';

  @override
  String get homeWelcomeBody => '收藏之后 Lyra 会来提问\n也看看下面别人收藏的书';

  @override
  String get homeWelcomeCta => '去挑一本书';

  @override
  String get homeStatusReading => '在读';

  @override
  String get homeSectionSavedByOthers => '别人收藏的书';

  @override
  String get homeAddBook => '添加图书';

  @override
  String get homeAddMemo => '写笔记';

  @override
  String get discoveryTitle => '收藏图书';

  @override
  String get discoverySkip => '以后再说';

  @override
  String get discoveryLoadError => '推荐加载失败';

  @override
  String get discoveryEmpty => '还没有推荐的书';

  @override
  String get discoveryHeading => '大家写过笔记的书';

  @override
  String get discoveryBody => '收藏喜欢的书\nLyra 会为你提问';

  @override
  String get discoverySearchCta => '没找到就直接搜索';

  @override
  String discoveryStartCta(int count) {
    return '收藏 $count 本开始';
  }

  @override
  String get discoverySaveError => '收藏失败';

  @override
  String discoveryProofSavers(int count) {
    return '$count 人收藏';
  }

  @override
  String discoveryProofMemos(int count) {
    return '$count 条笔记';
  }

  @override
  String get discoveryProofNew => '刚刚上架';

  @override
  String get memoTitle => '笔记';

  @override
  String get memoSelectBook => '选择图书';

  @override
  String get memoAnsweringLyra => '正在回答 Lyra 的提问';

  @override
  String get memoContentHint => '写下今天读到的句子，和它留下的想法';

  @override
  String get memoPageHint => '页';

  @override
  String get memoVisibilityPublic => '公开';

  @override
  String get memoVisibilityPrivateOnlyMe => '仅自己可见';

  @override
  String get memoNoBooksYet => '请先收藏一本书';

  @override
  String get memoPickBookTitle => '这是哪本书的笔记';

  @override
  String get memoImagePickTitle => '选择图片';

  @override
  String get memoImageFromGallery => '从相册选择';

  @override
  String get memoImageFromCamera => '拍照';

  @override
  String get memoSelectBookRequired => '请选择图书';

  @override
  String get memoContentRequired => '请输入笔记内容';

  @override
  String get memoImageUploadFailed => '图片上传失败';

  @override
  String get memoSaved => '笔记已保存';

  @override
  String get memoEditTitle => '编辑笔记';

  @override
  String get memoDelete => '删除';

  @override
  String get memoBookFallback => '书';

  @override
  String get memoEditHint => '输入笔记';

  @override
  String get memoUpdated => '笔记已更新';

  @override
  String get memoDeleteTitle => '删除笔记';

  @override
  String get memoDeleteConfirm => '要删除这条笔记吗？';

  @override
  String get memoDeleteAsk => '要删除这条笔记吗？';

  @override
  String get memoUnsavedTitle => '有未保存的更改';

  @override
  String get memoUnsavedBody => '不保存就离开吗？';

  @override
  String get memoLeave => '离开';

  @override
  String get memoLoadFailed => '笔记加载失败';

  @override
  String get memoSaveBookTitle => '收藏这本书';

  @override
  String get memoSaveBookConfirm => '收藏';

  @override
  String get memoRestrictedBody => '这条笔记现在看不了，要收藏这本书去看详情吗？';

  @override
  String get memoSaveBookBody => '收藏这本书才能看详情，要收藏吗？';

  @override
  String get memoAuthorFallback => 'milkyway';

  @override
  String get memoMineTag => '我的';

  @override
  String get memoEditedTag => '已编辑';

  @override
  String memoDateMonthDay(int month, int day) {
    return '$month月$day日';
  }

  @override
  String get memoLyraQuestionLabel => 'Lyra 的提问';

  @override
  String get memoPublicLabel => '公开笔记';

  @override
  String get memoPrivateLabel => '私密笔记';

  @override
  String get memoEditAction => '编辑';

  @override
  String get memoDeleteAction => '删除';

  @override
  String get memoConstellationTooltip => '星座';

  @override
  String get memoSegmentMine => '我的笔记';

  @override
  String get memoFeedLoadFailed => '动态加载失败';

  @override
  String get memoEmptyMine => '还没有笔记';

  @override
  String get memoEmptyPublic => '还没有公开笔记';

  @override
  String get memoTimeJustNow => '刚刚';

  @override
  String memoTimeMinutesAgo(int count) {
    return '$count 分钟前';
  }

  @override
  String memoTimeHoursAgo(int count) {
    return '$count 小时前';
  }

  @override
  String memoTimeDaysAgo(int count) {
    return '$count 天前';
  }

  @override
  String get memoLoadErrorTitle => '笔记加载失败';

  @override
  String get memoEmptyTitle => '还没有笔记';

  @override
  String get memoEmptyBody => '写下第一条笔记吧';

  @override
  String get memoFilterWrittenByMe => '我写的';

  @override
  String get memoFilterAllMemos => '全部';

  @override
  String get memoFilterPrivate => '私密';

  @override
  String get memoErrorCameraPermission => '需要相机权限';

  @override
  String get memoErrorCameraUnavailable => '无法使用相机';

  @override
  String get memoErrorPhotoPermission => '需要相册权限';

  @override
  String get memoErrorImagePick => '选择图片时出错';

  @override
  String get memoErrorNetwork => '请检查网络连接';

  @override
  String get memoErrorPermission => '需要访问权限';

  @override
  String get memoErrorSave => '保存时出错';

  @override
  String get memoErrorGeneric => '出错了';

  @override
  String get memoImageLabel => '图片 (选填)';

  @override
  String get memoImageHint => '添加想保存的书页';

  @override
  String get memoContentLabel => '笔记内容';

  @override
  String memoContentHintMax(int max) {
    return '写下读到的内容或想法 (最多 $max 字)';
  }

  @override
  String get memoPageLabel => '页码 (选填)';

  @override
  String get memoPageHintExample => '例如 123 (仅数字)';

  @override
  String get memoVisibilityLabel => '笔记公开设置';

  @override
  String get memoVisibilityDescription => '打开后这条笔记会公开';

  @override
  String get memoAddBookAction => '添加图书';

  @override
  String get memoAddMemoAction => '写笔记';

  @override
  String get reportAction => '举报';

  @override
  String get reportGuide => '请举报不当内容，举报的笔记会在审核后处理';

  @override
  String get reportReasonTitle => '举报原因';

  @override
  String get reportDescriptionLabel => '补充说明 (选填)';

  @override
  String get reportDescriptionHint => '请详细说明举报原因';

  @override
  String get reportSubmitted => '已收到举报，我们会尽快审核';

  @override
  String get reportAlreadyReported => '这条笔记已经举报过';

  @override
  String get reportFailed => '举报失败，请稍后再试';

  @override
  String get reportReasonSpam => '垃圾信息/广告';

  @override
  String get reportReasonInappropriate => '不当内容';

  @override
  String get reportReasonHarassment => '仇恨言论/骚扰';

  @override
  String get reportReasonSexual => '色情内容';

  @override
  String get reportReasonViolence => '暴力内容';

  @override
  String get reportReasonCopyright => '侵犯版权';

  @override
  String get reportReasonOther => '其他';

  @override
  String get profileLoadError => '加载失败';

  @override
  String get profileLoginRequired => '需要登录';

  @override
  String get profileEdit => '编辑资料';

  @override
  String get profileMyRecord => '我的记录';

  @override
  String get profileSavedBooks => '收藏的书';

  @override
  String get profileCompletedBooks => '读完的书';

  @override
  String get profileMenuNotification => '通知';

  @override
  String get profileMenuFeedback => '意见反馈';

  @override
  String get profileMenuTerms => '服务条款';

  @override
  String get profileMenuVersion => '应用版本';

  @override
  String get profileNotificationSaveFailed => '设置保存失败';

  @override
  String get profileNotificationPermissionTitle => '需要通知权限';

  @override
  String get profileNotificationPermissionBody => '想收到通知的话，请在系统设置里打开通知权限';

  @override
  String get profileOpenSettings => '打开设置';

  @override
  String get profileFeedbackTitle => '留下意见';

  @override
  String get profileFeedbackHint => '请输入意见';

  @override
  String get profileFeedbackSend => '发送';

  @override
  String get profileFeedbackThanks => '谢谢你的意见';

  @override
  String get profileFeedbackError => '发送出了点问题，稍后再试';

  @override
  String get profileEditTitle => '编辑资料';

  @override
  String get profileEditChangePhoto => '更换头像';

  @override
  String get profileEditRemovePhoto => '移除头像';

  @override
  String get profileEditPickImage => '选择图片';

  @override
  String get profileEditFromGallery => '从相册选择';

  @override
  String get profileEditFromCamera => '拍照';

  @override
  String profileEditPickImageError(String error) {
    return '选择图片时出错：$error';
  }

  @override
  String get profileEditNicknameLabel => '昵称';

  @override
  String get profileEditNicknameHint => '请输入昵称';

  @override
  String get profileEditNicknameRule => '2 - 20 个字符，不能用特殊字符';

  @override
  String get profileEditChecking => '检查中...';

  @override
  String get profileEditNicknameTooShort => '昵称至少需要 2 个字符';

  @override
  String get profileEditNicknameTooLong => '昵称最多 20 个字符';

  @override
  String get profileEditNicknameNoSpecial => '不能使用特殊字符';

  @override
  String get profileEditNicknameTaken => '该昵称已被使用';

  @override
  String get profileEditNicknameCheckError => '检查昵称时出错';

  @override
  String get profileEditNicknameRequired => '请输入昵称';

  @override
  String get profileEditNicknameChecking => '正在检查昵称，请稍候';

  @override
  String get profileEditEmailLabel => '邮箱';

  @override
  String get profileEditNoEmail => '无邮箱';

  @override
  String get profileEditEmailFixed => '邮箱无法更改';

  @override
  String get profileEditNoChanges => '没有更改';

  @override
  String get profileEditImageUploadFailed => '头像上传失败';

  @override
  String get profileEditSaved => '资料已更新';

  @override
  String get profileEditLogout => '退出登录';

  @override
  String get profileEditLogoutConfirm => '确定要退出登录吗？';

  @override
  String get profileEditDeleteAccount => '注销账号';

  @override
  String get profileEditDelete => '删除';

  @override
  String get profileEditDeleteAccountMessage =>
      '现在注销的话，书和笔记会在 30 天后彻底删除。在那之前重新登录，就能原样恢复。要继续吗？';

  @override
  String get rankingCardTitle => '我这周的记录';

  @override
  String rankingTopPercent(int percent) {
    return '前 $percent%';
  }

  @override
  String rankingDeltaUp(int count) {
    return '比上周多了 $count 条';
  }

  @override
  String rankingDeltaDown(int count) {
    return '比上周少了 $count 条';
  }

  @override
  String get rankingDeltaSame => '和上周一样';

  @override
  String get rankingEmptyTitle => '写下这周的第一条记录';

  @override
  String rankingLastWeek(int count) {
    return '上周写了 $count 条';
  }

  @override
  String rankingThisWeekCount(int count) {
    return '这周 $count 条';
  }

  @override
  String rankingStreakDays(int days) {
    return '连续读了 $days 天';
  }

  @override
  String get errCameraPermission => '需要相机访问权限';

  @override
  String get errCameraUnavailable => '无法使用相机';

  @override
  String get errPhotoPermission => '需要照片访问权限';

  @override
  String get errGeneric => '出了点问题';

  @override
  String get errNetwork => '请检查网络连接';

  @override
  String get errPermission => '需要访问权限';

  @override
  String get errUploadFailed => '上传失败';

  @override
  String get errCreateFailed => '创建失败';

  @override
  String get errUpdateFailed => '更新失败';

  @override
  String get errDeleteFailed => '删除失败';

  @override
  String get errSaveFailed => '保存失败';

  @override
  String get errAuthRequired => '需要登录';

  @override
  String get errServer => '服务器出错';
}
