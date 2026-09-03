// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppL10nEn extends AppL10n {
  AppL10nEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'milkyway';

  @override
  String get commonSave => 'Save';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonNext => 'Next';

  @override
  String get commonClose => 'Close';

  @override
  String get commonConfirm => 'OK';

  @override
  String get commonRetry => 'Try again';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get languageSystem => 'System default';

  @override
  String get languageKorean => '한국어';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageJapanese => '日本語';

  @override
  String get languageChinese => '中文';

  @override
  String get unitBooks => '';

  @override
  String get unitCount => '';

  @override
  String get unitDays => '';

  @override
  String get statBooksRead => 'Books read';

  @override
  String get statMemosLeft => 'Memos';

  @override
  String get statTopPercent => 'Top';

  @override
  String get statStreak => 'Day streak';

  @override
  String get constellationTitle => 'Constellation';

  @override
  String get constellationLoadError => 'Could not load your constellation';

  @override
  String get constellationEmptyTitle => 'No stars connected yet';

  @override
  String get constellationEmptyBody =>
      'As memos pile up, they connect and a night sky appears';

  @override
  String constellationConnected(int count) {
    return '$count connected moments';
  }

  @override
  String get constellationWhenPast => 'Then';

  @override
  String get constellationWhenNow => 'Now';

  @override
  String get constellationRelExtends => 'Extends';

  @override
  String get constellationRelReverses => 'Shifts';

  @override
  String get constellationRelEcho => 'Echoes';

  @override
  String get constellationRelSimilar => 'Similar';

  @override
  String get constellationRelDefault => 'Linked';

  @override
  String get constellationRevealTitle => 'A line was drawn';

  @override
  String get constellationViewInConstellation => 'View in constellation';

  @override
  String get lyraQuestionLabel => 'A question from Lyra';

  @override
  String get lyraAnswerCta => 'Answer with a memo';

  @override
  String get orbTierNebulaSmall => 'Small Nebula';

  @override
  String get orbTierStarCluster => 'Starfield';

  @override
  String get orbTierConstellation => 'Constellation';

  @override
  String get orbTierCluster => 'Star Cluster';

  @override
  String get orbTierGalaxy => 'Galaxy';

  @override
  String get orbTierSuperGalaxy => 'Supergalaxy';

  @override
  String get orbMyUniverseTitle => 'My universe';

  @override
  String get orbNowPrefix => 'Now: ';

  @override
  String orbTierBadge(String name) {
    return '$name tier';
  }

  @override
  String orbToNextTier(String next) {
    return 'Points to $next: ';
  }

  @override
  String get orbDeepestReached => 'Deepest space reached';

  @override
  String get orbShareLinkCopied => 'Share link copied';

  @override
  String get orbShareError =>
      'Something went wrong while preparing the share. Try again in a bit';

  @override
  String get orbGateBannerTitle => 'Create your first orb';

  @override
  String orbGateBannerBody(int count) {
    return '$count more memos to go';
  }

  @override
  String orbGateSheetTitle(int count) {
    return '$count memos to go';
  }

  @override
  String orbGateSheetBody(int count) {
    return 'Write $count more memos\nand your galaxy orb is complete';
  }

  @override
  String get orbGateWriteCta => 'Write a memo now';

  @override
  String get shareCardDefaultNick => 'Me';

  @override
  String shareCardOwnerUniverse(String nick) {
    return '$nick\'s universe';
  }

  @override
  String get shareCardTagline => 'What shape is your universe';

  @override
  String get shareCardStoreHint => 'milkyway on App Store / Google Play';

  @override
  String get wrappedTitle => 'Galaxy recap';

  @override
  String wrappedHeroLead(String month) {
    return 'In $month, you';
  }

  @override
  String get wrappedHeroAccent => 'paused here';

  @override
  String wrappedStarsLeft(int count) {
    return '$count stars left in those moments';
  }

  @override
  String get wrappedStatSentences => 'Sentences';

  @override
  String get wrappedStatReadDays => 'Days read';

  @override
  String get wrappedTopBookLabel => 'The book you stayed with longest';

  @override
  String get wrappedQuoteLabel => 'Sentence of the month';

  @override
  String wrappedQuoteSource(String title) {
    return 'From $title';
  }

  @override
  String get wrappedShareCta => 'Share the recap';

  @override
  String get wrappedEmptyTitle =>
      'This month\'s recap is still coming together';

  @override
  String get wrappedEmptyBody => 'Leave a memo and a star stays in that moment';

  @override
  String get wrappedLoadErrorTitle => 'Could not load the recap';

  @override
  String get wrappedLoadErrorBody => 'Try again in a bit';

  @override
  String get wrappedShareLinkCopied => 'Share link copied';

  @override
  String get wrappedShareError =>
      'Something went wrong while preparing the share. Try again in a bit';

  @override
  String get commonShare => 'Share';

  @override
  String get orbLoadErrorTitle => 'Could not load your universe';

  @override
  String wrappedEntryTitle(String month) {
    return '$month galaxy recap';
  }

  @override
  String wrappedEntryBody(int count) {
    return '$count stars gathered';
  }

  @override
  String get authSignInApple => 'Continue with Apple';

  @override
  String get authSignInGoogle => 'Continue with Google';

  @override
  String get authSignInFailed => 'Sign-in failed. Please try again';

  @override
  String get authNotificationPermissionTitle => 'Notifications';

  @override
  String get authNotificationPermissionBody =>
      'We will let you know when a new memo shows up on a book you are reading';

  @override
  String get authNotificationPermissionLater => 'Later';

  @override
  String get authNotificationPermissionAllow => 'Allow';

  @override
  String get splashUpdateTitle => 'Update required';

  @override
  String get splashUpdateBody =>
      'A new version is available.\nPlease update to keep reading';

  @override
  String get splashUpdateAction => 'Update';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingNicknameTitle => 'Nickname';

  @override
  String get onboardingNicknameHeading => 'Set your nickname';

  @override
  String get onboardingNicknameSubtitle =>
      'Other milkyway readers can see this name';

  @override
  String get onboardingNicknameLabel => 'Nickname';

  @override
  String get onboardingNicknameHint => 'Enter a nickname';

  @override
  String get onboardingNicknameChecking => 'Checking...';

  @override
  String get onboardingNicknameHelp =>
      '2 - 20 characters, no special characters';

  @override
  String get onboardingNicknameErrorTooShort => 'Use at least 2 characters';

  @override
  String get onboardingNicknameErrorTooLong => 'Use 20 characters or fewer';

  @override
  String get onboardingNicknameErrorSpecialChars =>
      'Special characters are not allowed';

  @override
  String get onboardingNicknameErrorTaken => 'That nickname is taken';

  @override
  String get onboardingNicknameErrorCheckFailed =>
      'Could not check the nickname';

  @override
  String onboardingNicknameSaveError(String error) {
    return 'Could not save the nickname: $error';
  }

  @override
  String get onboardingProfileImageTitle => 'Profile photo';

  @override
  String get onboardingProfileImageHeading => 'Set a profile photo';

  @override
  String get onboardingProfileImageSubtitle => 'You can change it anytime';

  @override
  String get onboardingProfileImageDescription =>
      'Your photo shows up\nnext to the memos you leave';

  @override
  String get onboardingProfileImageNote =>
      'Only memos you make public are shown';

  @override
  String get onboardingGenreTitle => 'Taste';

  @override
  String get onboardingGenreHeading => 'What kind of books\ndo you like?';

  @override
  String get onboardingGenreSubtitle =>
      'Your taste helps us pick a better first book\nChoose at least one';

  @override
  String onboardingGenreNextCount(int count) {
    return 'Next ($count)';
  }

  @override
  String get onboardingGenreSelectAtLeastOne => 'Choose at least one';

  @override
  String get onboardingGenreNovel => 'Novel';

  @override
  String get onboardingGenrePoetry => 'Poetry';

  @override
  String get onboardingGenreEssay => 'Essay';

  @override
  String get onboardingGenreHumanities => 'Humanities';

  @override
  String get onboardingGenrePhilosophy => 'Philosophy';

  @override
  String get onboardingGenreScience => 'Science';

  @override
  String get onboardingGenreSciFi => 'Sci-fi';

  @override
  String get onboardingGenreHistory => 'History';

  @override
  String get onboardingGenreArt => 'Art';

  @override
  String get onboardingGenrePsychology => 'Psychology';

  @override
  String get onboardingGenreBusiness => 'Business';

  @override
  String get onboardingGenreSelfHelp => 'Self-help';

  @override
  String get onboardingBookIntroTitle => 'Get started';

  @override
  String get onboardingBookIntroDescription =>
      'Now read, and keep\nthe bright thoughts\nthat come to you ✨';

  @override
  String get onboardingBookIntroStart => 'Find a book to start';

  @override
  String get onboardingBookIntroSkip => 'Maybe later';

  @override
  String get bookStatusWantToRead => 'To read';

  @override
  String get bookStatusReading => 'Reading';

  @override
  String get bookStatusCompleted => 'Done';

  @override
  String get bookFilterAll => 'All';

  @override
  String get bookShelfLoadError => 'Could not load your books';

  @override
  String get bookShelfEmpty => 'Add a book to get started';

  @override
  String get bookDetailTitle => 'Book details';

  @override
  String get bookActionDelete => 'Delete';

  @override
  String get bookDescriptionTitle => 'About this book';

  @override
  String get bookShowMore => 'Show more';

  @override
  String get bookMemosTitle => 'Memos on this book';

  @override
  String get bookMemoSegmentTogether => 'Everyone';

  @override
  String get bookMemoSegmentMine => 'Mine';

  @override
  String get bookMemosLoadError => 'Could not load memos';

  @override
  String get bookMemosEmptyPublic => 'No public memos yet';

  @override
  String get bookMemosEmptyMine => 'No memos yet';

  @override
  String get bookMemoDefaultAuthor => 'milkyway';

  @override
  String get bookTimeJustNow => 'Just now';

  @override
  String bookTimeMinutesAgo(int count) {
    return '${count}m ago';
  }

  @override
  String bookTimeHoursAgo(int count) {
    return '${count}h ago';
  }

  @override
  String bookTimeDaysAgo(int count) {
    return '${count}d ago';
  }

  @override
  String get bookWriteMemoCta => 'Write a memo';

  @override
  String get bookDetailLoadError => 'Could not load the book';

  @override
  String bookStatusChanged(String status) {
    return 'Changed to $status';
  }

  @override
  String get bookDeleteTitle => 'Delete book';

  @override
  String get bookDeleteBody =>
      'Deleting this book also deletes every memo on it, and it cannot be undone.\n\nDelete anyway?';

  @override
  String get bookSearchTitle => 'Search books';

  @override
  String get bookSearchHint => 'Search by title, author, or ISBN';

  @override
  String get bookSearchError => 'Something went wrong while searching';

  @override
  String get bookSearchEmptyTitle => 'No results';

  @override
  String get bookSearchEmptyBody => 'Try a different keyword';

  @override
  String get bookAlreadyAdded => 'Already on your shelf';

  @override
  String get bookAdded => 'Added to your shelf';

  @override
  String get bookAddedNew => 'New book added';

  @override
  String get bookAddFailed => 'Could not add the book';

  @override
  String get bookOpStatusChange => 'Changing status';

  @override
  String get bookOpDelete => 'Deleting book';

  @override
  String get bookOpRegister => 'Adding book';

  @override
  String get bookOpConnect => 'Linking book';

  @override
  String get readingLogTodayCta => 'Mark today as read';

  @override
  String get readingLoggedToday => 'Marked as read today';

  @override
  String get calendarTitle => 'Log';

  @override
  String get calendarSegmentMemos => 'Memos';

  @override
  String get calendarSegmentRead => 'Read';

  @override
  String get calendarEmptyMemos => 'No memos on this day';

  @override
  String get calendarEmptyBooks => 'No books read on this day';

  @override
  String get commentAnonymousAuthor => 'milkyway';

  @override
  String get commentMineTag => 'Me';

  @override
  String get commentEdit => 'Edit';

  @override
  String get commentDelete => 'Delete';

  @override
  String get commentHide => 'Hide this comment';

  @override
  String get commentReport => 'Report';

  @override
  String get commentComposerLocked => 'Save the book to comment';

  @override
  String get commentComposerEditHint => 'Edit comment';

  @override
  String get commentComposerHint => 'Leave a comment';

  @override
  String get commentSendError => 'Could not post';

  @override
  String get commentDeleteTitle => 'Delete comment';

  @override
  String get commentDeleteMessage => 'Delete this comment?';

  @override
  String get commentDeleteConfirm => 'Delete';

  @override
  String get commentDeleteError => 'Could not delete';

  @override
  String get commentHideError => 'Could not hide';

  @override
  String get commentReportReasonTitle => 'Report reason';

  @override
  String get commentReportSpam => 'Spam';

  @override
  String get commentReportInappropriate => 'Inappropriate';

  @override
  String get commentReportHarassment => 'Harassment';

  @override
  String get commentReportSexual => 'Sexual content';

  @override
  String get commentReportOther => 'Other';

  @override
  String get commentReportDone => 'Reported. This comment is hidden now';

  @override
  String get commentReportError => 'Could not report';

  @override
  String get commentSaveBookTitle => 'Save book';

  @override
  String get commentSaveBookMessage =>
      'Save this book first to leave a comment. Save it?';

  @override
  String get commentSaveBookConfirm => 'Save';

  @override
  String get commentSaveBookError => 'Could not save';

  @override
  String get commentLoadError => 'Could not load comments';

  @override
  String get commentSectionTitle => 'Comments';

  @override
  String commentSectionTitleCount(int count) {
    return 'Comments $count';
  }

  @override
  String get commentEmpty => 'Be the first to comment';

  @override
  String get shareLandingCta => 'You can build your own universe too';

  @override
  String get shareLandingCtaButton => 'Make mine';

  @override
  String get shareLandingErrorTitle => 'Could not load the card';

  @override
  String get shareLandingErrorBody =>
      'The link may have expired or the card was deleted';

  @override
  String get shareLandingGoHome => 'Go home';

  @override
  String get commonEdited => 'Edited';

  @override
  String get commonMyMemo => 'My memo';

  @override
  String commonPageLabel(int page) {
    return 'p.$page';
  }

  @override
  String get commonLoadFailed => 'Could not load';

  @override
  String get commonComposeHint => 'Leave a line you read today';

  @override
  String get commonTimeJustNow => 'Just now';

  @override
  String commonTimeMinutesAgo(int minutes) {
    return '${minutes}m ago';
  }

  @override
  String commonTimeHoursAgo(int hours) {
    return '${hours}h ago';
  }

  @override
  String commonTimeDaysAgo(int days) {
    return '${days}d ago';
  }

  @override
  String get commonNavHome => 'Home';

  @override
  String get commonNavBooks => 'Books';

  @override
  String get commonNavMemos => 'Memos';

  @override
  String get commonNavProfile => 'Profile';

  @override
  String get commonEmptyBookTitle => 'Pick a new book 👇';

  @override
  String get commonEmptyBookCta => 'What do you want to read? 🤔';

  @override
  String get homeSaveBookTitle => 'Save book';

  @override
  String get homeSaveBookMessage => 'Save this book to your shelf?';

  @override
  String get homeSaveAction => 'Save';

  @override
  String get homeSaveBookError => 'Could not save the book';

  @override
  String get homeSectionOtherThoughts => 'Thoughts from other stars';

  @override
  String get homeDefaultAuthor => 'milkyway';

  @override
  String get homeSectionRecentMemoBooks => 'Books with new memos';

  @override
  String homeMemoMeta(String time) {
    return 'Memo $time';
  }

  @override
  String get homeReadPromptTitle => 'What to read today';

  @override
  String get homeReadPromptBody => 'Pick from your shelf';

  @override
  String get homeOrbTitle => 'Your universe grows';

  @override
  String get homeOrbBody => 'See and share your galaxy';

  @override
  String get homeConstellationTitle => 'Your thoughts connect';

  @override
  String get homeConstellationBody => 'See how your memos link';

  @override
  String get homeWeekdayMon => 'Mon';

  @override
  String get homeWeekdayTue => 'Tue';

  @override
  String get homeWeekdayWed => 'Wed';

  @override
  String get homeWeekdayThu => 'Thu';

  @override
  String get homeWeekdayFri => 'Fri';

  @override
  String get homeWeekdaySat => 'Sat';

  @override
  String get homeWeekdaySun => 'Sun';

  @override
  String get homeRecordTitle => 'My record';

  @override
  String get homeViewAll => 'View all';

  @override
  String get homeTimeJustNow => 'Just now';

  @override
  String homeTimeMinutesAgo(int count) {
    return '${count}m ago';
  }

  @override
  String homeTimeHoursAgo(int count) {
    return '${count}h ago';
  }

  @override
  String homeTimeDaysAgo(int count) {
    return '${count}d ago';
  }

  @override
  String get homeWelcomeTitle => 'Start with one book';

  @override
  String get homeWelcomeBody =>
      'Save one and Lyra will ask you something\nBrowse what others saved below';

  @override
  String get homeWelcomeCta => 'Find a book';

  @override
  String get homeStatusReading => 'Reading';

  @override
  String get homeSectionSavedByOthers => 'Books others saved';

  @override
  String get homeAddBook => 'Add a book';

  @override
  String get homeAddMemo => 'Write a memo';

  @override
  String get discoveryTitle => 'Save books';

  @override
  String get discoverySkip => 'Later';

  @override
  String get discoveryLoadError => 'Could not load recommendations';

  @override
  String get discoveryEmpty => 'No recommendations yet';

  @override
  String get discoveryHeading => 'Books people wrote about';

  @override
  String get discoveryBody =>
      'Save the books you like\nLyra will ask you about them';

  @override
  String get discoverySearchCta => 'Search for another book';

  @override
  String discoveryStartCta(int count) {
    return 'Save $count and start';
  }

  @override
  String get discoverySaveError => 'Could not save the book';

  @override
  String discoveryProofSavers(int count) {
    return '$count saved this';
  }

  @override
  String discoveryProofMemos(int count) {
    return '$count memos';
  }

  @override
  String get discoveryProofNew => 'Just added';

  @override
  String get memoTitle => 'Memo';

  @override
  String get memoSelectBook => 'Pick a book';

  @override
  String get memoAnsweringLyra => 'Answering Lyra';

  @override
  String get memoContentHint =>
      'Write the line you read today and what it left behind';

  @override
  String get memoPageHint => 'p';

  @override
  String get memoVisibilityPublic => 'Public';

  @override
  String get memoVisibilityPrivateOnlyMe => 'Only me';

  @override
  String get memoNoBooksYet => 'Save a book first';

  @override
  String get memoPickBookTitle => 'Which book is this for?';

  @override
  String get memoImagePickTitle => 'Choose image';

  @override
  String get memoImageFromGallery => 'From gallery';

  @override
  String get memoImageFromCamera => 'Take a photo';

  @override
  String get memoSelectBookRequired => 'Please pick a book';

  @override
  String get memoContentRequired => 'Please write your memo';

  @override
  String get memoImageUploadFailed => 'Image upload failed';

  @override
  String get memoSaved => 'Memo saved';

  @override
  String get memoEditTitle => 'Edit memo';

  @override
  String get memoDelete => 'Delete';

  @override
  String get memoBookFallback => 'Book';

  @override
  String get memoEditHint => 'Write your memo';

  @override
  String get memoUpdated => 'Memo updated';

  @override
  String get memoDeleteTitle => 'Delete memo';

  @override
  String get memoDeleteConfirm => 'Delete this memo?';

  @override
  String get memoDeleteAsk => 'Delete this memo?';

  @override
  String get memoUnsavedTitle => 'Unsaved changes';

  @override
  String get memoUnsavedBody => 'Leave without saving?';

  @override
  String get memoLeave => 'Leave';

  @override
  String get memoLoadFailed => 'Could not load the memo';

  @override
  String get memoSaveBookTitle => 'Save book';

  @override
  String get memoSaveBookConfirm => 'Save';

  @override
  String get memoRestrictedBody =>
      'This memo is not visible right now. Save the book and open its page?';

  @override
  String get memoSaveBookBody => 'Save this book to see its page. Save it?';

  @override
  String get memoAuthorFallback => 'milkyway';

  @override
  String get memoMineTag => 'Mine';

  @override
  String get memoEditedTag => 'Edited';

  @override
  String memoDateMonthDay(int month, int day) {
    return '$month/$day';
  }

  @override
  String get memoLyraQuestionLabel => 'Lyra asked';

  @override
  String get memoPublicLabel => 'Public memo';

  @override
  String get memoPrivateLabel => 'Private memo';

  @override
  String get memoEditAction => 'Edit';

  @override
  String get memoDeleteAction => 'Delete';

  @override
  String get memoConstellationTooltip => 'Constellation';

  @override
  String get memoSegmentMine => 'Mine';

  @override
  String get memoFeedLoadFailed => 'Could not load the feed';

  @override
  String get memoEmptyMine => 'No memos yet';

  @override
  String get memoEmptyPublic => 'No public memos yet';

  @override
  String get memoTimeJustNow => 'Just now';

  @override
  String memoTimeMinutesAgo(int count) {
    return '${count}m ago';
  }

  @override
  String memoTimeHoursAgo(int count) {
    return '${count}h ago';
  }

  @override
  String memoTimeDaysAgo(int count) {
    return '${count}d ago';
  }

  @override
  String get memoLoadErrorTitle => 'Could not load memos';

  @override
  String get memoEmptyTitle => 'No memos yet';

  @override
  String get memoEmptyBody => 'Write your first memo';

  @override
  String get memoFilterWrittenByMe => 'Mine';

  @override
  String get memoFilterAllMemos => 'All';

  @override
  String get memoFilterPrivate => 'Private';

  @override
  String get memoErrorCameraPermission => 'Camera access is needed';

  @override
  String get memoErrorCameraUnavailable => 'Camera is unavailable';

  @override
  String get memoErrorPhotoPermission => 'Photo access is needed';

  @override
  String get memoErrorImagePick => 'Could not pick the image';

  @override
  String get memoErrorNetwork => 'Check your network connection';

  @override
  String get memoErrorPermission => 'Access permission is needed';

  @override
  String get memoErrorSave => 'Could not save';

  @override
  String get memoErrorGeneric => 'Something went wrong';

  @override
  String get memoImageLabel => 'Image (optional)';

  @override
  String get memoImageHint => 'Add the page you want to keep';

  @override
  String get memoContentLabel => 'Memo';

  @override
  String memoContentHintMax(int max) {
    return 'Write what you read or thought (up to $max chars)';
  }

  @override
  String get memoPageLabel => 'Page number (optional)';

  @override
  String get memoPageHintExample => 'e.g. 123 (numbers only)';

  @override
  String get memoVisibilityLabel => 'Memo visibility';

  @override
  String get memoVisibilityDescription =>
      'Turn this on to make the memo public';

  @override
  String get memoAddBookAction => 'Add a book';

  @override
  String get memoAddMemoAction => 'Write a memo';

  @override
  String get reportAction => 'Report';

  @override
  String get reportGuide =>
      'Report inappropriate content. Reported memos are reviewed before any action.';

  @override
  String get reportReasonTitle => 'Reason';

  @override
  String get reportDescriptionLabel => 'Details (optional)';

  @override
  String get reportDescriptionHint => 'Tell us more';

  @override
  String get reportSubmitted => 'Report received. We will take a look';

  @override
  String get reportAlreadyReported => 'You already reported this memo';

  @override
  String get reportFailed => 'Something went wrong. Try again in a bit';

  @override
  String get reportReasonSpam => 'Spam / ads';

  @override
  String get reportReasonInappropriate => 'Inappropriate content';

  @override
  String get reportReasonHarassment => 'Hate or harassment';

  @override
  String get reportReasonSexual => 'Sexual content';

  @override
  String get reportReasonViolence => 'Violent content';

  @override
  String get reportReasonCopyright => 'Copyright violation';

  @override
  String get reportReasonOther => 'Other';

  @override
  String get profileLoadError => 'Could not load';

  @override
  String get profileLoginRequired => 'Sign-in required';

  @override
  String get profileEdit => 'Edit profile';

  @override
  String get profileMyRecord => 'My record';

  @override
  String get profileSavedBooks => 'Saved';

  @override
  String get profileCompletedBooks => 'Finished';

  @override
  String get profileMenuNotification => 'Notifications';

  @override
  String get profileMenuFeedback => 'Send feedback';

  @override
  String get profileMenuTerms => 'Terms';

  @override
  String get profileMenuVersion => 'App version';

  @override
  String get profileNotificationSaveFailed => 'Could not save the setting';

  @override
  String get profileNotificationPermissionTitle => 'Notification permission';

  @override
  String get profileNotificationPermissionBody =>
      'To get notifications, allow them in system settings';

  @override
  String get profileOpenSettings => 'Open settings';

  @override
  String get profileFeedbackTitle => 'Leave feedback';

  @override
  String get profileFeedbackHint => 'Write your feedback';

  @override
  String get profileFeedbackSend => 'Send';

  @override
  String get profileFeedbackThanks => 'Thanks for the feedback';

  @override
  String get profileFeedbackError => 'Something went wrong. Try again in a bit';

  @override
  String get profileEditTitle => 'Edit profile';

  @override
  String get profileEditChangePhoto => 'Change photo';

  @override
  String get profileEditRemovePhoto => 'Remove photo';

  @override
  String get profileEditPickImage => 'Choose image';

  @override
  String get profileEditFromGallery => 'From gallery';

  @override
  String get profileEditFromCamera => 'Take a photo';

  @override
  String profileEditPickImageError(String error) {
    return 'Something went wrong picking the image: $error';
  }

  @override
  String get profileEditNicknameLabel => 'Nickname';

  @override
  String get profileEditNicknameHint => 'Enter a nickname';

  @override
  String get profileEditNicknameRule =>
      '2 - 20 characters, no special characters';

  @override
  String get profileEditChecking => 'Checking...';

  @override
  String get profileEditNicknameTooShort => 'Use at least 2 characters';

  @override
  String get profileEditNicknameTooLong => 'Use 20 characters or fewer';

  @override
  String get profileEditNicknameNoSpecial =>
      'Special characters are not allowed';

  @override
  String get profileEditNicknameTaken => 'That nickname is taken';

  @override
  String get profileEditNicknameCheckError => 'Could not check the nickname';

  @override
  String get profileEditNicknameRequired => 'Enter a nickname';

  @override
  String get profileEditNicknameChecking => 'Checking the nickname, one moment';

  @override
  String get profileEditEmailLabel => 'Email';

  @override
  String get profileEditNoEmail => 'No email';

  @override
  String get profileEditEmailFixed => 'Email cannot be changed';

  @override
  String get profileEditNoChanges => 'Nothing changed';

  @override
  String get profileEditImageUploadFailed => 'Could not upload the photo';

  @override
  String get profileEditSaved => 'Profile updated';

  @override
  String get profileEditLogout => 'Log out';

  @override
  String get profileEditLogoutConfirm => 'Log out of this account?';

  @override
  String get profileEditDeleteAccount => 'Delete account';

  @override
  String get profileEditDelete => 'Delete';

  @override
  String get profileEditDeleteAccountMessage =>
      'Delete now and your books and memos are erased for good in 30 days. Log back in before then and everything comes back. Continue?';

  @override
  String get rankingCardTitle => 'My week';

  @override
  String rankingTopPercent(int percent) {
    return 'Top $percent%';
  }

  @override
  String rankingDeltaUp(int count) {
    return '$count more than last week';
  }

  @override
  String rankingDeltaDown(int count) {
    return '$count fewer than last week';
  }

  @override
  String get rankingDeltaSame => 'Same as last week';

  @override
  String get rankingEmptyTitle => 'Leave your first memo this week';

  @override
  String rankingLastWeek(int count) {
    return 'You left $count memos last week';
  }

  @override
  String rankingThisWeekCount(int count) {
    return '$count this week';
  }

  @override
  String rankingStreakDays(int days) {
    return '$days-day streak';
  }

  @override
  String get errCameraPermission => 'Camera access is needed';

  @override
  String get errCameraUnavailable => 'Camera is unavailable';

  @override
  String get errPhotoPermission => 'Photo access is needed';

  @override
  String get errGeneric => 'Something went wrong';

  @override
  String get errNetwork => 'Check your connection';

  @override
  String get errPermission => 'Permission is needed';

  @override
  String get errUploadFailed => 'Upload failed';

  @override
  String get errCreateFailed => 'Could not create';

  @override
  String get errUpdateFailed => 'Could not update';

  @override
  String get errDeleteFailed => 'Could not delete';

  @override
  String get errSaveFailed => 'Could not save';

  @override
  String get errAuthRequired => 'Sign-in required';

  @override
  String get errServer => 'Server error';
}
