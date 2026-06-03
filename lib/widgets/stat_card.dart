import 'package:flutter/material.dart';
import 'package:shemesh_admin/config/common_consts.dart';

const double _cardPadding = 12;

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final titleFontSize = (constraints.maxWidth * 0.09).clamp(11.0, 17.0);
          final valueFontSize = (constraints.maxWidth * 0.2).clamp(22.0, 36.0);

          return Padding(
            padding: const EdgeInsets.all(_cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: titleFontSize, color: CommonConsts.primaryTextColor),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.bottomRight,
                    child: Text(
                      value,
                      style: TextStyle(fontSize: valueFontSize, fontWeight: FontWeight.bold, color: color),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
