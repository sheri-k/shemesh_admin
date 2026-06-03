import 'package:shemesh_admin/config/stat_consts.dart';

class DashboardLabels {
  static const String totalUsers = "סה'כ משתמשים רשומים";
  static const String quizzesToday = 'שאלונים שהוגשו היום';
  static const String quizzesThisMonth = 'שאלונים שהוגשו בחודש האחרון';
  static const String activeUsers = 'משתמשים רשומים פעילים (${StatConsts.daysForActiveUsers}   ימים אחרונים)';
  static const String newUsers = 'משתמשים חדשים (${StatConsts.daysForNewUsers} ימים אחרונים)';
  static const String totalGuestQuizzes = 'סך השאלונים שהוגשו על ידי אורחים';
  static const String totalGuestLogins = 'סך כניסות כאורח';
}
