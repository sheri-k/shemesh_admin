import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:shemesh_admin/services/firebase_service.dart';
import 'package:shemesh_admin/widgets/chart_card.dart';

const double _minWidthPerBar = 55.0;
const double _yAxisPanelWidth = 64.0;

class QuizTotalBarChart extends StatefulWidget {
  const QuizTotalBarChart({super.key});

  @override
  State<QuizTotalBarChart> createState() => _QuizTotalBarChartState();
}

class _QuizTotalBarChartState extends State<QuizTotalBarChart> {
  bool loading = true;
  Map<String, int> monthlyData = {};
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

    Map<String, int> counts = {};

    for (final doc in snap.docs) {
      final ts = doc['quiz_date'] as Timestamp;
      final date = ts.toDate();
      final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      counts[key] = (counts[key] ?? 0) + 1;
    }

    final sorted = Map.fromEntries(
      counts.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );

    setState(() {
      monthlyData = sorted;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return ChartCard.loadingPlaceholder();

    final entries = monthlyData.entries.toList();
    final maxY = entries.map((e) => e.value).reduce((a, b) => a > b ? a : b).toDouble() + 10;

    return LayoutBuilder(
      builder: (context, constraints) {
        final neededWidth = entries.length * _minWidthPerBar;
        final needsScroll = neededWidth > constraints.maxWidth;

        final chart = needsScroll
            ? _buildStickyScrollChart(entries, maxY, neededWidth)
            : BarChart(_buildBarChartData(entries, maxY, showLeftAxis: true));

        return ChartCard(
          title: 'מספר שאלונים שהוגשו לפי חודש',
          height: 360,
          chart: chart,
        );
      },
    );
  }

  /// Fixed y-axis panel + horizontally scrollable bars side by side.
  Widget _buildStickyScrollChart(
    List<MapEntry<String, int>> entries,
    double maxY,
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
                    interval: 10,
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
                  child: BarChart(_buildBarChartData(entries, maxY, showLeftAxis: false)),
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
    double maxY, {
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
                ChartCard.xAxisLabel(value.toInt(), entries),
          ),
        ),
        leftTitles: showLeftAxis
            ? AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 60,
                  interval: 10,
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
