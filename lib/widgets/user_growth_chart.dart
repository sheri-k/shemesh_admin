import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:shemesh_admin/services/firebase_service.dart';
import 'package:shemesh_admin/utilities/debug_log.dart';
import 'package:shemesh_admin/widgets/chart_card.dart';

class UserGrowthChart extends StatefulWidget {
  const UserGrowthChart({super.key});

  @override
  State<UserGrowthChart> createState() => _UserGrowthChartState();
}

class _UserGrowthChartState extends State<UserGrowthChart> {
  final String tag = 'UserGrowthChart';
  bool loading = true;
  Map<String, int> monthlyTotals = {};

  @override
  void initState() {
    super.initState();
    loadData();
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
      debugLog(name: tag, 'Key: $key');
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
    final maxValue = entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final height = ((entries.length * 20 + maxValue * 2).clamp(220, 450)).toDouble();

    return ChartCard(
      title: 'גידול במספר המשתמשים',
      height: height,
      chart: LineChart(
        LineChartData(
          maxY: ((maxValue / 5).ceil() * 5).toDouble(),
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
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 60,
                interval: 10,
                getTitlesWidget: (value, meta) => ChartCard.yAxisLabel(value),
              ),
            ),
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
        ),
      ),
    );
  }
}
