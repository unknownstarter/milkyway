import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../l10n/app_localizations.dart';

class AddActionModal extends StatelessWidget {
  const AddActionModal({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      // 바텀시트 배경이 네비게이션 바까지 확장되도록 (화면 최하단부터 시작)
      decoration: const BoxDecoration(
        color: Color(0xFF313131),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 닫기 버튼 (X)
          Padding(
            padding: const EdgeInsets.only(top: 16, right: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 8,
            ),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF9C9C9C),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.menu_book_outlined,
                color: Colors.black,
              ),
            ),
            title: Text(
              AppL10n.of(context).homeAddBook,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontFamily: 'Pretendard',
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              context.pushNamed(AppRoutes.bookSearchName);
            },
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 8,
            ),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF9C9C9C),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.edit_outlined,
                color: Colors.black,
              ),
            ),
            title: Text(
              AppL10n.of(context).homeAddMemo,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontFamily: 'Pretendard',
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              context.pushNamed(AppRoutes.memoCreateName);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
} 