import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:shemesh_admin/config/common_consts.dart';
import 'package:shemesh_admin/utilities/string_utils.dart';

class ChartCard extends StatelessWidget {
  final String title;
  final double height;
  final Widget chart;

  // When provided, rendered instead of Text(title) — lets the title embed
  // interactive widgets (e.g. the monthly/daily dropdown).
  final Widget? titleWidget;

  final Color backgroundColor;

  const ChartCard({
    super.key,
    this.title = '',
    required this.height,
    required this.chart,
    this.titleWidget,
    this.backgroundColor = CommonConsts.primaryScaffoldBckgrndColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      color: backgroundColor,
      surfaceTintColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          height: height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              titleWidget ??
                  Text(title,
                      textAlign: TextAlign.start,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
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
      color: CommonConsts.primaryScaffoldBckgrndColor,
      surfaceTintColor: Colors.transparent,
      child: Padding(
        padding: EdgeInsets.all(30),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }

  static AxisTitles hiddenAxis() {
    return AxisTitles(sideTitles: SideTitles(showTitles: false));
  }

  static Widget xAxisLabel(
    int index,
    List<MapEntry<String, int>> entries, {
    bool daily = false,
  }) {
    if (index < 0 || index >= entries.length) return const SizedBox();
    final key = entries[index].key;

    if (daily) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              StringUtils.getHebrewDayLetter(DateTime.parse(key)),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
            Text(
              StringUtils.getDayMonthStr(key),
              style: const TextStyle(fontSize: 11),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        StringUtils.getMonthYearStr(key),
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
