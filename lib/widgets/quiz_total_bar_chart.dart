import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:shemesh_admin/services/firebase_service.dart';
import 'package:shemesh_admin/utilities/string_utils.dart';

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
    if (loading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(30),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    final entries = monthlyData.entries.toList();

    final maxValue =
        entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          height: 360,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'מספר שאלונים שהוגשו לפי חודש',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxValue.toDouble() + 10,
                    gridData: FlGridData(show: true, drawVerticalLine: false),
                    borderData: FlBorderData(show: true),
                    titlesData: FlTitlesData(
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: false,
                        ),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: false,
                        ),
                      ),

                      /// X AXIS
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 42,
                          getTitlesWidget: (value, meta) {
                            final i = value.toInt();

                            if (i < 0 || i >= entries.length) {
                              return const SizedBox();
                            }

                            String label =
                                StringUtils.getMonthYearStr(entries[i].key);
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                label,
                                style: const TextStyle(
                                  fontSize: 11,
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      /// Y AXIS
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 60,
                          interval: 10,
                          getTitlesWidget: (value, meta) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: Text(
                                value.toInt().toString(),
                                style: const TextStyle(
                                  fontSize: 11,
                                ),
                              ),
                            );
                          },
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
