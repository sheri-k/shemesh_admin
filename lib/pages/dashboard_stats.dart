import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shemesh_admin/services/firebase_service.dart';

class DashboardStats {
  final int totalUsers;
  final int activeUsers;
  final int newUsers30Days;
  final int testsThisMonth;

  DashboardStats({
    required this.totalUsers,
    required this.activeUsers,
    required this.newUsers30Days,
    required this.testsThisMonth,
  });

  static Future<DashboardStats> loadStats() async {
    final FirebaseFirestore db = FirebaseService().firestore;

    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(Duration(days: 30));

    final startOfMonth = DateTime(now.year, now.month, 1);

    /// USERS
    final usersSnap = await db.collection('users').get();

    int totalUsers = usersSnap.docs.length;
    int activeUsers = 0;
    int newUsers30Days = 0;

    print('totalUsers: $totalUsers');

    for (var doc in usersSnap.docs) {
      final data = doc.data();

      final lastLogin = DateTime.tryParse(data['last_login'] ?? '');
      final regDate = DateTime.tryParse(data['date_of_registration'] ?? '');

      if (lastLogin != null &&
          lastLogin.isAfter(now.subtract(Duration(days: 30)))) {
        activeUsers++;
      }

      if (regDate != null && regDate.isAfter(thirtyDaysAgo)) {
        newUsers30Days++;
      }
    }

    /// TESTS THIS MONTH
    print('getting test_data collection group...');
    // final testsSnap = await db
    //     .collectionGroup('test_data')
    //     .where('quiz_date',
    //         isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
    //     .get();

    print('Returned form getting test_data collection group...');
    //int testsThisMonth = testsSnap.docs.length;
    

    int testsThisMonth = await _getTestsThisMonth();
    print('testsThisMonth: $testsThisMonth');

    return DashboardStats(
      totalUsers: totalUsers,
      activeUsers: activeUsers,
      newUsers30Days: newUsers30Days,
      testsThisMonth: testsThisMonth,
    );
  }

  static Future<int> _getTestsThisMonth() async {
    final db = FirebaseFirestore.instance;

    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    int totalTests = 0;

    /// Get all users
    final usersSnap = await db.collection('users').get();

    for (final userDoc in usersSnap.docs) {
      final uid = userDoc.id;

      final testsSnap = await db
          .collection('users')
          .doc(uid)
          .collection('test_data')
          .where(
            'quiz_date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth),
          )
          .get();

      totalTests += testsSnap.docs.length;
    }

    return totalTests;
  }
}
