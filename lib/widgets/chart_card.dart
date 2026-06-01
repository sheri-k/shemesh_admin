import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:shemesh_admin/utilities/string_utils.dart';

class ChartCard extends StatelessWidget {
  final String title;
  final double height;
  final Widget chart;

  const ChartCard({
    super.key,
    required this.title,
    required this.height,
    required this.chart,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          height: height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Expanded(child: chart),
            ],
          ),
        ),
      ),
    );
  }

  static Widget loadingPlaceholder() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(30),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }

  static AxisTitles hiddenAxis() {
    return AxisTitles(sideTitles: SideTitles(showTitles: false));
  }

  static Widget xAxisLabel(int index, List<MapEntry<String, int>> entries) {
    if (index < 0 || index >= entries.length) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        StringUtils.getMonthYearStr(entries[index].key),
        style: const TextStyle(fontSize: 11),
      ),
    );
  }

  static Widget yAxisLabel(double value) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Text(
        value.toInt().toString(),
        style: const TextStyle(fontSize: 11),
      ),
    );
  }
}
