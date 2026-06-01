import 'package:flutter/material.dart';
import 'package:shemesh_admin/config/common_consts.dart';

const double _cardWidth = 220;
const double _cardHeight = 150;
const double _cardPadding = 20;
const double _titleFontSize = 16;
const double _valueFontSize = 32;

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
      child: Container(
        width: _cardWidth,
        height: _cardHeight,
        padding: const EdgeInsets.all(_cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: _titleFontSize, color: CommonConsts.primaryTextColor)),
            const Spacer(),
            Text(
              value,
              style: TextStyle(fontSize: _valueFontSize, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
