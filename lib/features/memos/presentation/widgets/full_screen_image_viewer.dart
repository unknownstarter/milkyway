import 'package:flutter/material.dart';
import '../../../../core/presentation/widgets/design/cached_image.dart';

/// 전체 화면 이미지 뷰어
///
/// 이미지를 전체 화면으로 보여주고, 뒤로가기로 닫을 수 있음.
/// CachedImage로 상세 화면에서 받아둔 디스크 캐시를 재사용 -> 즉시 표시.
class FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;

  const FullScreenImageViewer({
    super.key,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: CachedImage(
            url: imageUrl,
            fit: BoxFit.contain,
            fallback: const Center(
              child: Icon(Icons.image, color: Colors.grey, size: 64),
            ),
          ),
        ),
      ),
    );
  }
}

