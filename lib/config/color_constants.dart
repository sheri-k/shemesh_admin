import 'package:flutter/material.dart';

class ColorConstants {
  // App palette
  static const Color primaryScaffoldBckgrndColor = Color(0xFFFBFCFF);
  static const Color secondaryScaffoldBckgrndColor = Color(0xFFEAEDF5);
  static const Color primaryTextColor = Color(0xFF263554);
  static const Color appBarColor = Color(0xFFCBD3E7);
  static const Color actionButtonColor = Color(0xFFB9E192);
  static const Color progressIndicatorColor = Colors.black12;

  // Registered-users vs. guests (shared by the stat cards and the stacked
  // quiz chart). The *QuizColor variants are used for quiz-submission metrics.
  static const Color registeredUsersColor = Color(0xFF00BCD4);
  static const Color guestsColor = Color(0xFF9F4F00);
  static const Color registeredUsersQuizColor = Color(0xFF06296F);
  static const Color guestsQuizColor = Color(0xfff47A00);

  // Quiz-submissions bar chart
  static const Color chartTooltipBackground = Colors.white;
  static const Color chartTooltipTotalColor = Colors.black;
  static const Color chartDropdownTextColor = Colors.black;
  static final Color chartBorderColor = Colors.grey.shade400;

  // Neutral / utility colors
  static const Color transparent = Colors.transparent;
  static const Color errorTextColor = Colors.red;
}
