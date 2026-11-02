import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:shemesh_admin/config/color_constants.dart';
import 'package:shemesh_admin/config/dashboard_labels.dart';
import 'package:shemesh_admin/config/stat_consts.dart';
import 'package:shemesh_admin/services/firebase_service.dart';
import 'package:shemesh_admin/widgets/chart_card.dart';

const double _minWidthPerBar = 55.0;
const double _yAxisPanelWidth = 64.0;

// Vertical space reserved above the plot for the per-bar total labels, and the
// space reserved below for the x-axis labels. Both are needed to map a bar's
// value to a pixel position for the hovering total labels.
const double _topLabelHeight = 22.0;
const double _xAxisHeight = 42.0;
// The fixed y-axis panel reserves this width for its labels; the scrollable
// chart hides its own left axis (see showLeftAxis).
const double _leftAxisWidth = 60.0;
// Size of each hovering total label.
const double _totalLabelWidth = 44.0;
const double _totalLabelHeight = 16.0;

/// A single x-axis column: the registered-user and guest quiz counts that make
/// up one stacked bar.
class _StackedEntry {
  _StackedEntry(this.key, this.registered, this.guest);

  final String key;
  final int registered;
  final int guest;

  int get total => registered + guest;
}

/// Stacked variant of QuizTotalBarChart: for each day/month it stacks the guest
/// quiz submissions (purple) on top of the registered-user submissions.
class QuizTotalStackedBarChart extends StatefulWidget {
  const QuizTotalStackedBarChart({super.key, required this.excludedUids});

  /// Resolved once per dashboard load and shared with the stat cards, so the
  /// excluded-user lookup runs only once.
  final Future<Set<String>> excludedUids;

  @override
  State<QuizTotalStackedBarChart> createState() =>
      _QuizTotalStackedBarChartState();
}

class _QuizTotalStackedBarChartState extends State<QuizTotalStackedBarChart> {
  bool loading = true;
  bool _daily = false;
  Map<String, int> monthlyRegistered = {};
  Map<String, int> monthlyGuest = {};
  Map<String, int> dailyRegistered = {};
  Map<String, int> dailyGuest = {};
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> loadData() async {
    final db = FirebaseService().firestore;
    final excludedUids = await widget.excludedUids;

    // Registered-user submissions come from the per-user test_data docs; guest
    // submissions are pre-aggregated under analytics/guest_stats.
    final testDataFuture = db.collectionGroup('test_data').get();
    final guestDailyFuture =
        db.collection('analytics').doc('guest_stats').collection('daily').get();
    final guestMonthlyFuture = db
        .collection('analytics')
        .doc('guest_stats')
        .collection('monthly')
        .get();

    final results = await Future.wait(
        [testDataFuture, guestDailyFuture, guestMonthlyFuture]);
    final snap = results[0];
    final guestDailySnap = results[1];
    final guestMonthlySnap = results[2];

    final Map<String, int> monthlyRegisteredCounts = {};
    final Map<String, int> monthlyGuestCounts = {};

    // Pre-seed the last N days with 0 so every calendar day shows a bar, even
    // days with no submissions. Keyed YYYY-MM-DD.
    final Map<String, int> dailyRegisteredCounts = {};
    final Map<String, int> dailyGuestCounts = {};
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    final windowStart =
        startOfToday.subtract(Duration(days: StatConsts.daysForDailyChart - 1));
    for (int i = 0; i < StatConsts.daysForDailyChart; i++) {
      final d = windowStart.add(Duration(days: i));
      dailyRegisteredCounts[_dayKey(d)] = 0;
      dailyGuestCounts[_dayKey(d)] = 0;
    }

    for (final doc in snap.docs) {
      // test_data is a subcollection of the user doc: users/{uid}/test_data.
      final uid = doc.reference.parent.parent?.id;
      if (uid != null && excludedUids.contains(uid)) continue;

      final ts = doc['quiz_date'] as Timestamp;
      final date = ts.toDate();

      final monthKey = _monthKey(date);
      monthlyRegisteredCounts[monthKey] =
          (monthlyRegisteredCounts[monthKey] ?? 0) + 1;

      final dayKey = _dayKey(date);
      if (dailyRegisteredCounts.containsKey(dayKey)) {
        dailyRegisteredCounts[dayKey] = dailyRegisteredCounts[dayKey]! + 1;
      }
    }

    // Guest submissions are already aggregated per day / per month; the doc id
    // is the YYYY-MM-DD / YYYY-MM key and the count is in `guestQuizzes`.
    for (final doc in guestDailySnap.docs) {
      final count = (doc.data()['guestQuizzes'] as num?)?.toInt() ?? 0;
      if (dailyGuestCounts.containsKey(doc.id)) {
        dailyGuestCounts[doc.id] = count;
      }
    }
    for (final doc in guestMonthlySnap.docs) {
      final count = (doc.data()['guestQuizzes'] as num?)?.toInt() ?? 0;
      monthlyGuestCounts[doc.id] = count;
    }

    // Fill in any gap months with 0 so a month without quizzes still shows a
    // (zero-height) bar instead of being skipped. Spans from the earliest
    // month seen in either series through the current month, and keeps both
    // series keyed identically.
    _fillMonthlyGaps(monthlyRegisteredCounts, monthlyGuestCounts, today);

    setState(() {
      monthlyRegistered = _sortedByKey(monthlyRegisteredCounts);
      monthlyGuest = _sortedByKey(monthlyGuestCounts);
      dailyRegistered = _sortedByKey(dailyRegisteredCounts);
      dailyGuest = _sortedByKey(dailyGuestCounts);
      loading = false;
    });
  }

