import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/supabase_image.dart';

/// 네트워크 이미지 공용 래퍼. cached_network_image로 디스크/메모리 캐시해
/// 재진입 시 재다운로드를 막는다(로딩 체감 개선). 빈 URL이면 [fallback].
///
/// 전송 최적화: Supabase Storage 공개 URL이면 on-the-fly 변환 엔드포인트로 바꿔
/// **표시폭 크기 + WebP**로 받는다(원본 수 MB -> 수 KB, CDN 엣지 캐시). YouTube/인스타식
/// "뷰포트별 최적본 서빙"과 동일 원리. Supabase Pro 이상에서 동작.
class CachedImage extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? fallback;

  /// 디코드 해상도 상한(px). 큰 원본이라도 이 폭으로 디코드해 메모리/속도 개선.
  /// 서버 변환 폭([transformWidth] 미지정 시)으로도 재사용된다.
  final int? cacheWidth;

  /// 서버 변환(리사이즈) 목표 폭(px). 미지정 시 [cacheWidth]를 사용.
  /// null이면(둘 다 없음) 변환 없이 원본 URL 그대로.
  final int? transformWidth;

  /// 서버 변환 품질(1-100). WebP 재인코딩 품질.
  final int transformQuality;

  const CachedImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.fallback,
    this.cacheWidth,
    this.transformWidth,
    this.transformQuality = 80,
  });

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) return _fallback();
    return CachedNetworkImage(
      imageUrl: supabaseRenderUrl(url!,
          width: transformWidth ?? cacheWidth, quality: transformQuality),
      // WebP를 명시적으로 수락 -> CDN이 표시폭 WebP로 응답(Accept 미전송 시 png로 커짐).
      httpHeaders: const {'Accept': 'image/webp,image/*,*/*'},
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: cacheWidth,
      // 디스크엔 변환본(표시폭 WebP) 저장 -> 재사용 시 재다운로드 없음.
      fadeInDuration: const Duration(milliseconds: 150),
      placeholder: (_, __) => Container(color: AppColors.surface),
      errorWidget: (_, __, ___) => _fallback(),
    );
  }

  Widget _fallback() =>
      fallback ??
      Container(width: width, height: height, color: AppColors.surface);
}
