import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shemesh_admin/config/stat_consts.dart';
import 'package:shemesh_admin/services/firebase_service.dart';
import 'package:shemesh_admin/utilities/debug_log.dart';

class DashboardStats {
  final int totalUsers;
  final int activeUsers;
  final int newUsersNDays;
  final int quizzesSubmittedRecently;
  final int quizzesToday;
  final int quizzesThisCalendarMonth;
  final int totalGuestQuizzes;
  final int totalGuestLogins;
  final int guestQuizzesThisMonth;
  final int guestQuizzesToday;

  DashboardStats({
    required this.totalUsers,
    required this.activeUsers,
    required this.newUsersNDays,
    required this.quizzesSubmittedRecently,
    required this.quizzesToday,
    required this.quizzesThisCalendarMonth,
    required this.totalGuestQuizzes,
    required this.totalGuestLogins,
    required this.guestQuizzesThisMonth,
    required this.guestQuizzesToday,
  });

  static String tag = "DashboardStats";

  /// [excludedUids] is resolved once per dashboard load (see DashboardPage) and
  /// shared with the quiz chart, so the excluded-user lookup runs only once.
  static Future<DashboardStats> loadStats({
    required Future<Set<String>> excludedUids,
  }) async {
    final db = FirebaseService().firestore;

    final now = DateTime.now();
    final nDaysAgoForActiveUsers =
        now.subtract(const Duration(days: StatConsts.daysForActiveUsers));
    final nDaysAgoForNewUsers =
        now.subtract(const Duration(days: StatConsts.daysForNewUsers));

    final nDaysAgoForRecentTests =
        now.subtract(const Duration(days: StatConsts.daysForTestsSubmitted));

    final totalUsersFuture = db.collection('users').count().get();

    debugLog(
        'Getting active users with last_login >= ${nDaysAgoForActiveUsers.toIso8601String()}');

    // Fetch the docs (not just a count) so excluded users can be dropped.
    final activeUsersFuture = db
        .collection('users')
        .where(
          'last_login',
          isGreaterThanOrEqualTo: nDaysAgoForActiveUsers.toIso8601String(),
        )
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

    final startOfMonth = DateTime(now.year, now.month, 1);
    final startOfToday = DateTime(now.year, now.month, now.day);
    final startOfTomorrow = startOfToday.add(const Duration(days: 1));

    // The recent / today / this-calendar-month quiz stats all read test_data
    // over overlapping date ranges. Fetch the widest window once and derive
    // each count in memory, instead of reading the overlapping docs three
    // times.
    final earliestQuizWindow = startOfMonth.isBefore(nDaysAgoForRecentTests)
        ? startOfMonth
        : nDaysAgoForRecentTests;
    debugLog(
        name: tag,
        'Getting test_data with quiz_date >= ${earliestQuizWindow.toIso8601String()}');
    final testDataDocsFuture = db
        .collectionGroup('test_data')
        .where(
          'quiz_date',
          isGreaterThanOrEqualTo: Timestamp.fromDate(earliestQuizWindow),
        )
        .get();

    final guestQuizzesSubmittedFuture =
        db.collection('analytics').doc('guest_stats').get();

    final guestLoginsFuture =
        db.collection('analytics').doc('guest_stats').get();

    final currentMonthId =
        '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final guestQuizzesThisMonthFuture = db
        .collection('analytics')
        .doc('guest_stats')
        .collection('monthly')
        .doc(currentMonthId)
        .get();

    final currentDayId =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final guestQuizzesTodayFuture = db
        .collection('analytics')
        .doc('guest_stats')
        .collection('daily')
        .doc(currentDayId)
        .get();

    debugLog('After getting collectionGroup');

    final results = await Future.wait([
      _safeRun("totalUsers", totalUsersFuture),
      _safeRun("activeUsers", activeUsersFuture),
      _safeRun("newUsers", newUsersFuture),
      _safeRun("testData", testDataDocsFuture),
      _safeRun("totalGuestLogins", guestLoginsFuture),
      _safeRun("totalGuestQuizzes", guestQuizzesSubmittedFuture),
      _safeRun("guestQuizzesThisMonth", guestQuizzesThisMonthFuture),
      _safeRun("guestQuizzesToday", guestQuizzesTodayFuture),
      // Resolved once per dashboard load; reused by every excluded stat below.
      _safeRun("excludedUids", excludedUids),
    ]);

    debugLog('Using collectionGroup: done');

    final activeUsersSnap = results[1] as QuerySnapshot;
    final testDataSnap = results[3] as QuerySnapshot;
    final excludedUidsSet = results[8] as Set<String>;

    return DashboardStats(
      totalUsers: results[0].count!,
      activeUsers: _countUsersExcluding(activeUsersSnap, excludedUidsSet),
      newUsersNDays: results[2].count!,
      quizzesSubmittedRecently: _countTestData(
        testDataSnap,
        excludedUidsSet,
        (d) => !d.isBefore(nDaysAgoForRecentTests),
      ),
      quizzesToday: _countTestData(
        testDataSnap,
        excludedUidsSet,
        (d) => !d.isBefore(startOfToday) && d.isBefore(startOfTomorrow),
      ),
      totalGuestLogins:
          (results[4].data() as Map<String, dynamic>?)?['totalGuestLogins'] ??
              0,
      totalGuestQuizzes:
          (results[5].data() as Map<String, dynamic>?)?['totalGuestQuizzes'] ??
              0,
      guestQuizzesThisMonth:
          (results[6].data() as Map<String, dynamic>?)?['guestQuizzes'] ?? 0,
      quizzesThisCalendarMonth: _countTestData(
        testDataSnap,
        excludedUidsSet,
        (d) => !d.isBefore(startOfMonth),
      ),
      guestQuizzesToday:
          (results[7].data() as Map<String, dynamic>?)?['guestQuizzes'] ?? 0,
    );
  }

  /// Counts test_data docs whose quiz_date satisfies [matches], skipping any
  /// whose owning user (stored at `users/{uid}/test_data`) is in [excludedUids].
  static int _countTestData(
    QuerySnapshot snap,
    Set<String> excludedUids,
    bool Function(DateTime quizDate) matches,
  ) {
    var count = 0;
    for (final doc in snap.docs) {
      final ts = doc['quiz_date'] as Timestamp;
      if (!matches(ts.toDate())) continue;
      final uid = doc.reference.parent.parent?.id;
      if (uid != null && excludedUids.contains(uid)) continue;
      count++;
    }
    return count;
  }

  /// Counts user docs, skipping any whose id (the uid) is in [excludedUids].
  static int _countUsersExcluding(
      QuerySnapshot snap, Set<String> excludedUids) {
    if (excludedUids.isEmpty) return snap.docs.length;
    var count = 0;
    for (final doc in snap.docs) {
      if (!excludedUids.contains(doc.id)) count++;
    }
    return count;
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
