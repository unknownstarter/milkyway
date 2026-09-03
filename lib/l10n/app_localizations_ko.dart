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
    return '메모 $count개만 더 남기면 나만의 은하수가 생겨요';
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
    return '그 자리에 남은 $count개의 별을 모았어요';
  }
}
