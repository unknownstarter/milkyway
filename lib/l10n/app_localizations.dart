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
  /// **'메모 {count}개만 더 남기면 나만의 은하수가 생겨요'**
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
  /// **'그 자리에 남은 {count}개의 별을 모았어요'**
  String wrappedEntryBody(int count);
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
