import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:shemesh_admin/services/firebase_service.dart';
import 'package:shemesh_admin/utilities/debug_log.dart';
import 'package:shemesh_admin/utilities/string_utils.dart';

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

      if (data['date_of_registration'] == null) {
        continue;
      }

      DateTime date;

      if (data['date_of_registration'] is Timestamp) {
        date = (data['date_of_registration'] as Timestamp).toDate();
      } else {
        date = DateTime.parse(
          data['date_of_registration'],
        );
      }

      // Assign date to earliest if it is null
      earliest ??= date;

      if (date.isBefore(earliest)) {
        earliest = date;
      }

      final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      debugLog(name: tag, 'Key: $key');

      registrations[key] = (registrations[key] ?? 0) + 1;
    }

    if (earliest == null) return;

    debugLog(name: tag, 'Earliest: $earliest');
    DateTime current = DateTime(earliest.year, earliest.month);

    final lastMonth = DateTime(now.year, now.month);

    debugLog(name: tag, 'Earliest registration: $earliest');
    debugLog(name: tag, 'Last month: $lastMonth');

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

    final entries = monthlyTotals.entries.toList();

    final maxValue =
        entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          height: ((entries.length * 20 + maxValue * 2).clamp(220, 450)).toDouble(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'גידול במספר המשתמשים',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: LineChart(
                  LineChartData(
                    maxY: ((maxValue / 5).ceil() * 5).toDouble(),
                    //maxY: maxValue.toDouble() + 5,
                    gridData: FlGridData(show: true),
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
                      ///
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 42,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            final i = value.toInt();

                            if (i < 0 || i >= entries.length) {
                              return const SizedBox();
                            }

                            String label = StringUtils.getMonthYearStr(entries[i].key);
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
                    lineBarsData: [
                      LineChartBarData(
                        isCurved: false,
                        barWidth: 4,
                        dotData: FlDotData(show: true),
                        spots: List.generate(
                          entries.length,
                          (i) => FlSpot(
                            i.toDouble(),
                            entries[i].value.toDouble(),
                          ),
                        ),
                      ),
                    ],
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
