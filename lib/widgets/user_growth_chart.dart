import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:shemesh_admin/services/firebase_service.dart';
import 'package:shemesh_admin/utilities/debug_log.dart';
import 'package:shemesh_admin/widgets/chart_card.dart';

const double _minWidthPerPoint = 55.0;
const double _yAxisPanelWidth = 64.0;

class UserGrowthChart extends StatefulWidget {
  const UserGrowthChart({super.key});

  @override
  State<UserGrowthChart> createState() => _UserGrowthChartState();
}

class _UserGrowthChartState extends State<UserGrowthChart> {
  final String tag = 'UserGrowthChart';
  bool loading = true;
  Map<String, int> monthlyTotals = {};
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
    final snap = await FirebaseService().firestore.collection('users').get();

    Map<String, int> registrations = {};
    DateTime? earliest;
    final now = DateTime.now();

    for (final doc in snap.docs) {
      final data = doc.data();
      if (data['date_of_registration'] == null) continue;

      DateTime date;
      if (data['date_of_registration'] is Timestamp) {
        date = (data['date_of_registration'] as Timestamp).toDate();
      } else {
        date = DateTime.parse(data['date_of_registration']);
      }

      earliest ??= date;
      if (date.isBefore(earliest)) earliest = date;

      final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      //debugLog(name: tag, 'Key: $key');
      registrations[key] = (registrations[key] ?? 0) + 1;
    }

    if (earliest == null) return;

    debugLog(name: tag, 'Earliest registration: $earliest');

    DateTime current = DateTime(earliest.year, earliest.month);
    final lastMonth = DateTime(now.year, now.month);

    Map<String, int> totals = {};
    int runningTotal = 0;

    while (!current.isAfter(lastMonth)) {
      final key = '${current.year}-${current.month.toString().padLeft(2, '0')}';
      runningTotal += registrations[key] ?? 0;
      totals[key] = runningTotal;
      current = DateTime(current.year, current.month + 1);
    }

    setState(() {
      monthlyTotals = totals;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return ChartCard.loadingPlaceholder();

    final entries = monthlyTotals.entries.toList();
    final maxValue =
        entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final maxY = ((maxValue / 5).ceil() * 5).toDouble();
    final height =
        ((entries.length * 20 + maxValue * 2).clamp(220, 450)).toDouble();

    return LayoutBuilder(
      builder: (context, constraints) {
        final neededWidth = entries.length * _minWidthPerPoint;
        final needsScroll = neededWidth > constraints.maxWidth;

        final chart = needsScroll
            ? _buildStickyScrollChart(entries, maxY, neededWidth)
            : LineChart(_buildLineChartData(entries, maxY, showLeftAxis: true));

        return ChartCard(
          title: 'גידול במספר המשתמשים',
          height: height,
          chart: chart,
        );
      },
    );
  }

  /// Fixed y-axis panel + horizontally scrollable line chart side by side.
  Widget _buildStickyScrollChart(
    List<MapEntry<String, int>> entries,
    double maxY,
    double neededWidth,
  ) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Fixed y-axis: a transparent line anchors the y-range; the invisible
          // bottom placeholder reserves the same 42 px as the right chart so
          // both chart areas sit at the same vertical height.
          SizedBox(
            width: _yAxisPanelWidth,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY,
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(enabled: false),
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
                      getTitlesWidget: (value, meta) =>
                          ChartCard.yAxisLabel(value),
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      FlSpot(0, 0),
                      FlSpot((entries.length - 1).toDouble(), 0),
                    ],
                    color: Colors.transparent,
                    dotData: FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
          // Scrollable line chart with y-axis hidden.
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
                    child: LineChart(
                      _buildLineChartData(entries, maxY, showLeftAxis: false),
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

  LineChartData _buildLineChartData(
    List<MapEntry<String, int>> entries,
    double maxY, {
    required bool showLeftAxis,
  }) {
    return LineChartData(
      maxY: maxY,
      lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          fitInsideVertically: true,
          fitInsideHorizontally: true,
        ),
      ),
      gridData: FlGridData(show: true),
      borderData: FlBorderData(show: true),
      titlesData: FlTitlesData(
        topTitles: ChartCard.hiddenAxis(),
        rightTitles: ChartCard.hiddenAxis(),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 42,
            interval: 1,
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
      lineBarsData: [
        LineChartBarData(
          isCurved: false,
          barWidth: 4,
          dotData: FlDotData(show: true),
          spots: List.generate(
            entries.length,
            (i) => FlSpot(i.toDouble(), entries[i].value.toDouble()),
          ),
        ),
      ],
    );
  }
}
