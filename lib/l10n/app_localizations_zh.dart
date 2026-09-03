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
  String get languageSystem => '系统默认';

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
  String get statMemosLeft => '写下的笔记';

  @override
  String get statTopPercent => '前';

  @override
  String get statStreak => '连续';

  @override
  String get constellationTitle => '星座';

  @override
  String get constellationLoadError => '无法加载星座';

  @override
  String get constellationEmptyTitle => '还没有连起来的星星';

  @override
  String get constellationEmptyBody => '笔记积累起来就会彼此相连，形成夜空';

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
  String get constellationRevealTitle => '画出了一条线';

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
  String get orbNowPrefix => '现在是 ';

  @override
  String orbTierBadge(String name) {
    return '$name 阶段';
  }

  @override
  String orbToNextTier(String next) {
    return '距离 $next 还差 ';
  }

  @override
  String get orbDeepestReached => '已抵达最深的宇宙';

  @override
  String get orbShareLinkCopied => '分享链接已复制';

  @override
  String get orbShareError => '分享准备时出了点问题，稍后再试一次';

  @override
  String get orbGateBannerTitle => '来创建第一颗星球吧';

  @override
  String orbGateBannerBody(int count) {
    return '再写 $count 条笔记，就会出现属于你的银河';
  }

  @override
  String orbGateSheetTitle(int count) {
    return '距离星球还差 $count 条';
  }

  @override
  String orbGateSheetBody(int count) {
    return '再写 $count 条笔记\n你的银河星球就完成了';
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
  String get wrappedEmptyBody => '写下笔记，星星就会在那里积累';

  @override
  String get wrappedLoadErrorTitle => '无法加载回顾';

  @override
  String get wrappedLoadErrorBody => '稍后再试一次';

  @override
  String get wrappedShareLinkCopied => '分享链接已复制';

  @override
  String get wrappedShareError => '分享准备时出了点问题，稍后再试一次';

  @override
  String get commonShare => '分享';

  @override
  String get orbLoadErrorTitle => '无法加载宇宙';

  @override
  String wrappedEntryTitle(String month) {
    return '$month 银河回顾';
  }

  @override
  String wrappedEntryBody(int count) {
    return '收集了留在那里的 $count 颗星';
  }
}
