import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../theme/app_colors.dart';

/// 네트워크 이미지 공용 래퍼. cached_network_image로 디스크/메모리 캐시해
/// 재진입 시 재다운로드를 막는다(로딩 체감 개선). 빈 URL이면 [fallback].
class CachedImage extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? fallback;

  /// 디코드 해상도 상한(px). 큰 원본이라도 이 폭으로 디코드해 메모리/속도 개선.
  final int? cacheWidth;

  const CachedImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.fallback,
    this.cacheWidth,
  });

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) return _fallback();
    return CachedNetworkImage(
      imageUrl: url!,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: cacheWidth,
      maxWidthDiskCache: cacheWidth,
      fadeInDuration: const Duration(milliseconds: 150),
      placeholder: (_, __) => Container(color: AppColors.surface),
      errorWidget: (_, __, ___) => _fallback(),
    );
  }

  Widget _fallback() =>
      fallback ??
      Container(width: width, height: height, color: AppColors.surface);
}
