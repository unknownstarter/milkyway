import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../features/home/presentation/widgets/add_action_modal.dart';

/// 공통 플로팅 액션 버튼
///
/// Home, Books, Memos 스크린에서 공통으로 사용하는 플로팅 버튼
class AddFloatingActionButton extends StatelessWidget {
  const AddFloatingActionButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _showBottomSheet(context),
      backgroundColor: const Color(0xFFECECEC),
      shape: const CircleBorder(),
      child: const Icon(Icons.add, color: Colors.black),
    );
  }

  void _showBottomSheet(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '바텀시트',
      barrierColor: Colors.black.withOpacity(0.5), // 어두운 딤 처리
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final screenHeight = MediaQuery.of(context).size.height;

        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          )),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Material(
              color: Colors.transparent,
              child: GestureDetector(
                onTap: () {}, // 바텀시트 내부 탭은 무시
                child: Container(
                  width: double.infinity,
                  height: screenHeight * 0.3,
                  decoration: const BoxDecoration(
                    color: Color(0xFF313131),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: math.max(MediaQuery.of(context).viewInsets.bottom,
                          MediaQuery.viewPaddingOf(context).bottom),
                      ),
                      child: const AddActionModal(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
