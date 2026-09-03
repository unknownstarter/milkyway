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
  String get statStreak => 'Streak';

  @override
  String get constellationTitle => 'Constellation';

  @override
  String get constellationLoadError => 'Could not load your constellation';

  @override
  String get constellationEmptyTitle => 'No stars connected yet';

  @override
  String get constellationEmptyBody =>
      'As memos pile up they link and a night sky appears';

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
  String get lyraAnswerCta => 'Write a memo on this question';

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
    return 'To reach $next: ';
  }

  @override
  String get orbDeepestReached => 'Reached the deepest space';

  @override
  String get orbShareLinkCopied => 'Share link copied';

  @override
  String get orbShareError =>
      'Something went wrong while preparing the share. Try again in a bit';

  @override
  String get orbGateBannerTitle => 'Create your first orb';

  @override
  String orbGateBannerBody(int count) {
    return 'Just $count more memos and your own galaxy appears';
  }

  @override
  String orbGateSheetTitle(int count) {
    return '$count to go for your orb';
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
  String get wrappedEmptyBody =>
      'Leave memos and stars gather in those moments';

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
    return 'Gathered $count stars left in those moments';
  }
}
