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
    return 'つながった瞬間 $count';
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
  String get constellationRevealTitle => '線が一本引かれました';

  @override
  String get constellationViewInConstellation => '星座で見る';

  @override
  String get lyraQuestionLabel => 'Lyraからの問い';

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
  String get orbMyUniverseTitle => '私の宇宙';

  @override
  String get orbNowPrefix => 'いまは ';

  @override
  String orbTierBadge(String name) {
    return '$name ステージ';
  }

  @override
  String orbToNextTier(String next) {
    return '次の $next まで ';
  }

  @override
  String get orbDeepestReached => 'いちばん深い宇宙に到達';

  @override
  String get orbShareLinkCopied => '共有リンクをコピーしました';

  @override
  String get orbShareError => '共有の準備中に問題が起きました。少し後にもう一度お試しください';

  @override
  String get orbGateBannerTitle => 'はじめてのオーブを作ってみよう';

  @override
  String orbGateBannerBody(int count) {
    return 'あと $count 件メモを残すと自分だけの銀河ができます';
  }

  @override
  String orbGateSheetTitle(int count) {
    return 'オーブまであと $count 件';
  }

  @override
  String orbGateSheetBody(int count) {
    return 'メモをあと $count 件残すと\n自分だけの銀河オーブが完成します';
  }

  @override
  String get orbGateWriteCta => 'いまメモを書く';

  @override
  String get shareCardDefaultNick => 'わたし';

  @override
  String shareCardOwnerUniverse(String nick) {
    return '$nick の宇宙';
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
    return 'その場所に残った $count 個の星';
  }

  @override
  String get wrappedStatSentences => '止まった文';

  @override
  String get wrappedStatReadDays => '読んだ日';

  @override
  String get wrappedTopBookLabel => 'いちばん長くとどまった本';

  @override
  String get wrappedQuoteLabel => 'その月の一文';

  @override
  String wrappedQuoteSource(String title) {
    return '$title より';
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
  String get wrappedLoadErrorBody => '少し後にもう一度お試しください';

  @override
  String get wrappedShareLinkCopied => '共有リンクをコピーしました';

  @override
  String get wrappedShareError => '共有の準備中に問題が起きました。少し後にもう一度お試しください';

  @override
  String get commonShare => '共有';

  @override
  String get orbLoadErrorTitle => '宇宙を読み込めませんでした';

  @override
  String wrappedEntryTitle(String month) {
    return '$month の銀河のふりかえり';
  }

  @override
  String wrappedEntryBody(int count) {
    return 'その場所に残った $count 個の星を集めました';
  }
}
