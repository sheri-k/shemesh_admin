import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shemesh_admin/config/common_consts.dart';
import 'package:shemesh_admin/services/firebase_service.dart';
import 'package:shemesh_admin/utilities/debug_log.dart';

class DashboardStats {
  final int totalUsers;
  final int activeUsers;
  final int newUsersNDays;
  final int testsSubmittedRecently;

  DashboardStats({
    required this.totalUsers,
    required this.activeUsers,
    required this.newUsersNDays,
    required this.testsSubmittedRecently,
  });

  static Future<DashboardStats> loadStats() async {
    final db = FirebaseService().firestore;

    final now = DateTime.now();
    final nDaysAgoForActiveUsers =
        now.subtract(const Duration(days: CommonConsts.daysForActiveUsers));
    final nDaysAgoForNewUsers =
        now.subtract(const Duration(days: CommonConsts.daysForNewUsers));

    final nDaysAgoForRecentTests =
        now.subtract(const Duration(days: CommonConsts.daysForTestsSubmitted));

    final startOfMonth = DateTime(now.year, now.month, 1);

    final totalUsersFuture = db.collection('users').count().get();

    debugLog(
        'Getting active users with last_login >= ${nDaysAgoForActiveUsers.toIso8601String()}');

    final activeUsersFuture = db
        .collection('users')
        .where(
          'last_login',
          isGreaterThanOrEqualTo: nDaysAgoForActiveUsers.toIso8601String(),
        )
        .count()
        .get();

    debugLog(
        'Getting newUsersFuture with date_of_registration >= ${nDaysAgoForNewUsers.toIso8601String()}');

    final newUsersFuture = db
        .collection('users')
        .where(
          'date_of_registration',
          isGreaterThanOrEqualTo: nDaysAgoForNewUsers.toIso8601String(),
        )
        .count()
        .get();

    debugLog('Getting collectionGroup for test_data');

    final testsFuture = db
        .collectionGroup('test_data')
        .where(
          'quiz_date',
          isGreaterThanOrEqualTo: Timestamp.fromDate(nDaysAgoForRecentTests),
        )
        .count()
        .get();

    debugLog('After getting collectionGroup');

    final results = await Future.wait([
      _safeRun("totalUsers", totalUsersFuture),
      _safeRun("activeUsers", activeUsersFuture),
      _safeRun("newUsers", newUsersFuture),
      _safeRun("tests", testsFuture),
    ]);

    debugLog('Using collectionGroup: done');

    return DashboardStats(
      totalUsers: results[0].count!,
      activeUsers: results[1].count!,
      newUsersNDays: results[2].count!,
      testsSubmittedRecently: results[3].count!,
    );
  }

  static Future _safeRun(String name, Future future) async {
    try {
      return await future;
    } catch (e, stack) {
      debugLog("FAILED FUTURE: $name");
      debugLog(e.toString());
      debugLog(stack.toString());
      rethrow; // keeps Future.wait failing
    }
  }
}
