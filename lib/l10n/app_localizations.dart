import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppL10n
/// returned by `AppL10n.of(context)`.
///
/// Applications need to include `AppL10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppL10n.localizationsDelegates,
///   supportedLocales: AppL10n.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppL10n.supportedLocales
/// property.
abstract class AppL10n {
  AppL10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppL10n of(BuildContext context) {
    return Localizations.of<AppL10n>(context, AppL10n)!;
  }

  static const LocalizationsDelegate<AppL10n> delegate = _AppL10nDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('ko'),
    Locale('zh'),
  ];

  /// No description provided for @appName.
  ///
  /// In ko, this message translates to:
  /// **'milkyway'**
  String get appName;

  /// No description provided for @commonSave.
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get commonSave;

  /// No description provided for @commonCancel.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get commonCancel;

  /// No description provided for @commonNext.
  ///
  /// In ko, this message translates to:
  /// **'다음'**
  String get commonNext;

  /// No description provided for @commonClose.
  ///
  /// In ko, this message translates to:
  /// **'닫기'**
  String get commonClose;

  /// No description provided for @commonConfirm.
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get commonConfirm;

  /// No description provided for @commonRetry.
  ///
  /// In ko, this message translates to:
  /// **'다시 시도'**
  String get commonRetry;

  /// No description provided for @settingsLanguage.
  ///
  /// In ko, this message translates to:
  /// **'언어'**
  String get settingsLanguage;

  /// No description provided for @languageSystem.
  ///
  /// In ko, this message translates to:
  /// **'기기 설정'**
  String get languageSystem;

  /// No description provided for @languageKorean.
  ///
  /// In ko, this message translates to:
  /// **'한국어'**
  String get languageKorean;

  /// No description provided for @languageEnglish.
  ///
  /// In ko, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageJapanese.
  ///
  /// In ko, this message translates to:
  /// **'日本語'**
  String get languageJapanese;

  /// No description provided for @languageChinese.
  ///
  /// In ko, this message translates to:
  /// **'中文'**
  String get languageChinese;

  /// No description provided for @unitBooks.
  ///
  /// In ko, this message translates to:
  /// **'권'**
  String get unitBooks;

  /// No description provided for @unitCount.
  ///
  /// In ko, this message translates to:
  /// **'개'**
  String get unitCount;

  /// No description provided for @unitDays.
  ///
  /// In ko, this message translates to:
  /// **'일'**
  String get unitDays;

  /// No description provided for @statBooksRead.
  ///
  /// In ko, this message translates to:
  /// **'읽은 책'**
  String get statBooksRead;

  /// No description provided for @statMemosLeft.
  ///
  /// In ko, this message translates to:
  /// **'남긴 메모'**
  String get statMemosLeft;

  /// No description provided for @statTopPercent.
  ///
  /// In ko, this message translates to:
  /// **'상위'**
  String get statTopPercent;

  /// No description provided for @statStreak.
  ///
  /// In ko, this message translates to:
  /// **'연속'**
  String get statStreak;

  /// No description provided for @constellationTitle.
  ///
  /// In ko, this message translates to:
  /// **'별자리'**
  String get constellationTitle;

  /// No description provided for @constellationLoadError.
  ///
  /// In ko, this message translates to:
  /// **'별자리를 불러오지 못했어'**
  String get constellationLoadError;

  /// No description provided for @constellationEmptyTitle.
  ///
  /// In ko, this message translates to:
  /// **'아직 이어진 별이 없어'**
  String get constellationEmptyTitle;

  /// No description provided for @constellationEmptyBody.
  ///
  /// In ko, this message translates to:
  /// **'메모가 쌓이면 서로 이어져 밤하늘이 생겨'**
  String get constellationEmptyBody;

  /// No description provided for @constellationConnected.
  ///
  /// In ko, this message translates to:
  /// **'이어진 순간 {count}'**
  String constellationConnected(int count);

  /// No description provided for @constellationWhenPast.
  ///
  /// In ko, this message translates to:
  /// **'그때'**
  String get constellationWhenPast;

  /// No description provided for @constellationWhenNow.
  ///
  /// In ko, this message translates to:
  /// **'지금'**
  String get constellationWhenNow;

  /// No description provided for @constellationRelExtends.
  ///
  /// In ko, this message translates to:
  /// **'확장'**
  String get constellationRelExtends;

  /// No description provided for @constellationRelReverses.
  ///
  /// In ko, this message translates to:
  /// **'달라짐'**
  String get constellationRelReverses;

  /// No description provided for @constellationRelEcho.
  ///
  /// In ko, this message translates to:
  /// **'다시 떠오름'**
  String get constellationRelEcho;

  /// No description provided for @constellationRelSimilar.
  ///
  /// In ko, this message translates to:
  /// **'닮음'**
  String get constellationRelSimilar;

  /// No description provided for @constellationRelDefault.
  ///
  /// In ko, this message translates to:
  /// **'연결'**
  String get constellationRelDefault;

  /// No description provided for @constellationRevealTitle.
  ///
  /// In ko, this message translates to:
  /// **'선이 하나 그어졌어'**
  String get constellationRevealTitle;

  /// No description provided for @constellationViewInConstellation.
  ///
  /// In ko, this message translates to:
  /// **'별자리에서 보기'**
  String get constellationViewInConstellation;

  /// No description provided for @lyraQuestionLabel.
  ///
  /// In ko, this message translates to:
  /// **'Lyra의 물음'**
  String get lyraQuestionLabel;

  /// No description provided for @lyraAnswerCta.
  ///
  /// In ko, this message translates to:
  /// **'이 물음에 메모 남기기'**
  String get lyraAnswerCta;

  /// No description provided for @orbTierNebulaSmall.
  ///
  /// In ko, this message translates to:
  /// **'작은 성운'**
  String get orbTierNebulaSmall;

  /// No description provided for @orbTierStarCluster.
  ///
  /// In ko, this message translates to:
  /// **'별무리'**
  String get orbTierStarCluster;

  /// No description provided for @orbTierConstellation.
  ///
  /// In ko, this message translates to:
  /// **'별자리'**
  String get orbTierConstellation;

  /// No description provided for @orbTierCluster.
  ///
  /// In ko, this message translates to:
  /// **'성단'**
  String get orbTierCluster;

  /// No description provided for @orbTierGalaxy.
  ///
  /// In ko, this message translates to:
  /// **'은하'**
  String get orbTierGalaxy;

  /// No description provided for @orbTierSuperGalaxy.
  ///
  /// In ko, this message translates to:
  /// **'대은하'**
  String get orbTierSuperGalaxy;

  /// No description provided for @orbMyUniverseTitle.
  ///
  /// In ko, this message translates to:
  /// **'내 우주'**
  String get orbMyUniverseTitle;

  /// No description provided for @orbNowPrefix.
  ///
  /// In ko, this message translates to:
  /// **'지금은 '**
  String get orbNowPrefix;

  /// No description provided for @orbTierBadge.
  ///
  /// In ko, this message translates to:
  /// **'{name} 단계'**
  String orbTierBadge(String name);

  /// No description provided for @orbToNextTier.
  ///
  /// In ko, this message translates to:
  /// **'다음 단계 {next}까지 '**
  String orbToNextTier(String next);

  /// No description provided for @orbDeepestReached.
  ///
  /// In ko, this message translates to:
  /// **'가장 깊은 우주에 도달'**
  String get orbDeepestReached;

  /// No description provided for @orbShareLinkCopied.
  ///
  /// In ko, this message translates to:
  /// **'공유하기 링크가 복사되었어요'**
  String get orbShareLinkCopied;

  /// No description provided for @orbShareError.
  ///
  /// In ko, this message translates to:
  /// **'공유 준비 중 문제가 생겼어요. 잠시 후 다시 시도해요'**
  String get orbShareError;

  /// No description provided for @orbGateBannerTitle.
  ///
  /// In ko, this message translates to:
  /// **'첫 오브를 만들어보세요'**
  String get orbGateBannerTitle;

  /// No description provided for @orbGateBannerBody.
  ///
  /// In ko, this message translates to:
  /// **'메모 {count}개면 은하수가 생겨'**
  String orbGateBannerBody(int count);

  /// No description provided for @orbGateSheetTitle.
  ///
  /// In ko, this message translates to:
  /// **'오브가 {count}개 남았어요'**
  String orbGateSheetTitle(int count);

  /// No description provided for @orbGateSheetBody.
  ///
  /// In ko, this message translates to:
  /// **'메모를 {count}개 더 남기면\n나만의 은하수 오브가 완성돼요'**
  String orbGateSheetBody(int count);

  /// No description provided for @orbGateWriteCta.
  ///
  /// In ko, this message translates to:
  /// **'지금 메모 쓰기'**
  String get orbGateWriteCta;

  /// No description provided for @shareCardDefaultNick.
  ///
  /// In ko, this message translates to:
  /// **'나'**
  String get shareCardDefaultNick;

  /// No description provided for @shareCardOwnerUniverse.
  ///
  /// In ko, this message translates to:
  /// **'{nick}의 우주'**
  String shareCardOwnerUniverse(String nick);

  /// No description provided for @shareCardTagline.
  ///
  /// In ko, this message translates to:
  /// **'너의 우주는 어떤 모양일까'**
  String get shareCardTagline;

  /// No description provided for @shareCardStoreHint.
  ///
  /// In ko, this message translates to:
  /// **'App Store / Google Play 에 milkyway'**
  String get shareCardStoreHint;

  /// No description provided for @wrappedTitle.
  ///
  /// In ko, this message translates to:
  /// **'은하 회고'**
  String get wrappedTitle;

  /// No description provided for @wrappedHeroLead.
  ///
  /// In ko, this message translates to:
  /// **'{month}, 네가'**
  String wrappedHeroLead(String month);

  /// No description provided for @wrappedHeroAccent.
  ///
  /// In ko, this message translates to:
  /// **'멈춘 순간들'**
  String get wrappedHeroAccent;

  /// No description provided for @wrappedStarsLeft.
  ///
  /// In ko, this message translates to:
  /// **'그 자리에 남은 {count}개의 별'**
  String wrappedStarsLeft(int count);

  /// No description provided for @wrappedStatSentences.
  ///
  /// In ko, this message translates to:
  /// **'멈춘 문장'**
  String get wrappedStatSentences;

  /// No description provided for @wrappedStatReadDays.
  ///
  /// In ko, this message translates to:
  /// **'읽은 날'**
  String get wrappedStatReadDays;

  /// No description provided for @wrappedTopBookLabel.
  ///
  /// In ko, this message translates to:
  /// **'가장 오래 머문 책'**
  String get wrappedTopBookLabel;

  /// No description provided for @wrappedQuoteLabel.
  ///
  /// In ko, this message translates to:
  /// **'그 달의 문장'**
  String get wrappedQuoteLabel;

  /// No description provided for @wrappedQuoteSource.
  ///
  /// In ko, this message translates to:
  /// **'{title}에서'**
  String wrappedQuoteSource(String title);

  /// No description provided for @wrappedShareCta.
  ///
  /// In ko, this message translates to:
  /// **'회고 공유하기'**
  String get wrappedShareCta;

  /// No description provided for @wrappedEmptyTitle.
  ///
  /// In ko, this message translates to:
  /// **'이번 달 회고는 아직 준비 중이에요'**
  String get wrappedEmptyTitle;

  /// No description provided for @wrappedEmptyBody.
  ///
  /// In ko, this message translates to:
  /// **'메모를 남기면 그 자리에 별이 쌓여요'**
  String get wrappedEmptyBody;

  /// No description provided for @wrappedLoadErrorTitle.
  ///
  /// In ko, this message translates to:
  /// **'회고를 불러오지 못했어요'**
  String get wrappedLoadErrorTitle;

  /// No description provided for @wrappedLoadErrorBody.
  ///
  /// In ko, this message translates to:
  /// **'잠시 후 다시 시도해요'**
  String get wrappedLoadErrorBody;

  /// No description provided for @wrappedShareLinkCopied.
  ///
  /// In ko, this message translates to:
  /// **'공유하기 링크가 복사되었어요'**
  String get wrappedShareLinkCopied;

  /// No description provided for @wrappedShareError.
  ///
  /// In ko, this message translates to:
  /// **'공유 준비 중 문제가 생겼어요. 잠시 후 다시 시도해요'**
  String get wrappedShareError;

  /// No description provided for @commonShare.
  ///
  /// In ko, this message translates to:
  /// **'공유하기'**
  String get commonShare;

  /// No description provided for @orbLoadErrorTitle.
  ///
  /// In ko, this message translates to:
  /// **'우주를 불러오지 못했어요'**
  String get orbLoadErrorTitle;

  /// No description provided for @wrappedEntryTitle.
  ///
  /// In ko, this message translates to:
  /// **'{month} 은하 회고'**
  String wrappedEntryTitle(String month);

  /// No description provided for @wrappedEntryBody.
  ///
  /// In ko, this message translates to:
  /// **'그 자리에 남은 별 {count}개'**
  String wrappedEntryBody(int count);

  /// No description provided for @authSignInApple.
  ///
  /// In ko, this message translates to:
  /// **'Apple로 시작하기'**
  String get authSignInApple;

  /// No description provided for @authSignInGoogle.
  ///
  /// In ko, this message translates to:
  /// **'Google로 시작하기'**
  String get authSignInGoogle;

  /// No description provided for @authSignInFailed.
  ///
  /// In ko, this message translates to:
  /// **'로그인에 실패했습니다. 다시 시도해 주세요'**
  String get authSignInFailed;

  /// No description provided for @authNotificationPermissionTitle.
  ///
  /// In ko, this message translates to:
  /// **'알림 권한'**
  String get authNotificationPermissionTitle;

  /// No description provided for @authNotificationPermissionBody.
  ///
  /// In ko, this message translates to:
  /// **'내가 읽고 있는 책에 새로운 메모가 등록되면 알려드려요'**
  String get authNotificationPermissionBody;

  /// No description provided for @authNotificationPermissionLater.
  ///
  /// In ko, this message translates to:
  /// **'나중에'**
  String get authNotificationPermissionLater;

  /// No description provided for @authNotificationPermissionAllow.
  ///
  /// In ko, this message translates to:
  /// **'허용'**
  String get authNotificationPermissionAllow;

  /// No description provided for @splashUpdateTitle.
  ///
  /// In ko, this message translates to:
  /// **'업데이트 필요'**
  String get splashUpdateTitle;

  /// No description provided for @splashUpdateBody.
  ///
  /// In ko, this message translates to:
  /// **'새로운 버전이 있습니다.\n원활한 사용을 위해 업데이트를 진행해주세요'**
  String get splashUpdateBody;

  /// No description provided for @splashUpdateAction.
  ///
  /// In ko, this message translates to:
  /// **'업데이트'**
  String get splashUpdateAction;

  /// No description provided for @onboardingSkip.
  ///
  /// In ko, this message translates to:
  /// **'건너뛰기'**
  String get onboardingSkip;

  /// No description provided for @onboardingNicknameTitle.
  ///
  /// In ko, this message translates to:
  /// **'닉네임 설정'**
  String get onboardingNicknameTitle;

  /// No description provided for @onboardingNicknameHeading.
  ///
  /// In ko, this message translates to:
  /// **'닉네임을 설정해주세요'**
  String get onboardingNicknameHeading;

  /// No description provided for @onboardingNicknameSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'밀키웨이의 다른 유저가 볼 수 있는 이름이에요'**
  String get onboardingNicknameSubtitle;

  /// No description provided for @onboardingNicknameLabel.
  ///
  /// In ko, this message translates to:
  /// **'닉네임'**
  String get onboardingNicknameLabel;

  /// No description provided for @onboardingNicknameHint.
  ///
  /// In ko, this message translates to:
  /// **'닉네임을 입력하세요'**
  String get onboardingNicknameHint;

  /// No description provided for @onboardingNicknameChecking.
  ///
  /// In ko, this message translates to:
  /// **'확인 중...'**
  String get onboardingNicknameChecking;

  /// No description provided for @onboardingNicknameHelp.
  ///
  /// In ko, this message translates to:
  /// **'2 - 20자, 특수문자 사용 불가'**
  String get onboardingNicknameHelp;

  /// No description provided for @onboardingNicknameErrorTooShort.
  ///
  /// In ko, this message translates to:
  /// **'닉네임은 최소 2자 이상이어야 합니다'**
  String get onboardingNicknameErrorTooShort;

  /// No description provided for @onboardingNicknameErrorTooLong.
  ///
  /// In ko, this message translates to:
  /// **'닉네임은 최대 20자까지 입력 가능합니다'**
  String get onboardingNicknameErrorTooLong;

  /// No description provided for @onboardingNicknameErrorSpecialChars.
  ///
  /// In ko, this message translates to:
  /// **'특수문자는 사용할 수 없습니다'**
  String get onboardingNicknameErrorSpecialChars;

  /// No description provided for @onboardingNicknameErrorTaken.
  ///
  /// In ko, this message translates to:
  /// **'이미 사용 중인 닉네임입니다'**
  String get onboardingNicknameErrorTaken;

  /// No description provided for @onboardingNicknameErrorCheckFailed.
  ///
  /// In ko, this message translates to:
  /// **'닉네임 확인 중 오류가 발생했습니다'**
  String get onboardingNicknameErrorCheckFailed;

  /// No description provided for @onboardingNicknameSaveError.
  ///
  /// In ko, this message translates to:
  /// **'닉네임 설정 중 오류가 발생했습니다: {error}'**
  String onboardingNicknameSaveError(String error);

  /// No description provided for @onboardingProfileImageTitle.
  ///
  /// In ko, this message translates to:
  /// **'프로필 사진'**
  String get onboardingProfileImageTitle;

  /// No description provided for @onboardingProfileImageHeading.
  ///
  /// In ko, this message translates to:
  /// **'프로필 사진을 설정해주세요'**
  String get onboardingProfileImageHeading;

  /// No description provided for @onboardingProfileImageSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'나중에 언제든지 변경할 수 있어요'**
  String get onboardingProfileImageSubtitle;

  /// No description provided for @onboardingProfileImageDescription.
  ///
  /// In ko, this message translates to:
  /// **'등록된 프로필 사진은\n남겨주신 메모와 함께 보여져요'**
  String get onboardingProfileImageDescription;

  /// No description provided for @onboardingProfileImageNote.
  ///
  /// In ko, this message translates to:
  /// **'공개 설정한 메모만 보여지니 걱정마세요'**
  String get onboardingProfileImageNote;

  /// No description provided for @onboardingGenreTitle.
  ///
  /// In ko, this message translates to:
  /// **'취향'**
  String get onboardingGenreTitle;

  /// No description provided for @onboardingGenreHeading.
  ///
  /// In ko, this message translates to:
  /// **'어떤 결의 책을\n좋아하나요'**
  String get onboardingGenreHeading;

  /// No description provided for @onboardingGenreSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'취향을 알려주면 첫 책을 더 잘 골라드려요\n하나 이상 골라주세요'**
  String get onboardingGenreSubtitle;

  /// No description provided for @onboardingGenreNextCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}개 고르고 다음'**
  String onboardingGenreNextCount(int count);

  /// No description provided for @onboardingGenreSelectAtLeastOne.
  ///
  /// In ko, this message translates to:
  /// **'한 개 이상 골라주세요'**
  String get onboardingGenreSelectAtLeastOne;

  /// No description provided for @onboardingGenreNovel.
  ///
  /// In ko, this message translates to:
  /// **'소설'**
  String get onboardingGenreNovel;

  /// No description provided for @onboardingGenrePoetry.
  ///
  /// In ko, this message translates to:
  /// **'시'**
  String get onboardingGenrePoetry;

  /// No description provided for @onboardingGenreEssay.
  ///
  /// In ko, this message translates to:
  /// **'에세이'**
  String get onboardingGenreEssay;

  /// No description provided for @onboardingGenreHumanities.
  ///
  /// In ko, this message translates to:
  /// **'인문'**
  String get onboardingGenreHumanities;

  /// No description provided for @onboardingGenrePhilosophy.
  ///
  /// In ko, this message translates to:
  /// **'철학'**
  String get onboardingGenrePhilosophy;

  /// No description provided for @onboardingGenreScience.
  ///
  /// In ko, this message translates to:
  /// **'과학'**
  String get onboardingGenreScience;

  /// No description provided for @onboardingGenreSciFi.
  ///
  /// In ko, this message translates to:
  /// **'SF'**
  String get onboardingGenreSciFi;

  /// No description provided for @onboardingGenreHistory.
  ///
  /// In ko, this message translates to:
  /// **'역사'**
  String get onboardingGenreHistory;

  /// No description provided for @onboardingGenreArt.
  ///
  /// In ko, this message translates to:
  /// **'예술'**
  String get onboardingGenreArt;

  /// No description provided for @onboardingGenrePsychology.
  ///
  /// In ko, this message translates to:
  /// **'심리'**
  String get onboardingGenrePsychology;

  /// No description provided for @onboardingGenreBusiness.
  ///
  /// In ko, this message translates to:
  /// **'경제경영'**
  String get onboardingGenreBusiness;

  /// No description provided for @onboardingGenreSelfHelp.
  ///
  /// In ko, this message translates to:
  /// **'자기계발'**
  String get onboardingGenreSelfHelp;

  /// No description provided for @onboardingBookIntroTitle.
  ///
  /// In ko, this message translates to:
  /// **'시작하기'**
  String get onboardingBookIntroTitle;

  /// No description provided for @onboardingBookIntroDescription.
  ///
  /// In ko, this message translates to:
  /// **'이제 책을 읽으며\n떠오른 반짝이는 생각을\n메모하고 저장해요 ✨'**
  String get onboardingBookIntroDescription;

  /// No description provided for @onboardingBookIntroStart.
  ///
  /// In ko, this message translates to:
  /// **'책 검색하고 시작하기'**
  String get onboardingBookIntroStart;

  /// No description provided for @onboardingBookIntroSkip.
  ///
  /// In ko, this message translates to:
  /// **'다음에 하기'**
  String get onboardingBookIntroSkip;

  /// No description provided for @bookStatusWantToRead.
  ///
  /// In ko, this message translates to:
  /// **'읽고 싶은'**
  String get bookStatusWantToRead;

  /// No description provided for @bookStatusReading.
  ///
  /// In ko, this message translates to:
  /// **'읽는 중'**
  String get bookStatusReading;

  /// No description provided for @bookStatusCompleted.
  ///
  /// In ko, this message translates to:
  /// **'완독'**
  String get bookStatusCompleted;

  /// No description provided for @bookFilterAll.
  ///
  /// In ko, this message translates to:
  /// **'모든 책'**
  String get bookFilterAll;

  /// No description provided for @bookShelfLoadError.
  ///
  /// In ko, this message translates to:
  /// **'책을 불러오지 못했어'**
  String get bookShelfLoadError;

  /// No description provided for @bookShelfEmpty.
  ///
  /// In ko, this message translates to:
  /// **'새로운 책을 추가해주세요'**
  String get bookShelfEmpty;

  /// No description provided for @bookDetailTitle.
  ///
  /// In ko, this message translates to:
  /// **'책 상세페이지'**
  String get bookDetailTitle;

  /// No description provided for @bookActionDelete.
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get bookActionDelete;

  /// No description provided for @bookDescriptionTitle.
  ///
  /// In ko, this message translates to:
  /// **'책 소개'**
  String get bookDescriptionTitle;

  /// No description provided for @bookShowMore.
  ///
  /// In ko, this message translates to:
  /// **'더보기'**
  String get bookShowMore;

  /// No description provided for @bookMemosTitle.
  ///
  /// In ko, this message translates to:
  /// **'이 책의 메모'**
  String get bookMemosTitle;

  /// No description provided for @bookMemoSegmentTogether.
  ///
  /// In ko, this message translates to:
  /// **'함께'**
  String get bookMemoSegmentTogether;

  /// No description provided for @bookMemoSegmentMine.
  ///
  /// In ko, this message translates to:
  /// **'내 메모'**
  String get bookMemoSegmentMine;

  /// No description provided for @bookMemosLoadError.
  ///
  /// In ko, this message translates to:
  /// **'메모를 불러오지 못했어요'**
  String get bookMemosLoadError;

  /// No description provided for @bookMemosEmptyPublic.
  ///
  /// In ko, this message translates to:
  /// **'아직 공개된 메모가 없어요'**
  String get bookMemosEmptyPublic;

  /// No description provided for @bookMemosEmptyMine.
  ///
  /// In ko, this message translates to:
  /// **'아직 남긴 메모가 없어요'**
  String get bookMemosEmptyMine;

  /// No description provided for @bookMemoDefaultAuthor.
  ///
  /// In ko, this message translates to:
  /// **'밀키웨이'**
  String get bookMemoDefaultAuthor;

  /// No description provided for @bookTimeJustNow.
  ///
  /// In ko, this message translates to:
  /// **'방금'**
  String get bookTimeJustNow;

  /// No description provided for @bookTimeMinutesAgo.
  ///
  /// In ko, this message translates to:
  /// **'{count}분 전'**
  String bookTimeMinutesAgo(int count);

  /// No description provided for @bookTimeHoursAgo.
  ///
  /// In ko, this message translates to:
  /// **'{count}시간 전'**
  String bookTimeHoursAgo(int count);

  /// No description provided for @bookTimeDaysAgo.
  ///
  /// In ko, this message translates to:
  /// **'{count}일 전'**
  String bookTimeDaysAgo(int count);

  /// No description provided for @bookWriteMemoCta.
  ///
  /// In ko, this message translates to:
  /// **'메모하기'**
  String get bookWriteMemoCta;

  /// No description provided for @bookDetailLoadError.
  ///
  /// In ko, this message translates to:
  /// **'책 정보를 불러오지 못했어요'**
  String get bookDetailLoadError;

  /// No description provided for @bookStatusChanged.
  ///
  /// In ko, this message translates to:
  /// **'{status} 상태로 바꿨어요'**
  String bookStatusChanged(String status);

  /// No description provided for @bookDeleteTitle.
  ///
  /// In ko, this message translates to:
  /// **'책 삭제'**
  String get bookDeleteTitle;

  /// No description provided for @bookDeleteBody.
  ///
  /// In ko, this message translates to:
  /// **'책을 삭제하면 그 책의 메모도 모두 삭제되고 되돌릴 수 없어요.\n\n정말 삭제할까요?'**
  String get bookDeleteBody;

  /// No description provided for @bookSearchTitle.
  ///
  /// In ko, this message translates to:
  /// **'책 검색'**
  String get bookSearchTitle;

  /// No description provided for @bookSearchHint.
  ///
  /// In ko, this message translates to:
  /// **'책 제목, 저자, ISBN으로 검색하세요'**
  String get bookSearchHint;

  /// No description provided for @bookSearchError.
  ///
  /// In ko, this message translates to:
  /// **'검색 중 오류가 발생했어요'**
  String get bookSearchError;

  /// No description provided for @bookSearchEmptyTitle.
  ///
  /// In ko, this message translates to:
  /// **'검색 결과가 없어요'**
  String get bookSearchEmptyTitle;

  /// No description provided for @bookSearchEmptyBody.
  ///
  /// In ko, this message translates to:
  /// **'다른 키워드로 검색해보세요'**
  String get bookSearchEmptyBody;

  /// No description provided for @bookAlreadyAdded.
  ///
  /// In ko, this message translates to:
  /// **'이미 등록된 책이에요'**
  String get bookAlreadyAdded;

  /// No description provided for @bookAdded.
  ///
  /// In ko, this message translates to:
  /// **'책을 등록했어요'**
  String get bookAdded;

  /// No description provided for @bookAddedNew.
  ///
  /// In ko, this message translates to:
  /// **'새 책을 등록했어요'**
  String get bookAddedNew;

  /// No description provided for @bookAddFailed.
  ///
  /// In ko, this message translates to:
  /// **'책 등록에 실패했어요'**
  String get bookAddFailed;

  /// No description provided for @bookOpStatusChange.
  ///
  /// In ko, this message translates to:
  /// **'책 상태 변경'**
  String get bookOpStatusChange;

  /// No description provided for @bookOpDelete.
  ///
  /// In ko, this message translates to:
  /// **'책 삭제'**
  String get bookOpDelete;

  /// No description provided for @bookOpRegister.
  ///
  /// In ko, this message translates to:
  /// **'책 등록'**
  String get bookOpRegister;

  /// No description provided for @bookOpConnect.
  ///
  /// In ko, this message translates to:
  /// **'책 연결'**
  String get bookOpConnect;

  /// No description provided for @readingLogTodayCta.
  ///
  /// In ko, this message translates to:
  /// **'오늘 읽음'**
  String get readingLogTodayCta;

  /// No description provided for @readingLoggedToday.
  ///
  /// In ko, this message translates to:
  /// **'오늘 읽었어요'**
  String get readingLoggedToday;

  /// No description provided for @calendarTitle.
  ///
  /// In ko, this message translates to:
  /// **'기록'**
  String get calendarTitle;

  /// No description provided for @calendarSegmentMemos.
  ///
  /// In ko, this message translates to:
  /// **'메모'**
  String get calendarSegmentMemos;

  /// No description provided for @calendarSegmentRead.
  ///
  /// In ko, this message translates to:
  /// **'읽음'**
  String get calendarSegmentRead;

  /// No description provided for @calendarEmptyMemos.
  ///
  /// In ko, this message translates to:
  /// **'이 날 남긴 메모가 없어요'**
  String get calendarEmptyMemos;

  /// No description provided for @calendarEmptyBooks.
  ///
  /// In ko, this message translates to:
  /// **'이 날 읽은 책이 없어요'**
  String get calendarEmptyBooks;

  /// No description provided for @commentAnonymousAuthor.
  ///
  /// In ko, this message translates to:
  /// **'밀키웨이'**
  String get commentAnonymousAuthor;

  /// No description provided for @commentMineTag.
  ///
  /// In ko, this message translates to:
  /// **'나'**
  String get commentMineTag;

  /// No description provided for @commentEdit.
  ///
  /// In ko, this message translates to:
  /// **'수정하기'**
  String get commentEdit;

  /// No description provided for @commentDelete.
  ///
  /// In ko, this message translates to:
  /// **'삭제하기'**
  String get commentDelete;

  /// No description provided for @commentHide.
  ///
  /// In ko, this message translates to:
  /// **'이 댓글 숨기기'**
  String get commentHide;

  /// No description provided for @commentReport.
  ///
  /// In ko, this message translates to:
  /// **'신고하기'**
  String get commentReport;

  /// No description provided for @commentComposerLocked.
  ///
  /// In ko, this message translates to:
  /// **'책을 담으면 댓글을 남길 수 있어'**
  String get commentComposerLocked;

  /// No description provided for @commentComposerEditHint.
  ///
  /// In ko, this message translates to:
  /// **'댓글 수정'**
  String get commentComposerEditHint;

  /// No description provided for @commentComposerHint.
  ///
  /// In ko, this message translates to:
  /// **'댓글 남기기'**
  String get commentComposerHint;

  /// No description provided for @commentSendError.
  ///
  /// In ko, this message translates to:
  /// **'댓글을 못 남겼어'**
  String get commentSendError;

  /// No description provided for @commentDeleteTitle.
  ///
  /// In ko, this message translates to:
  /// **'댓글 삭제'**
  String get commentDeleteTitle;

  /// No description provided for @commentDeleteMessage.
  ///
  /// In ko, this message translates to:
  /// **'이 댓글을 지울까'**
  String get commentDeleteMessage;

  /// No description provided for @commentDeleteConfirm.
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get commentDeleteConfirm;

  /// No description provided for @commentDeleteError.
  ///
  /// In ko, this message translates to:
  /// **'못 지웠어'**
  String get commentDeleteError;

  /// No description provided for @commentHideError.
  ///
  /// In ko, this message translates to:
  /// **'못 숨겼어'**
  String get commentHideError;

  /// No description provided for @commentReportReasonTitle.
  ///
  /// In ko, this message translates to:
  /// **'신고 사유'**
  String get commentReportReasonTitle;

  /// No description provided for @commentReportSpam.
  ///
  /// In ko, this message translates to:
  /// **'스팸/도배'**
  String get commentReportSpam;

  /// No description provided for @commentReportInappropriate.
  ///
  /// In ko, this message translates to:
  /// **'부적절한 내용'**
  String get commentReportInappropriate;

  /// No description provided for @commentReportHarassment.
  ///
  /// In ko, this message translates to:
  /// **'괴롭힘/혐오'**
  String get commentReportHarassment;

  /// No description provided for @commentReportSexual.
  ///
  /// In ko, this message translates to:
  /// **'선정적'**
  String get commentReportSexual;

  /// No description provided for @commentReportOther.
  ///
  /// In ko, this message translates to:
  /// **'기타'**
  String get commentReportOther;

  /// No description provided for @commentReportDone.
  ///
  /// In ko, this message translates to:
  /// **'신고했어. 이 댓글은 이제 안 보여'**
  String get commentReportDone;

  /// No description provided for @commentReportError.
  ///
  /// In ko, this message translates to:
  /// **'신고하지 못했어'**
  String get commentReportError;

  /// No description provided for @commentSaveBookTitle.
  ///
  /// In ko, this message translates to:
  /// **'책 담기'**
  String get commentSaveBookTitle;

  /// No description provided for @commentSaveBookMessage.
  ///
  /// In ko, this message translates to:
  /// **'이 책을 담아야 댓글을 남길 수 있어. 담을까'**
  String get commentSaveBookMessage;

  /// No description provided for @commentSaveBookConfirm.
  ///
  /// In ko, this message translates to:
  /// **'담기'**
  String get commentSaveBookConfirm;

  /// No description provided for @commentSaveBookError.
  ///
  /// In ko, this message translates to:
  /// **'책을 못 담았어'**
  String get commentSaveBookError;

  /// No description provided for @commentLoadError.
  ///
  /// In ko, this message translates to:
  /// **'댓글을 못 불러왔어'**
  String get commentLoadError;

  /// No description provided for @commentSectionTitle.
  ///
  /// In ko, this message translates to:
  /// **'댓글'**
  String get commentSectionTitle;

  /// No description provided for @commentSectionTitleCount.
  ///
  /// In ko, this message translates to:
  /// **'댓글 {count}'**
  String commentSectionTitleCount(int count);

  /// No description provided for @commentEmpty.
  ///
  /// In ko, this message translates to:
  /// **'첫 댓글을 남겨봐'**
  String get commentEmpty;

  /// No description provided for @shareLandingCta.
  ///
  /// In ko, this message translates to:
  /// **'나도 내 우주를 만들 수 있어요'**
  String get shareLandingCta;

  /// No description provided for @shareLandingCtaButton.
  ///
  /// In ko, this message translates to:
  /// **'나도 만들기'**
  String get shareLandingCtaButton;

  /// No description provided for @shareLandingErrorTitle.
  ///
  /// In ko, this message translates to:
  /// **'카드를 불러오지 못했어요'**
  String get shareLandingErrorTitle;

  /// No description provided for @shareLandingErrorBody.
  ///
  /// In ko, this message translates to:
  /// **'링크가 만료되었거나 삭제된 카드일 수 있어요'**
  String get shareLandingErrorBody;

  /// No description provided for @shareLandingGoHome.
  ///
  /// In ko, this message translates to:
  /// **'홈으로'**
  String get shareLandingGoHome;

  /// No description provided for @commonEdited.
  ///
  /// In ko, this message translates to:
  /// **'수정됨'**
  String get commonEdited;

  /// No description provided for @commonMyMemo.
  ///
  /// In ko, this message translates to:
  /// **'내 메모'**
  String get commonMyMemo;

  /// No description provided for @commonPageLabel.
  ///
  /// In ko, this message translates to:
  /// **'{page}쪽'**
  String commonPageLabel(int page);

  /// No description provided for @commonLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'불러오지 못했어'**
  String get commonLoadFailed;

  /// No description provided for @commonComposeHint.
  ///
  /// In ko, this message translates to:
  /// **'오늘 읽은 문장을 남겨보세요'**
  String get commonComposeHint;

  /// No description provided for @commonTimeJustNow.
  ///
  /// In ko, this message translates to:
  /// **'방금'**
  String get commonTimeJustNow;

  /// No description provided for @commonTimeMinutesAgo.
  ///
  /// In ko, this message translates to:
  /// **'{minutes}분 전'**
  String commonTimeMinutesAgo(int minutes);

  /// No description provided for @commonTimeHoursAgo.
  ///
  /// In ko, this message translates to:
  /// **'{hours}시간 전'**
  String commonTimeHoursAgo(int hours);

  /// No description provided for @commonTimeDaysAgo.
  ///
  /// In ko, this message translates to:
  /// **'{days}일 전'**
  String commonTimeDaysAgo(int days);

  /// No description provided for @commonNavHome.
  ///
  /// In ko, this message translates to:
  /// **'홈'**
  String get commonNavHome;

  /// No description provided for @commonNavBooks.
  ///
  /// In ko, this message translates to:
  /// **'책 목록'**
  String get commonNavBooks;

  /// No description provided for @commonNavMemos.
  ///
  /// In ko, this message translates to:
  /// **'메모'**
  String get commonNavMemos;

  /// No description provided for @commonNavProfile.
  ///
  /// In ko, this message translates to:
  /// **'프로필'**
  String get commonNavProfile;

  /// No description provided for @commonEmptyBookTitle.
  ///
  /// In ko, this message translates to:
  /// **'새로운 책을 골라주세요 👇'**
  String get commonEmptyBookTitle;

  /// No description provided for @commonEmptyBookCta.
  ///
  /// In ko, this message translates to:
  /// **'어떤 책을 읽고 싶나요? 🤔'**
  String get commonEmptyBookCta;

  /// No description provided for @homeSaveBookTitle.
  ///
  /// In ko, this message translates to:
  /// **'책 담기'**
  String get homeSaveBookTitle;

  /// No description provided for @homeSaveBookMessage.
  ///
  /// In ko, this message translates to:
  /// **'이 책을 서재에 담을까'**
  String get homeSaveBookMessage;

  /// No description provided for @homeSaveAction.
  ///
  /// In ko, this message translates to:
  /// **'담기'**
  String get homeSaveAction;

  /// No description provided for @homeSaveBookError.
  ///
  /// In ko, this message translates to:
  /// **'책을 담는 중 문제가 생겼어요'**
  String get homeSaveBookError;

  /// No description provided for @homeSectionOtherThoughts.
  ///
  /// In ko, this message translates to:
  /// **'다른 별들이 남긴 생각들'**
  String get homeSectionOtherThoughts;

  /// No description provided for @homeDefaultAuthor.
  ///
  /// In ko, this message translates to:
  /// **'밀키웨이'**
  String get homeDefaultAuthor;

  /// No description provided for @homeSectionRecentMemoBooks.
  ///
  /// In ko, this message translates to:
  /// **'최근 메모가 올라온 책'**
  String get homeSectionRecentMemoBooks;

  /// No description provided for @homeMemoMeta.
  ///
  /// In ko, this message translates to:
  /// **'{time} 메모'**
  String homeMemoMeta(String time);

  /// No description provided for @homeReadPromptTitle.
  ///
  /// In ko, this message translates to:
  /// **'오늘은 어떤 책을 읽을까'**
  String get homeReadPromptTitle;

  /// No description provided for @homeReadPromptBody.
  ///
  /// In ko, this message translates to:
  /// **'내 서재에서 골라보세요'**
  String get homeReadPromptBody;

  /// No description provided for @homeOrbTitle.
  ///
  /// In ko, this message translates to:
  /// **'내 우주가 자라고 있어요'**
  String get homeOrbTitle;

  /// No description provided for @homeOrbBody.
  ///
  /// In ko, this message translates to:
  /// **'내 은하수를 확인하고 공유해요'**
  String get homeOrbBody;

  /// No description provided for @homeConstellationTitle.
  ///
  /// In ko, this message translates to:
  /// **'내 생각들이 이어지고 있어요'**
  String get homeConstellationTitle;

  /// No description provided for @homeConstellationBody.
  ///
  /// In ko, this message translates to:
  /// **'메모 사이에 생긴 별자리를 살펴봐요'**
  String get homeConstellationBody;

  /// No description provided for @homeWeekdayMon.
  ///
  /// In ko, this message translates to:
  /// **'월'**
  String get homeWeekdayMon;

  /// No description provided for @homeWeekdayTue.
  ///
  /// In ko, this message translates to:
  /// **'화'**
  String get homeWeekdayTue;

  /// No description provided for @homeWeekdayWed.
  ///
  /// In ko, this message translates to:
  /// **'수'**
  String get homeWeekdayWed;

  /// No description provided for @homeWeekdayThu.
  ///
  /// In ko, this message translates to:
  /// **'목'**
  String get homeWeekdayThu;

  /// No description provided for @homeWeekdayFri.
  ///
  /// In ko, this message translates to:
  /// **'금'**
  String get homeWeekdayFri;

  /// No description provided for @homeWeekdaySat.
  ///
  /// In ko, this message translates to:
  /// **'토'**
  String get homeWeekdaySat;

  /// No description provided for @homeWeekdaySun.
  ///
  /// In ko, this message translates to:
  /// **'일'**
  String get homeWeekdaySun;

  /// No description provided for @homeRecordTitle.
  ///
  /// In ko, this message translates to:
  /// **'내 기록'**
  String get homeRecordTitle;

  /// No description provided for @homeViewAll.
  ///
  /// In ko, this message translates to:
  /// **'전체 보기'**
  String get homeViewAll;

  /// No description provided for @homeTimeJustNow.
  ///
  /// In ko, this message translates to:
  /// **'방금'**
  String get homeTimeJustNow;

  /// No description provided for @homeTimeMinutesAgo.
  ///
  /// In ko, this message translates to:
  /// **'{count}분 전'**
  String homeTimeMinutesAgo(int count);

  /// No description provided for @homeTimeHoursAgo.
  ///
  /// In ko, this message translates to:
  /// **'{count}시간 전'**
  String homeTimeHoursAgo(int count);

  /// No description provided for @homeTimeDaysAgo.
  ///
  /// In ko, this message translates to:
  /// **'{count}일 전'**
  String homeTimeDaysAgo(int count);

  /// No description provided for @homeWelcomeTitle.
  ///
  /// In ko, this message translates to:
  /// **'마음이 가는 책 한 권부터'**
  String get homeWelcomeTitle;

  /// No description provided for @homeWelcomeBody.
  ///
  /// In ko, this message translates to:
  /// **'담으면 Lyra가 물음을 건네요\n아래 사람들이 담은 책도 둘러보세요'**
  String get homeWelcomeBody;

  /// No description provided for @homeWelcomeCta.
  ///
  /// In ko, this message translates to:
  /// **'책 담으러 가기'**
  String get homeWelcomeCta;

  /// No description provided for @homeStatusReading.
  ///
  /// In ko, this message translates to:
  /// **'읽는 중'**
  String get homeStatusReading;

  /// No description provided for @homeSectionSavedByOthers.
  ///
  /// In ko, this message translates to:
  /// **'다른 사람이 담은 책'**
  String get homeSectionSavedByOthers;

  /// No description provided for @homeAddBook.
  ///
  /// In ko, this message translates to:
  /// **'책 등록하기'**
  String get homeAddBook;

  /// No description provided for @homeAddMemo.
  ///
  /// In ko, this message translates to:
  /// **'메모 작성하기'**
  String get homeAddMemo;

  /// No description provided for @discoveryTitle.
  ///
  /// In ko, this message translates to:
  /// **'책 담기'**
  String get discoveryTitle;

  /// No description provided for @discoverySkip.
  ///
  /// In ko, this message translates to:
  /// **'다음에 담기'**
  String get discoverySkip;

  /// No description provided for @discoveryLoadError.
  ///
  /// In ko, this message translates to:
  /// **'추천을 불러오지 못했어요'**
  String get discoveryLoadError;

  /// No description provided for @discoveryEmpty.
  ///
  /// In ko, this message translates to:
  /// **'아직 추천할 책이 없어요'**
  String get discoveryEmpty;

  /// No description provided for @discoveryHeading.
  ///
  /// In ko, this message translates to:
  /// **'사람들이 메모를 남긴 책'**
  String get discoveryHeading;

  /// No description provided for @discoveryBody.
  ///
  /// In ko, this message translates to:
  /// **'마음이 가는 책을 담아보세요\n담은 책에 Lyra가 물음을 건네요'**
  String get discoveryBody;

  /// No description provided for @discoverySearchCta.
  ///
  /// In ko, this message translates to:
  /// **'찾는 책이 없다면 직접 검색'**
  String get discoverySearchCta;

  /// No description provided for @discoveryStartCta.
  ///
  /// In ko, this message translates to:
  /// **'{count}권 담고 시작하기'**
  String discoveryStartCta(int count);

  /// No description provided for @discoverySaveError.
  ///
  /// In ko, this message translates to:
  /// **'책을 담는 중 문제가 생겼어요'**
  String get discoverySaveError;

  /// No description provided for @discoveryProofSavers.
  ///
  /// In ko, this message translates to:
  /// **'{count}명이 담은 책'**
  String discoveryProofSavers(int count);

  /// No description provided for @discoveryProofMemos.
  ///
  /// In ko, this message translates to:
  /// **'메모 {count}개가 쌓인 책'**
  String discoveryProofMemos(int count);

  /// No description provided for @discoveryProofNew.
  ///
  /// In ko, this message translates to:
  /// **'방금 올라온 책'**
  String get discoveryProofNew;

  /// No description provided for @memoTitle.
  ///
  /// In ko, this message translates to:
  /// **'메모'**
  String get memoTitle;

  /// No description provided for @memoSelectBook.
  ///
  /// In ko, this message translates to:
  /// **'책 선택'**
  String get memoSelectBook;

  /// No description provided for @memoAnsweringLyra.
  ///
  /// In ko, this message translates to:
  /// **'Lyra의 물음에 답하는 중'**
  String get memoAnsweringLyra;

  /// No description provided for @memoContentHint.
  ///
  /// In ko, this message translates to:
  /// **'오늘 읽은 문장, 그 문장이 남긴 생각을 적어보세요'**
  String get memoContentHint;

  /// No description provided for @memoPageHint.
  ///
  /// In ko, this message translates to:
  /// **'쪽'**
  String get memoPageHint;

  /// No description provided for @memoVisibilityPublic.
  ///
  /// In ko, this message translates to:
  /// **'공개'**
  String get memoVisibilityPublic;

  /// No description provided for @memoVisibilityPrivateOnlyMe.
  ///
  /// In ko, this message translates to:
  /// **'나만 보기'**
  String get memoVisibilityPrivateOnlyMe;

  /// No description provided for @memoNoBooksYet.
  ///
  /// In ko, this message translates to:
  /// **'먼저 책을 담아주세요'**
  String get memoNoBooksYet;

  /// No description provided for @memoPickBookTitle.
  ///
  /// In ko, this message translates to:
  /// **'어떤 책의 메모인가요'**
  String get memoPickBookTitle;

  /// No description provided for @memoImagePickTitle.
  ///
  /// In ko, this message translates to:
  /// **'이미지 선택'**
  String get memoImagePickTitle;

  /// No description provided for @memoImageFromGallery.
  ///
  /// In ko, this message translates to:
  /// **'갤러리에서 선택'**
  String get memoImageFromGallery;

  /// No description provided for @memoImageFromCamera.
  ///
  /// In ko, this message translates to:
  /// **'카메라로 촬영'**
  String get memoImageFromCamera;

  /// No description provided for @memoSelectBookRequired.
  ///
  /// In ko, this message translates to:
  /// **'책을 선택해주세요'**
  String get memoSelectBookRequired;

  /// No description provided for @memoContentRequired.
  ///
  /// In ko, this message translates to:
  /// **'메모 내용을 입력해주세요'**
  String get memoContentRequired;

  /// No description provided for @memoImageUploadFailed.
  ///
  /// In ko, this message translates to:
  /// **'이미지 업로드에 실패했습니다'**
  String get memoImageUploadFailed;

  /// No description provided for @memoSaved.
  ///
  /// In ko, this message translates to:
  /// **'메모가 저장되었습니다'**
  String get memoSaved;

  /// No description provided for @memoEditTitle.
  ///
  /// In ko, this message translates to:
  /// **'메모 편집'**
  String get memoEditTitle;

  /// No description provided for @memoDelete.
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get memoDelete;

  /// No description provided for @memoBookFallback.
  ///
  /// In ko, this message translates to:
  /// **'책'**
  String get memoBookFallback;

  /// No description provided for @memoEditHint.
  ///
  /// In ko, this message translates to:
  /// **'메모를 입력하세요'**
  String get memoEditHint;

  /// No description provided for @memoUpdated.
  ///
  /// In ko, this message translates to:
  /// **'메모가 수정되었습니다'**
  String get memoUpdated;

  /// No description provided for @memoDeleteTitle.
  ///
  /// In ko, this message translates to:
  /// **'메모 삭제'**
  String get memoDeleteTitle;

  /// No description provided for @memoDeleteConfirm.
  ///
  /// In ko, this message translates to:
  /// **'이 메모를 삭제하시겠습니까?'**
  String get memoDeleteConfirm;

  /// No description provided for @memoDeleteAsk.
  ///
  /// In ko, this message translates to:
  /// **'이 메모를 삭제할까'**
  String get memoDeleteAsk;

  /// No description provided for @memoUnsavedTitle.
  ///
  /// In ko, this message translates to:
  /// **'변경사항이 있습니다'**
  String get memoUnsavedTitle;

  /// No description provided for @memoUnsavedBody.
  ///
  /// In ko, this message translates to:
  /// **'저장하지 않고 나가시겠습니까?'**
  String get memoUnsavedBody;

  /// No description provided for @memoLeave.
  ///
  /// In ko, this message translates to:
  /// **'나가기'**
  String get memoLeave;

  /// No description provided for @memoLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'메모를 불러오지 못했어요'**
  String get memoLoadFailed;

  /// No description provided for @memoSaveBookTitle.
  ///
  /// In ko, this message translates to:
  /// **'책 담기'**
  String get memoSaveBookTitle;

  /// No description provided for @memoSaveBookConfirm.
  ///
  /// In ko, this message translates to:
  /// **'담기'**
  String get memoSaveBookConfirm;

  /// No description provided for @memoRestrictedBody.
  ///
  /// In ko, this message translates to:
  /// **'지금은 볼 수 없는 메모야. 이 책을 담고 책 상세로 가볼까'**
  String get memoRestrictedBody;

  /// No description provided for @memoSaveBookBody.
  ///
  /// In ko, this message translates to:
  /// **'이 책을 담아야 상세를 볼 수 있어. 담을까'**
  String get memoSaveBookBody;

  /// No description provided for @memoAuthorFallback.
  ///
  /// In ko, this message translates to:
  /// **'밀키웨이'**
  String get memoAuthorFallback;

  /// No description provided for @memoMineTag.
  ///
  /// In ko, this message translates to:
  /// **'내 메모'**
  String get memoMineTag;

  /// No description provided for @memoEditedTag.
  ///
  /// In ko, this message translates to:
  /// **'수정됨'**
  String get memoEditedTag;

  /// No description provided for @memoDateMonthDay.
  ///
  /// In ko, this message translates to:
  /// **'{month}월 {day}일'**
  String memoDateMonthDay(int month, int day);

  /// No description provided for @memoLyraQuestionLabel.
  ///
  /// In ko, this message translates to:
  /// **'Lyra의 물음'**
  String get memoLyraQuestionLabel;

  /// No description provided for @memoPublicLabel.
  ///
  /// In ko, this message translates to:
  /// **'공개 메모'**
  String get memoPublicLabel;

  /// No description provided for @memoPrivateLabel.
  ///
  /// In ko, this message translates to:
  /// **'나만 보는 메모'**
  String get memoPrivateLabel;

  /// No description provided for @memoEditAction.
  ///
  /// In ko, this message translates to:
  /// **'수정하기'**
  String get memoEditAction;

  /// No description provided for @memoDeleteAction.
  ///
  /// In ko, this message translates to:
  /// **'삭제하기'**
  String get memoDeleteAction;

  /// No description provided for @memoConstellationTooltip.
  ///
  /// In ko, this message translates to:
  /// **'별자리'**
  String get memoConstellationTooltip;

  /// No description provided for @memoSegmentMine.
  ///
  /// In ko, this message translates to:
  /// **'내 메모'**
  String get memoSegmentMine;

  /// No description provided for @memoFeedLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'피드를 불러오지 못했어요'**
  String get memoFeedLoadFailed;

  /// No description provided for @memoEmptyMine.
  ///
  /// In ko, this message translates to:
  /// **'아직 남긴 메모가 없어요'**
  String get memoEmptyMine;

  /// No description provided for @memoEmptyPublic.
  ///
  /// In ko, this message translates to:
  /// **'아직 공개된 메모가 없어요'**
  String get memoEmptyPublic;

  /// No description provided for @memoTimeJustNow.
  ///
  /// In ko, this message translates to:
  /// **'방금'**
  String get memoTimeJustNow;

  /// No description provided for @memoTimeMinutesAgo.
  ///
  /// In ko, this message translates to:
  /// **'{count}분 전'**
  String memoTimeMinutesAgo(int count);

  /// No description provided for @memoTimeHoursAgo.
  ///
  /// In ko, this message translates to:
  /// **'{count}시간 전'**
  String memoTimeHoursAgo(int count);

  /// No description provided for @memoTimeDaysAgo.
  ///
  /// In ko, this message translates to:
  /// **'{count}일 전'**
  String memoTimeDaysAgo(int count);

  /// No description provided for @memoLoadErrorTitle.
  ///
  /// In ko, this message translates to:
  /// **'메모를 불러올 수 없습니다'**
  String get memoLoadErrorTitle;

  /// No description provided for @memoEmptyTitle.
  ///
  /// In ko, this message translates to:
  /// **'아직 메모가 없습니다'**
  String get memoEmptyTitle;

  /// No description provided for @memoEmptyBody.
  ///
  /// In ko, this message translates to:
  /// **'첫 번째 메모를 작성해보세요'**
  String get memoEmptyBody;

  /// No description provided for @memoFilterWrittenByMe.
  ///
  /// In ko, this message translates to:
  /// **'내가 쓴'**
  String get memoFilterWrittenByMe;

  /// No description provided for @memoFilterAllMemos.
  ///
  /// In ko, this message translates to:
  /// **'모든 메모'**
  String get memoFilterAllMemos;

  /// No description provided for @memoFilterPrivate.
  ///
  /// In ko, this message translates to:
  /// **'비공개'**
  String get memoFilterPrivate;

  /// No description provided for @memoErrorCameraPermission.
  ///
  /// In ko, this message translates to:
  /// **'카메라 접근 권한이 필요합니다'**
  String get memoErrorCameraPermission;

  /// No description provided for @memoErrorCameraUnavailable.
  ///
  /// In ko, this message translates to:
  /// **'카메라를 사용할 수 없습니다'**
  String get memoErrorCameraUnavailable;

  /// No description provided for @memoErrorPhotoPermission.
  ///
  /// In ko, this message translates to:
  /// **'사진 접근 권한이 필요합니다'**
  String get memoErrorPhotoPermission;

  /// No description provided for @memoErrorImagePick.
  ///
  /// In ko, this message translates to:
  /// **'이미지 선택 중 오류가 발생했습니다'**
  String get memoErrorImagePick;

  /// No description provided for @memoErrorNetwork.
  ///
  /// In ko, this message translates to:
  /// **'네트워크 연결을 확인해주세요'**
  String get memoErrorNetwork;

  /// No description provided for @memoErrorPermission.
  ///
  /// In ko, this message translates to:
  /// **'접근 권한이 필요합니다'**
  String get memoErrorPermission;

  /// No description provided for @memoErrorSave.
  ///
  /// In ko, this message translates to:
  /// **'저장 중 오류가 발생했습니다'**
  String get memoErrorSave;

  /// No description provided for @memoErrorGeneric.
  ///
  /// In ko, this message translates to:
  /// **'오류가 발생했습니다'**
  String get memoErrorGeneric;

  /// No description provided for @memoImageLabel.
  ///
  /// In ko, this message translates to:
  /// **'이미지 (선택사항)'**
  String get memoImageLabel;

  /// No description provided for @memoImageHint.
  ///
  /// In ko, this message translates to:
  /// **'저장하고 싶은 페이지를 등록해주세요'**
  String get memoImageHint;

  /// No description provided for @memoContentLabel.
  ///
  /// In ko, this message translates to:
  /// **'메모 내용'**
  String get memoContentLabel;

  /// No description provided for @memoContentHintMax.
  ///
  /// In ko, this message translates to:
  /// **'읽은 내용이나 생각을 적어주세요 (최대 {max}자)'**
  String memoContentHintMax(int max);

  /// No description provided for @memoPageLabel.
  ///
  /// In ko, this message translates to:
  /// **'페이지 숫자 (선택사항)'**
  String get memoPageLabel;

  /// No description provided for @memoPageHintExample.
  ///
  /// In ko, this message translates to:
  /// **'예시: 123 (숫자만 입력 가능해요)'**
  String get memoPageHintExample;

  /// No description provided for @memoVisibilityLabel.
  ///
  /// In ko, this message translates to:
  /// **'메모 공개 선택'**
  String get memoVisibilityLabel;

  /// No description provided for @memoVisibilityDescription.
  ///
  /// In ko, this message translates to:
  /// **'이 스위치를 켜면 메모가 공개돼요'**
  String get memoVisibilityDescription;

  /// No description provided for @memoAddBookAction.
  ///
  /// In ko, this message translates to:
  /// **'책 등록하기'**
  String get memoAddBookAction;

  /// No description provided for @memoAddMemoAction.
  ///
  /// In ko, this message translates to:
  /// **'메모 작성하기'**
  String get memoAddMemoAction;

  /// No description provided for @reportAction.
  ///
  /// In ko, this message translates to:
  /// **'신고하기'**
  String get reportAction;

  /// No description provided for @reportGuide.
  ///
  /// In ko, this message translates to:
  /// **'부적절한 콘텐츠를 신고해주세요. 신고된 메모는 검토 후 처리됩니다.'**
  String get reportGuide;

  /// No description provided for @reportReasonTitle.
  ///
  /// In ko, this message translates to:
  /// **'신고 사유'**
  String get reportReasonTitle;

  /// No description provided for @reportDescriptionLabel.
  ///
  /// In ko, this message translates to:
  /// **'추가 설명 (선택사항)'**
  String get reportDescriptionLabel;

  /// No description provided for @reportDescriptionHint.
  ///
  /// In ko, this message translates to:
  /// **'신고 사유를 자세히 설명해주세요'**
  String get reportDescriptionHint;

  /// No description provided for @reportSubmitted.
  ///
  /// In ko, this message translates to:
  /// **'신고가 접수되었습니다. 검토 후 처리됩니다.'**
  String get reportSubmitted;

  /// No description provided for @reportAlreadyReported.
  ///
  /// In ko, this message translates to:
  /// **'이미 신고한 메모입니다.'**
  String get reportAlreadyReported;

  /// No description provided for @reportFailed.
  ///
  /// In ko, this message translates to:
  /// **'신고 처리 중 오류가 발생했습니다. 잠시 후 다시 시도해주세요.'**
  String get reportFailed;

  /// No description provided for @reportReasonSpam.
  ///
  /// In ko, this message translates to:
  /// **'스팸/광고'**
  String get reportReasonSpam;

  /// No description provided for @reportReasonInappropriate.
  ///
  /// In ko, this message translates to:
  /// **'부적절한 콘텐츠'**
  String get reportReasonInappropriate;

  /// No description provided for @reportReasonHarassment.
  ///
  /// In ko, this message translates to:
  /// **'혐오 발언/괴롭힘'**
  String get reportReasonHarassment;

  /// No description provided for @reportReasonSexual.
  ///
  /// In ko, this message translates to:
  /// **'성적 콘텐츠'**
  String get reportReasonSexual;

  /// No description provided for @reportReasonViolence.
  ///
  /// In ko, this message translates to:
  /// **'폭력적 콘텐츠'**
  String get reportReasonViolence;

  /// No description provided for @reportReasonCopyright.
  ///
  /// In ko, this message translates to:
  /// **'저작권 침해'**
  String get reportReasonCopyright;

  /// No description provided for @reportReasonOther.
  ///
  /// In ko, this message translates to:
  /// **'기타'**
  String get reportReasonOther;

  /// No description provided for @profileLoadError.
  ///
  /// In ko, this message translates to:
  /// **'불러오지 못했어요'**
  String get profileLoadError;

  /// No description provided for @profileLoginRequired.
  ///
  /// In ko, this message translates to:
  /// **'로그인이 필요해요'**
  String get profileLoginRequired;

  /// No description provided for @profileEdit.
  ///
  /// In ko, this message translates to:
  /// **'프로필 편집'**
  String get profileEdit;

  /// No description provided for @profileMyRecord.
  ///
  /// In ko, this message translates to:
  /// **'내 기록'**
  String get profileMyRecord;

  /// No description provided for @profileSavedBooks.
  ///
  /// In ko, this message translates to:
  /// **'담은 책'**
  String get profileSavedBooks;

  /// No description provided for @profileCompletedBooks.
  ///
  /// In ko, this message translates to:
  /// **'완독한 책'**
  String get profileCompletedBooks;

  /// No description provided for @profileMenuNotification.
  ///
  /// In ko, this message translates to:
  /// **'알림'**
  String get profileMenuNotification;

  /// No description provided for @profileMenuFeedback.
  ///
  /// In ko, this message translates to:
  /// **'의견 보내기'**
  String get profileMenuFeedback;

  /// No description provided for @profileMenuTerms.
  ///
  /// In ko, this message translates to:
  /// **'이용약관'**
  String get profileMenuTerms;

  /// No description provided for @profileMenuVersion.
  ///
  /// In ko, this message translates to:
  /// **'앱 버전'**
  String get profileMenuVersion;

  /// No description provided for @profileNotificationSaveFailed.
  ///
  /// In ko, this message translates to:
  /// **'설정을 저장하지 못했어요'**
  String get profileNotificationSaveFailed;

  /// No description provided for @profileNotificationPermissionTitle.
  ///
  /// In ko, this message translates to:
  /// **'알림 권한 필요'**
  String get profileNotificationPermissionTitle;

  /// No description provided for @profileNotificationPermissionBody.
  ///
  /// In ko, this message translates to:
  /// **'알림을 받으려면 시스템 설정에서 알림 권한을 허용해주세요'**
  String get profileNotificationPermissionBody;

  /// No description provided for @profileOpenSettings.
  ///
  /// In ko, this message translates to:
  /// **'설정 열기'**
  String get profileOpenSettings;

  /// No description provided for @profileFeedbackTitle.
  ///
  /// In ko, this message translates to:
  /// **'의견 남기기'**
  String get profileFeedbackTitle;

  /// No description provided for @profileFeedbackHint.
  ///
  /// In ko, this message translates to:
  /// **'의견을 입력해주세요'**
  String get profileFeedbackHint;

  /// No description provided for @profileFeedbackSend.
  ///
  /// In ko, this message translates to:
  /// **'보내기'**
  String get profileFeedbackSend;

  /// No description provided for @profileFeedbackThanks.
  ///
  /// In ko, this message translates to:
  /// **'의견 보내주셔서 감사해요'**
  String get profileFeedbackThanks;

  /// No description provided for @profileFeedbackError.
  ///
  /// In ko, this message translates to:
  /// **'의견을 보내는 중 문제가 생겼어요. 잠시 후 다시 시도해요'**
  String get profileFeedbackError;

  /// No description provided for @profileEditTitle.
  ///
  /// In ko, this message translates to:
  /// **'프로필 수정'**
  String get profileEditTitle;

  /// No description provided for @profileEditChangePhoto.
  ///
  /// In ko, this message translates to:
  /// **'프로필 사진 변경'**
  String get profileEditChangePhoto;

  /// No description provided for @profileEditRemovePhoto.
  ///
  /// In ko, this message translates to:
  /// **'사진 제거'**
  String get profileEditRemovePhoto;

  /// No description provided for @profileEditPickImage.
  ///
  /// In ko, this message translates to:
  /// **'이미지 선택'**
  String get profileEditPickImage;

  /// No description provided for @profileEditFromGallery.
  ///
  /// In ko, this message translates to:
  /// **'갤러리에서 선택'**
  String get profileEditFromGallery;

  /// No description provided for @profileEditFromCamera.
  ///
  /// In ko, this message translates to:
  /// **'카메라로 촬영'**
  String get profileEditFromCamera;

  /// No description provided for @profileEditPickImageError.
  ///
  /// In ko, this message translates to:
  /// **'이미지 선택 중 오류가 발생했어요: {error}'**
  String profileEditPickImageError(String error);

  /// No description provided for @profileEditNicknameLabel.
  ///
  /// In ko, this message translates to:
  /// **'닉네임'**
  String get profileEditNicknameLabel;

  /// No description provided for @profileEditNicknameHint.
  ///
  /// In ko, this message translates to:
  /// **'닉네임을 입력하세요'**
  String get profileEditNicknameHint;

  /// No description provided for @profileEditNicknameRule.
  ///
  /// In ko, this message translates to:
  /// **'2 - 20자, 특수문자 사용 불가'**
  String get profileEditNicknameRule;

  /// No description provided for @profileEditChecking.
  ///
  /// In ko, this message translates to:
  /// **'확인 중...'**
  String get profileEditChecking;

  /// No description provided for @profileEditNicknameTooShort.
  ///
  /// In ko, this message translates to:
  /// **'닉네임은 최소 2자 이상이어야 합니다'**
  String get profileEditNicknameTooShort;

  /// No description provided for @profileEditNicknameTooLong.
  ///
  /// In ko, this message translates to:
  /// **'닉네임은 최대 20자까지 입력 가능합니다'**
  String get profileEditNicknameTooLong;

  /// No description provided for @profileEditNicknameNoSpecial.
  ///
  /// In ko, this message translates to:
  /// **'특수문자는 사용할 수 없습니다'**
  String get profileEditNicknameNoSpecial;

  /// No description provided for @profileEditNicknameTaken.
  ///
  /// In ko, this message translates to:
  /// **'이미 사용 중인 닉네임입니다'**
  String get profileEditNicknameTaken;

  /// No description provided for @profileEditNicknameCheckError.
  ///
  /// In ko, this message translates to:
  /// **'닉네임 확인 중 오류가 발생했습니다'**
  String get profileEditNicknameCheckError;

  /// No description provided for @profileEditNicknameRequired.
  ///
  /// In ko, this message translates to:
  /// **'닉네임을 입력해주세요'**
  String get profileEditNicknameRequired;

  /// No description provided for @profileEditNicknameChecking.
  ///
  /// In ko, this message translates to:
  /// **'닉네임 확인 중입니다. 잠시만 기다려주세요'**
  String get profileEditNicknameChecking;

  /// No description provided for @profileEditEmailLabel.
  ///
  /// In ko, this message translates to:
  /// **'이메일'**
  String get profileEditEmailLabel;

  /// No description provided for @profileEditNoEmail.
  ///
  /// In ko, this message translates to:
  /// **'이메일 없음'**
  String get profileEditNoEmail;

  /// No description provided for @profileEditEmailFixed.
  ///
  /// In ko, this message translates to:
  /// **'이메일은 변경할 수 없습니다'**
  String get profileEditEmailFixed;

  /// No description provided for @profileEditNoChanges.
  ///
  /// In ko, this message translates to:
  /// **'변경된 내용이 없습니다'**
  String get profileEditNoChanges;

  /// No description provided for @profileEditImageUploadFailed.
  ///
  /// In ko, this message translates to:
  /// **'프로필 이미지 업로드에 실패했습니다'**
  String get profileEditImageUploadFailed;

  /// No description provided for @profileEditSaved.
  ///
  /// In ko, this message translates to:
  /// **'프로필이 수정되었습니다'**
  String get profileEditSaved;

  /// No description provided for @profileEditLogout.
  ///
  /// In ko, this message translates to:
  /// **'로그아웃'**
  String get profileEditLogout;

  /// No description provided for @profileEditLogoutConfirm.
  ///
  /// In ko, this message translates to:
  /// **'정말 로그아웃 하시겠습니까?'**
  String get profileEditLogoutConfirm;

  /// No description provided for @profileEditDeleteAccount.
  ///
  /// In ko, this message translates to:
  /// **'계정 삭제'**
  String get profileEditDeleteAccount;

  /// No description provided for @profileEditDelete.
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get profileEditDelete;

  /// No description provided for @profileEditDeleteAccountMessage.
  ///
  /// In ko, this message translates to:
  /// **'지금 삭제하면 30일 뒤에 책과 메모가 완전히 지워져. 그 전에 다시 로그인하면 그대로 복구돼. 계속할까'**
  String get profileEditDeleteAccountMessage;

  /// No description provided for @rankingCardTitle.
  ///
  /// In ko, this message translates to:
  /// **'이번 주 나의 기록'**
  String get rankingCardTitle;

  /// No description provided for @rankingTopPercent.
  ///
  /// In ko, this message translates to:
  /// **'상위 {percent}%'**
  String rankingTopPercent(int percent);

  /// No description provided for @rankingDeltaUp.
  ///
  /// In ko, this message translates to:
  /// **'지난주보다 {count}개 늘었어'**
  String rankingDeltaUp(int count);

  /// No description provided for @rankingDeltaDown.
  ///
  /// In ko, this message translates to:
  /// **'지난주보다 {count}개 줄었어'**
  String rankingDeltaDown(int count);

  /// No description provided for @rankingDeltaSame.
  ///
  /// In ko, this message translates to:
  /// **'지난주와 같아'**
  String get rankingDeltaSame;

  /// No description provided for @rankingEmptyTitle.
  ///
  /// In ko, this message translates to:
  /// **'이번 주 첫 기록을 남겨봐'**
  String get rankingEmptyTitle;

  /// No description provided for @rankingLastWeek.
  ///
  /// In ko, this message translates to:
  /// **'지난주엔 {count}개 남겼어'**
  String rankingLastWeek(int count);

  /// No description provided for @rankingThisWeekCount.
  ///
  /// In ko, this message translates to:
  /// **'이번 주 {count}개'**
  String rankingThisWeekCount(int count);

  /// No description provided for @rankingStreakDays.
  ///
  /// In ko, this message translates to:
  /// **'{days}일 연속 읽는 중'**
  String rankingStreakDays(int days);

  /// No description provided for @errCameraPermission.
  ///
  /// In ko, this message translates to:
  /// **'카메라 접근 권한이 필요합니다'**
  String get errCameraPermission;

  /// No description provided for @errCameraUnavailable.
  ///
  /// In ko, this message translates to:
  /// **'카메라를 사용할 수 없습니다'**
  String get errCameraUnavailable;

  /// No description provided for @errPhotoPermission.
  ///
  /// In ko, this message translates to:
  /// **'사진 접근 권한이 필요합니다'**
  String get errPhotoPermission;

  /// No description provided for @errGeneric.
  ///
  /// In ko, this message translates to:
  /// **'작업 중 오류가 발생했습니다'**
  String get errGeneric;

  /// No description provided for @errNetwork.
  ///
  /// In ko, this message translates to:
  /// **'네트워크 연결을 확인해주세요'**
  String get errNetwork;

  /// No description provided for @errPermission.
  ///
  /// In ko, this message translates to:
  /// **'접근 권한이 필요합니다'**
  String get errPermission;

  /// No description provided for @errUploadFailed.
  ///
  /// In ko, this message translates to:
  /// **'업로드에 실패했습니다'**
  String get errUploadFailed;

  /// No description provided for @errCreateFailed.
  ///
  /// In ko, this message translates to:
  /// **'등록에 실패했습니다'**
  String get errCreateFailed;

  /// No description provided for @errUpdateFailed.
  ///
  /// In ko, this message translates to:
  /// **'수정에 실패했습니다'**
  String get errUpdateFailed;

  /// No description provided for @errDeleteFailed.
  ///
  /// In ko, this message translates to:
  /// **'삭제에 실패했습니다'**
  String get errDeleteFailed;

  /// No description provided for @errSaveFailed.
  ///
  /// In ko, this message translates to:
  /// **'저장에 실패했습니다'**
  String get errSaveFailed;

  /// No description provided for @errAuthRequired.
  ///
  /// In ko, this message translates to:
  /// **'인증이 필요합니다'**
  String get errAuthRequired;

  /// No description provided for @errServer.
  ///
  /// In ko, this message translates to:
  /// **'서버 오류가 발생했습니다'**
  String get errServer;
}

class _AppL10nDelegate extends LocalizationsDelegate<AppL10n> {
  const _AppL10nDelegate();

  @override
  Future<AppL10n> load(Locale locale) {
    return SynchronousFuture<AppL10n>(lookupAppL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja', 'ko', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppL10nDelegate old) => false;
}

AppL10n lookupAppL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppL10nEn();
    case 'ja':
      return AppL10nJa();
    case 'ko':
      return AppL10nKo();
    case 'zh':
      return AppL10nZh();
  }

  throw FlutterError(
    'AppL10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
