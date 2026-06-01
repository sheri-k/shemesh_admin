import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:shemesh_admin/services/firebase_service.dart';
import 'package:shemesh_admin/widgets/chart_card.dart';

class QuizTotalBarChart extends StatefulWidget {
  const QuizTotalBarChart({super.key});

  @override
  State<QuizTotalBarChart> createState() => _QuizTotalBarChartState();
}

class _QuizTotalBarChartState extends State<QuizTotalBarChart> {
  bool loading = true;
  Map<String, int> monthlyData = {};

  @override
  void initState() {
    super.initState();
    loadData();
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
    final maxValue = entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return ChartCard(
      title: 'מספר שאלונים שהוגשו לפי חודש',
      height: 360,
      chart: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxValue.toDouble() + 10,
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
              barRods: [
                BarChartRodData(
                  toY: entries[i].value.toDouble(),
                  width: 22,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
