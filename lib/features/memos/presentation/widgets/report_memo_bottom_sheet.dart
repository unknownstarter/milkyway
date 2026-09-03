import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/memo.dart';
import '../../domain/models/report_reason.dart';
import '../providers/memo_report_provider.dart';
import 'dart:developer' as developer;
import '../../../../l10n/app_localizations.dart';
import '../memo_l10n.dart';

/// 메모 신고 바텀시트
class ReportMemoBottomSheet extends ConsumerStatefulWidget {
  final Memo memo;

  const ReportMemoBottomSheet({
    super.key,
    required this.memo,
  });

  @override
  ConsumerState<ReportMemoBottomSheet> createState() =>
      _ReportMemoBottomSheetState();
}

class _ReportMemoBottomSheetState
    extends ConsumerState<ReportMemoBottomSheet> {
  ReportReason? _selectedReason;
  final TextEditingController _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.reportAction,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Pretendard',
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // 안내 문구
            Text(
              l10n.reportGuide,
              style: const TextStyle(
                color: Color(0xFF838383),
                fontFamily: 'Pretendard',
                fontSize: 14,
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: 24),
            // 신고 사유 선택
            Text(
              l10n.reportReasonTitle,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Pretendard',
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ...ReportReason.values.map((reason) => _buildReasonTile(reason)),
            const SizedBox(height: 24),
            // 추가 설명 (선택사항)
            if (_selectedReason == ReportReason.other) ...[
              Text(
                l10n.reportDescriptionLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Pretendard',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Pretendard',
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  hintText: l10n.reportDescriptionHint,
                  hintStyle: const TextStyle(
                    color: Color(0xFF838383),
                    fontFamily: 'Pretendard',
                    fontSize: 16,
                  ),
                  filled: true,
                  fillColor: const Color(0xFF242424),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 24),
            ],
            // 신고하기 버튼
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSubmitting || _selectedReason == null
                    ? null
                    : _handleReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF48FF00),
                  disabledBackgroundColor: const Color(0xFF838383),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        l10n.reportAction,
                        style: const TextStyle(
                          color: Colors.black,
                          fontFamily: 'Pretendard',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// 신고 사유 타일
  Widget _buildReasonTile(ReportReason reason) {
    final isSelected = _selectedReason == reason;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedReason = reason;
          if (reason != ReportReason.other) {
            _descriptionController.clear();
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF48FF00).withOpacity(0.1) : const Color(0xFF242424),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF48FF00) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                reportReasonLabel(AppL10n.of(context), reason),
                style: TextStyle(
                  color: isSelected ? const Color(0xFF48FF00) : Colors.white,
                  fontFamily: 'Pretendard',
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF48FF00),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  /// 신고 처리
  Future<void> _handleReport() async {
    if (_selectedReason == null) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final description = _selectedReason == ReportReason.other
          ? _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim()
          : null;

      await ref.read(reportMemoProvider((
        memoId: widget.memo.id,
        bookId: widget.memo.bookId, // 메모 리스트 리로딩을 위해 필요
        reason: _selectedReason!,
        description: description,
      )).future);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppL10n.of(context).reportSubmitted,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Pretendard',
              ),
            ),
            backgroundColor: const Color(0xFF242424),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      developer.log('신고 실패: $e');
      if (mounted) {
        final errorMessage = e.toString().contains('이미 신고한 메모')
            ? AppL10n.of(context).reportAlreadyReported
            : AppL10n.of(context).reportFailed;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMessage,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Pretendard',
              ),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}

