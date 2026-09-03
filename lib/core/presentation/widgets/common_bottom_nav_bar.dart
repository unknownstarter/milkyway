import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

class CommonBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const CommonBottomNavBar({
    required this.currentIndex,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) => BottomNavigationBar(
        backgroundColor: Colors.black,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey.shade600,
        currentIndex: currentIndex,
        onTap: onTap,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home_filled),
            label: AppL10n.of(context).commonNavHome,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.book_outlined),
            activeIcon: const Icon(Icons.book),
            label: AppL10n.of(context).commonNavBooks,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.note_outlined),
            activeIcon: const Icon(Icons.note),
            label: AppL10n.of(context).commonNavMemos,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            activeIcon: const Icon(Icons.person),
            label: AppL10n.of(context).commonNavProfile,
          ),
        ],
      );
} 