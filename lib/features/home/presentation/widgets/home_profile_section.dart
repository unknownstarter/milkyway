import 'package:flutter/material.dart';
import '../../../../core/presentation/widgets/design/cached_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// 홈 화면의 프로필 섹션
class HomeProfileSection extends ConsumerWidget {
  const HomeProfileSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authProvider);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 프로필 이미지 (Avatar)
          authAsync.when(
            data: (user) => _ProfileAvatar(pictureUrl: user?.pictureUrl),
            loading: () => const _ProfileAvatarLoading(),
            error: (_, __) => const _ProfileAvatarPlaceholder(),
          ),
          const SizedBox(width: 20),
          // 텍스트 영역
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                authAsync.when(
                  data: (user) => Text(
                    '${user?.nickname ?? 'User'}님,',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Pretendard',
                      height: 21.48 / 18,
                    ),
                  ),
                  loading: () => const Text(
                    'Loading...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Pretendard',
                      height: 21.48 / 18,
                    ),
                  ),
                  error: (_, __) => const Text(
                    'User님,',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Pretendard',
                      height: 21.48 / 18,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '오늘은 어떤 책을 보고 계신가요?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'Pretendard',
                    height: 19.09 / 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 프로필 아바타
class _ProfileAvatar extends StatelessWidget {
  final String? pictureUrl;

  const _ProfileAvatar({required this.pictureUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
      ),
      child: pictureUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: CachedImage(
                url: pictureUrl,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                cacheWidth: 120,
                fallback: const _ProfileAvatarPlaceholder(),
              ),
            )
          : const _ProfileAvatarPlaceholder(),
    );
  }
}

/// 프로필 아바타 로딩
class _ProfileAvatarLoading extends StatelessWidget {
  const _ProfileAvatarLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFF48FF00),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFFECECEC),
          ),
        ),
      ),
    );
  }
}

/// 프로필 아바타 플레이스홀더
class _ProfileAvatarPlaceholder extends StatelessWidget {
  const _ProfileAvatarPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFF48FF00),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Icon(
        Icons.person,
        color: Colors.black,
        size: 20,
      ),
    );
  }
}

