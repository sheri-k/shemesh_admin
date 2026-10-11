import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:shemesh_admin/config/common_consts.dart';
import 'package:shemesh_admin/config/stat_consts.dart';
import 'package:shemesh_admin/services/firebase_service.dart';
import 'package:shemesh_admin/utilities/debug_log.dart';
import 'package:shemesh_admin/widgets/chart_card.dart';

const double _minWidthPerBar = 55.0;
const double _yAxisPanelWidth = 64.0;

// Debug only: when true, logs the user ids that submitted a quiz on each day.
const bool _logDailySubmitters = false;

class QuizTotalBarChart extends StatefulWidget {
  const QuizTotalBarChart({super.key});

  @override
  State<QuizTotalBarChart> createState() => _QuizTotalBarChartState();
}

class _QuizTotalBarChartState extends State<QuizTotalBarChart> {
  bool loading = true;
  bool _daily = false;
  Map<String, int> monthlyData = {};
  Map<String, int> dailyData = {};
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
    final snap = await db.collectionGroup('test_data').get();

    final Map<String, int> monthlyCounts = {};

    // Pre-seed the last N days with 0 so every calendar day shows a bar, even
    // days with no submissions. Keyed YYYY-MM-DD.
    final Map<String, int> dailyCounts = {};
    // Debug only: user ids that submitted a quiz on each day in the window.
    final Map<String, List<String>> dailyUserIds = {};
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    final windowStart =
        startOfToday.subtract(Duration(days: StatConsts.daysForDailyChart - 1));
    for (int i = 0; i < StatConsts.daysForDailyChart; i++) {
      final d = windowStart.add(Duration(days: i));
      dailyCounts[_dayKey(d)] = 0;
      if (_logDailySubmitters) dailyUserIds[_dayKey(d)] = [];
    }

    for (final doc in snap.docs) {
      final ts = doc['quiz_date'] as Timestamp;
      final date = ts.toDate();

      final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      monthlyCounts[monthKey] = (monthlyCounts[monthKey] ?? 0) + 1;

      final dayKey = _dayKey(date);
      if (dailyCounts.containsKey(dayKey)) {
        dailyCounts[dayKey] = dailyCounts[dayKey]! + 1;
        if (_logDailySubmitters) {
          // test_data is a subcollection of the user doc: users/{uid}/test_data.
          final uid = doc.reference.parent.parent?.id ?? '(unknown)';
          dailyUserIds[dayKey]!.add(uid);
        }
      }
    }

    if (_logDailySubmitters) _logDailyUserIds(dailyUserIds);

    setState(() {
      monthlyData = _sortedByKey(monthlyCounts);
      dailyData = _sortedByKey(dailyCounts);
      loading = false;
    });
  }

  // Debug only: dumps, per day, the user ids that submitted a quiz.
  void _logDailyUserIds(Map<String, List<String>> dailyUserIds) {
    final keys = dailyUserIds.keys.toList()..sort();
    debugLog('Quiz submitters by day (last ${StatConsts.daysForDailyChart} days):');
    for (final key in keys) {
      final uids = dailyUserIds[key]!;
      debugLog('$key (${uids.length}): ${uids.join(', ')}');
    }
  }

  static String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static Map<String, int> _sortedByKey(Map<String, int> counts) =>
      Map.fromEntries(
        counts.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
      );

  @override
  Widget build(BuildContext context) {
    if (loading) return ChartCard.loadingPlaceholder();

    final entries = (_daily ? dailyData : monthlyData).entries.toList();
    final maxVal = entries.isEmpty
        ? 0
        : entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    // Pick a gridline interval that works for both the small daily counts and
    // the larger monthly totals (aim for ~5 gridlines).
    final interval = math.max(1, (maxVal / 5).ceil()).toDouble();
    final maxY = maxVal + interval;

    return LayoutBuilder(
      builder: (context, constraints) {
        final neededWidth = entries.length * _minWidthPerBar;
        final needsScroll = neededWidth > constraints.maxWidth;

        final chart = needsScroll
            ? _buildStickyScrollChart(entries, maxY, interval, neededWidth)
            : BarChart(_buildBarChartData(entries, maxY, interval,
                showLeftAxis: true));

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
            color: CommonConsts.primaryScaffoldBckgrndColor,
            border: Border.all(color: Colors.grey.shade400, width: 1),
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
                color: Colors.black,
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
    List<MapEntry<String, int>> entries,
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
        // bottom placeholder reserves the same 42 px as the right chart so
        // both bar areas sit at exactly the same vertical height.
        SizedBox(
          width: _yAxisPanelWidth,
          child: BarChart(
            BarChartData(
              maxY: maxY,
              gridData: FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: ChartCard.hiddenAxis(),
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
                    getTitlesWidget: (value, meta) => ChartCard.yAxisLabel(value),
                  ),
                ),
              ),
              barGroups: List.generate(
                entries.length,
                (i) => BarChartGroupData(
                  x: i,
                  barRods: [BarChartRodData(toY: 0, width: 0, color: Colors.transparent)],
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
                  child: BarChart(_buildBarChartData(entries, maxY, interval,
                      showLeftAxis: false)),
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
    List<MapEntry<String, int>> entries,
    double maxY,
    double interval, {
    required bool showLeftAxis,
  }) {
    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: maxY,
      // Disable touch when in scroll mode so fl_chart doesn't consume the
      // horizontal drag events that SingleChildScrollView needs.
      barTouchData: BarTouchData(
        enabled: true,
        touchTooltipData: BarTouchTooltipData(
          fitInsideVertically: true,
          fitInsideHorizontally: true,
        ),
      ),
      gridData: FlGridData(show: true, drawVerticalLine: false),
      borderData: FlBorderData(show: true),
      titlesData: FlTitlesData(
        topTitles: ChartCard.hiddenAxis(),
        rightTitles: ChartCard.hiddenAxis(),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 42,
            getTitlesWidget: (value, meta) =>
                ChartCard.xAxisLabel(value.toInt(), entries, daily: _daily),
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
        (i) => BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: entries[i].value.toDouble(),
              width: 22,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      ),
    );
  }
}
