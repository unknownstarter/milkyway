import 'package:flutter/material.dart';
import '../../../../core/presentation/widgets/design/cached_image.dart';
import 'dart:io';

/// 메모 이미지 선택 위젯
class MemoImageSelector extends StatelessWidget {
  final String? imagePath;
  final VoidCallback onSelectImage;
  final VoidCallback onRemoveImage;

  const MemoImageSelector({
    super.key,
    this.imagePath,
    required this.onSelectImage,
    required this.onRemoveImage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '이미지 (선택사항)',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            fontFamily: 'Pretendard',
            height: 28 / 20,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 208,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF646464)),
          ),
          child: imagePath == null
              ? InkWell(
                  onTap: onSelectImage,
                  borderRadius: BorderRadius.circular(12),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_outlined,
                        color: Color(0xFF838383),
                        size: 48,
                      ),
                      SizedBox(height: 12),
                      Text(
                        '저장하고 싶은 페이지를 등록해주세요',
                        style: TextStyle(
                          color: Color(0xFF838383),
                          fontSize: 16,
                          fontFamily: 'Pretendard',
                        ),
                      ),
                    ],
                  ),
                )
              : Stack(
                  children: [
                    InkWell(
                      onTap: onSelectImage,
                      borderRadius: BorderRadius.circular(12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: imagePath!.startsWith('http')
                            ? CachedImage(
                                url: imagePath,
                                width: double.infinity,
                                height: 208,
                                fit: BoxFit.cover,
                                cacheWidth: 700,
                                fallback: Container(
                                  width: double.infinity,
                                  height: 208,
                                  color: Colors.grey.shade900,
                                  child: const Icon(
                                    Icons.image,
                                    color: Colors.grey,
                                    size: 32,
                                  ),
                                ),
                              )
                            : Image.file(
                                File(imagePath!),
                                width: double.infinity,
                                height: 208,
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: onRemoveImage,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