  /// Ensures both monthly series have a contiguous set of month keys from the
  /// earliest month seen in either through the current month (0 where absent).
  static void _fillMonthlyGaps(
    Map<String, int> registered,
    Map<String, int> guest,
    DateTime today,
  ) {
    final allKeys = {...registered.keys, ...guest.keys}.toList()..sort();
    if (allKeys.isEmpty) return;
    final first = _parseMonthKey(allKeys.first);
    final lastPresent = _parseMonthKey(allKeys.last);
    final currentMonth = DateTime(today.year, today.month);
    final last = lastPresent.isAfter(currentMonth) ? lastPresent : currentMonth;
    for (var m = first; !m.isAfter(last); m = DateTime(m.year, m.month + 1)) {
      final key = _monthKey(m);
      registered.putIfAbsent(key, () => 0);
      guest.putIfAbsent(key, () => 0);
    }
  }

  static String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String _monthKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}';

  static DateTime _parseMonthKey(String key) {
    final parts = key.split('-');
    return DateTime(int.parse(parts[0]), int.parse(parts[1]));
  }

  static Map<String, int> _sortedByKey(Map<String, int> counts) =>
      Map.fromEntries(
        counts.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
      );

  /// Overlays the per-bar total (registered + guests) just above each bar's top
  /// edge. The labels are painted *under* [chart], so the opaque tooltip covers
  /// whichever labels it overlaps while the rest show through the chart's
  /// transparent background untouched. The bar geometry is derived from the
  /// data: with [BarChartAlignment.spaceAround], bar i is centred at
  /// plotWidth * (i + 0.5) / n, and its top sits at (1 - total / maxY) of the
  /// plot height. [leftInset] is the width taken by the left axis (0 when it is
  /// hidden, as in the scrollable chart).
  Widget _withTotalLabels({
    required BarChart chart,
    required List<_StackedEntry> entries,
    required double maxY,
    required double leftInset,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final n = entries.length;
        final plotWidth = constraints.maxWidth - leftInset;
        final plotHeight =
            constraints.maxHeight - _topLabelHeight - _xAxisHeight;
        final canLabel = n > 0 && plotWidth > 0 && plotHeight > 0 && maxY > 0;
        return Stack(
          fit: StackFit.expand,
          children: [
            if (canLabel)
              for (int i = 0; i < n; i++)
                _buildTotalLabel(
                  total: entries[i].total,
                  centerX: leftInset + plotWidth * (i + 0.5) / n,
                  barTopY: _topLabelHeight + plotHeight * (1 - entries[i].total / maxY),
                ),
            // Painted last → on top, so the tooltip hides the labels under it.
            chart,
          ],
        );
      },
    );
  }

  /// A single total label, or an empty box when the total is 0.
  Widget _buildTotalLabel({
    required int total,
    required double centerX,
    required double barTopY,
  }) {
    if (total <= 0) return const SizedBox.shrink();
    return Positioned(
      left: centerX - _totalLabelWidth / 2,
      top: (barTopY - _totalLabelHeight).clamp(0.0, double.infinity).toDouble(),
      width: _totalLabelWidth,
      child: Text(
        '$total',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  List<_StackedEntry> _entries() {
    final registered = _daily ? dailyRegistered : monthlyRegistered;
    final guest = _daily ? dailyGuest : monthlyGuest;
    final keys = {...registered.keys, ...guest.keys}.toList()..sort();
    return [
      for (final key in keys)
        _StackedEntry(key, registered[key] ?? 0, guest[key] ?? 0),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return ChartCard.loadingPlaceholder();

    final entries = _entries();
    // The x-axis labels reuse ChartCard.xAxisLabel, which keys off a
    // List<MapEntry<String, int>>; the total is irrelevant for the label.
    final labelEntries = [for (final e in entries) MapEntry(e.key, e.total)];
    final maxVal = entries.isEmpty
        ? 0
        : entries.map((e) => e.total).reduce((a, b) => a > b ? a : b);
    // Pick a gridline interval that works for both the small daily counts and
    // the larger monthly totals (aim for ~5 gridlines).
    final interval = math.max(1, (maxVal / 5).ceil()).toDouble();
    final maxY = maxVal + interval;

    return LayoutBuilder(
      builder: (context, constraints) {
        final neededWidth = entries.length * _minWidthPerBar;
        final needsScroll = neededWidth > constraints.maxWidth;

        final chart = needsScroll
            ? _buildStickyScrollChart(
                entries, labelEntries, maxY, interval, neededWidth)
            : _withTotalLabels(
                chart: BarChart(_buildBarChartData(
                    entries, labelEntries, maxY, interval,
                    showLeftAxis: true)),
                entries: entries,
                maxY: maxY,
                leftInset: _leftAxisWidth,
              );

        return ChartCard(
          titleWidget: _buildTitle(),
          height: 360,
          chart: chart,
        );
      },
    );
  }

  Widget _buildTitle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const Text(
          'מספר שאלונים שהוגשו לפי ',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Container(
          decoration: BoxDecoration(
            color: ColorConstants.primaryScaffoldBckgrndColor,
            border:
                Border.all(color: ColorConstants.chartBorderColor, width: 1),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<bool>(
              value: _daily,
              isDense: true,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: ColorConstants.chartDropdownTextColor,
              ),
              items: const [
                DropdownMenuItem(value: false, child: Text('חודש')),
                DropdownMenuItem(value: true, child: Text('יום')),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _daily = value);
              },
            ),
          ),
        ),
      ],
    );
  }

  /// Fixed y-axis panel + horizontally scrollable bars side by side.
  Widget _buildStickyScrollChart(
    List<_StackedEntry> entries,
    List<MapEntry<String, int>> labelEntries,
    double maxY,
    double interval,
    double neededWidth,
  ) {
    // Force LTR so the y-axis stays physically on the left regardless of the
    // app's RTL Directionality.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Fixed y-axis: transparent bars keep fl_chart happy; the invisible
          // top (total label) and bottom placeholders reserve the same space as
          // the right chart so both bar areas sit at exactly the same height.
          SizedBox(
            width: _yAxisPanelWidth,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: _topLabelHeight,
                      getTitlesWidget: (_, __) => const SizedBox(),
                    ),
                  ),
                  rightTitles: ChartCard.hiddenAxis(),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      getTitlesWidget: (_, __) => const SizedBox(),
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 60,
                      interval: interval,
                      getTitlesWidget: (value, meta) =>
                          ChartCard.yAxisLabel(value),
                    ),
                  ),
                ),
                barGroups: List.generate(
                  entries.length,
                  (i) => BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                          toY: 0, width: 0, color: ColorConstants.transparent)
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Scrollable bars with y-axis hidden.
          Expanded(
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                dragDevices: {
                  PointerDeviceKind.touch,
                  PointerDeviceKind.mouse,
                },
              ),
              child: Scrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: neededWidth,
                    child: _withTotalLabels(
                      chart: BarChart(_buildBarChartData(
                          entries, labelEntries, maxY, interval,
                          showLeftAxis: false)),
                      entries: entries,
                      maxY: maxY,
                      leftInset: 0,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartData _buildBarChartData(
    List<_StackedEntry> entries,
    List<MapEntry<String, int>> labelEntries,
    double maxY,
    double interval, {
    required bool showLeftAxis,
  }) {
    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: maxY,
      barTouchData: BarTouchData(
        enabled: true,
        touchTooltipData: BarTouchTooltipData(
          fitInsideVertically: true,
          fitInsideHorizontally: true,
          getTooltipColor: (_) => ColorConstants.chartTooltipBackground,
          tooltipBorder:
              BorderSide(color: ColorConstants.chartBorderColor, width: 1),
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            final e = entries[groupIndex];
            return BarTooltipItem(
              '',
              const TextStyle(),
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              children: [
                TextSpan(
                  text: '${DashboardLabels.registeredUsersTooltip}: '
                      '${e.registered}\n',
                  style: const TextStyle(
                    color: ColorConstants.registeredUsersQuizColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                TextSpan(
                  text: '${DashboardLabels.guestsSection}: ${e.guest}\n',
                  style: const TextStyle(
                    color: ColorConstants.guestsQuizColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                TextSpan(
                  text: 'סה"כ: ${e.total}',
                  style: const TextStyle(
                    color: ColorConstants.chartTooltipTotalColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            );
          },
        ),
      ),
      gridData: FlGridData(show: true, drawVerticalLine: false),
      borderData: FlBorderData(show: true),
      titlesData: FlTitlesData(
        // Reserve space for the hovering total labels drawn by _withTotalLabels.
        topTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: _topLabelHeight,
            getTitlesWidget: (_, __) => const SizedBox(),
          ),
        ),
        rightTitles: ChartCard.hiddenAxis(),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: _xAxisHeight,
            getTitlesWidget: (value, meta) => ChartCard.xAxisLabel(
                value.toInt(), labelEntries,
                daily: _daily),
          ),
        ),
        leftTitles: showLeftAxis
            ? AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 60,
                  interval: interval,
                  getTitlesWidget: (value, meta) => ChartCard.yAxisLabel(value),
                ),
              )
            : ChartCard.hiddenAxis(),
      ),
      barGroups: List.generate(
        entries.length,
        (i) {
          final e = entries[i];
          // True proportions: each segment is drawn at its real height, so an
          // empty segment has zero height (never visible) and a count of 8 is
          // eight times the height of a count of 1.
          final registered = e.registered.toDouble();
          final total = e.total.toDouble();
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: total,
                width: 22,
                borderRadius: BorderRadius.zero,
                rodStackItems: [
                  BarChartRodStackItem(
                      0, registered, ColorConstants.registeredUsersQuizColor),
                  BarChartRodStackItem(
                      registered, total, ColorConstants.guestsQuizColor),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
