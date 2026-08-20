import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/presentation/widgets/design/segment_filter.dart';
import '../../../../core/presentation/widgets/design/memo_card.dart';
import '../../../../core/presentation/widgets/design/cached_image.dart';
import '../../../../core/providers/analytics_provider.dart';
import '../../../memos/domain/models/memo.dart';
import '../../../memos/presentation/providers/memo_provider.dart';
import '../../../reading/data/models/reading_log.dart';
import '../../../reading/presentation/providers/reading_providers.dart';
import '../../domain/calendar_logic.dart';

/// 기록 캘린더. 메모/책 세그먼트 + 월 그리드. 날짜 탭 -> 그날 기록 바텀시트.
/// 내 메모(created_at) / 내 책(담은 날) 기준, 전부 클라이언트 데이터.
class CalendarScreen extends ConsumerStatefulWidget {
  /// 진입 시 초기 세그먼트(0=메모, 1=책).
  final int initialSegment;

  const CalendarScreen({super.key, this.initialSegment = 0});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late int _segment;
  late DateTime _month; // 해당 월 1일

  static const _weekdays = ['일', '월', '화', '수', '목', '금', '토'];

  @override
  void initState() {
    super.initState();
    _segment = widget.initialSegment;
    final now = DateTime.now();
    _month = DateTime(now.year, now.month, 1);
    ref.read(analyticsProvider).logScreenView('calendar_screen');
  }

  void _shiftMonth(int delta) =>
      setState(() => _month = DateTime(_month.year, _month.month + delta, 1));

  @override
  Widget build(BuildContext context) {
    final memos = ref.watch(allMemosProvider).asData?.value ?? const <Memo>[];
    final logs =
        ref.watch(readingLogsProvider).asData?.value ?? const <ReadingLog>[];

    final counts = _segment == 0
        ? countByDay<Memo>(memos, (m) => m.createdAt)
        : countByDay<ReadingLog>(logs, (l) => l.readOn);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 20, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text('기록', style: AppTypography.subtitle),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Center(
              child: SegmentFilter(
                segments: const ['메모', '읽음'],
                selectedIndex: _segment,
                onChanged: (i) => setState(() => _segment = i),
              ),
            ),
          ),
          _monthBar(),
          _weekdayHeader(),
          Expanded(child: SingleChildScrollView(child: _grid(counts))),
        ],
      ),
    );
  }

  Widget _monthBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left,
                size: 22, color: AppColors.textSecondary),
            onPressed: () => _shiftMonth(-1),
          ),
          const SizedBox(width: 8),
          Text('${_month.year}년 ${_month.month}월',
              style: AppTypography.subtitle.copyWith(color: Colors.white)),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.chevron_right,
                size: 22, color: AppColors.textSecondary),
            onPressed: () => _shiftMonth(1),
          ),
        ],
      ),
    );
  }

  Widget _weekdayHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: Row(
        children: [
          for (var i = 0; i < 7; i++)
            Expanded(
              child: Center(
                child: Text(
                  _weekdays[i],
                  style: AppTypography.caption.copyWith(
                    color: i == 0 ? const Color(0xFFA05252) : AppColors.textTertiary,
                    fontSize: 11.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _grid(Map<DateTime, int> counts) {
    final cells = monthGrid(_month.year, _month.month);
    final today = dayKey(DateTime.now());
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
      child: GridView.count(
        crossAxisCount: 7,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 0.72,
        children: [
          for (final cell in cells)
            _cell(cell, counts[dayKey(cell.date)] ?? 0, today),
        ],
      ),
    );
  }

  Widget _cell(MonthCell cell, int count, DateTime today) {
    final isToday = dayKey(cell.date) == today;
    final enabled = cell.inMonth && count > 0;
    return GestureDetector(
      onTap: enabled ? () => _openDay(cell.date) : null,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isToday ? Colors.white : null,
            ),
            child: Text(
              '${cell.date.day}',
              style: AppTypography.caption.copyWith(
                fontSize: 13,
                color: !cell.inMonth
                    ? const Color(0xFF3A3A3A)
                    : (isToday ? Colors.black : AppColors.textPrimary),
                fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 6),
          if (cell.inMonth && count > 0)
            count > 1
                ? Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.accentGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('$count',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.accentGreen,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        )),
                  )
                : Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: AppColors.accentGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
        ],
      ),
    );
  }

  void _openDay(DateTime day) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgPrimary,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _daySheet(day),
    );
  }

  Widget _daySheet(DateTime day) {
    final title = '${day.month}월 ${day.day}일';
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      maxChildSize: 0.9,
      builder: (context, controller) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(title, style: AppTypography.title),
              const SizedBox(height: 16),
              Expanded(
                child: _segment == 0 ? _memoList(day, controller) : _bookList(day, controller),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _memoList(DateTime day, ScrollController controller) {
    final memos = ref.read(allMemosProvider).asData?.value ?? const <Memo>[];
    final items = itemsOnDay<Memo>(memos, (m) => m.createdAt, day);
    if (items.isEmpty) return _empty('이 날 남긴 메모가 없어요');
    return ListView.separated(
      controller: controller,
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final m = items[i];
        return MemoCard(
          content: m.content,
          bookTitle: m.bookTitle,
          page: m.page,
          onTap: () {
            context.pop();
            context.pushNamed(AppRoutes.memoDetailName,
                pathParameters: {'id': m.id});
          },
        );
      },
    );
  }

  Widget _bookList(DateTime day, ScrollController controller) {
    final logs =
        ref.read(readingLogsProvider).asData?.value ?? const <ReadingLog>[];
    final items = itemsOnDay<ReadingLog>(logs, (l) => l.readOn, day);
    if (items.isEmpty) return _empty('이 날 읽은 책이 없어요');
    return ListView.separated(
      controller: controller,
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final l = items[i];
        return GestureDetector(
          onTap: () {
            context.pop();
            context.pushNamed(AppRoutes.bookDetailName,
                pathParameters: {'id': l.bookId});
          },
          behavior: HitTestBehavior.opaque,
          child: Row(
            children: [
              Container(
                width: 42,
                height: 62,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(4),
                ),
                clipBehavior: Clip.antiAlias,
                child: CachedImage(url: l.coverUrl, fallback: const SizedBox()),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(l.bookTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyBold
                        .copyWith(fontSize: 14, color: AppColors.textBright)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _empty(String text) {
    return Center(
      child: Text(text,
          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
    );
  }
}
