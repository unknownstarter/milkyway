import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 온보딩에서 고른 관심 장르(선택).
///
/// 용도는 **추천 책 정렬**뿐이며 게이팅이 아니다(디자인/실행계획 결정 2026-08-17).
/// 건너뛰기 가능. 다음 스텝(책 담기)이 이 값을 읽어 추천 순서를 조정한다.
/// 현재는 클라이언트 상태로만 유지하고, 영구 저장(신규 테이블)은 후속 작업.
final onboardingGenresProvider =
    StateProvider<List<String>>((ref) => const []);

/// 선택 가능한 장르 목록. 쉬운 말 원칙(원칙 6)에 맞춘 일상어.
const List<String> kOnboardingGenres = [
  '소설',
  '시',
  '에세이',
  '인문',
  '철학',
  '과학',
  'SF',
  '역사',
  '예술',
  '심리',
  '경제경영',
  '자기계발',
];
