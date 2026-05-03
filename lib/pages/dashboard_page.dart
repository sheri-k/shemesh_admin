import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart' as intl;
import 'package:shemesh_admin/config/common_consts.dart';
import 'package:shemesh_admin/pages/dashboard_stats.dart';
import 'package:shemesh_admin/pages/quiz_total_bar_chart.dart';
import 'package:shemesh_admin/pages/user_growth_chart.dart';
import 'package:shemesh_admin/services/firebase_service.dart';
import 'package:shemesh_admin/utilities/debug_log.dart';

class DashboardPage extends StatelessWidget {
  final FirebaseFirestore db = FirebaseService().firestore;

  DashboardPage({super.key});

  Future<QuerySnapshot?> getUsers() async {
    try {
      // Reference to the Firestore document
      //DocumentReference docRef =
      //    FirebaseFirestore.instance.collection(collectionPath).doc(documentId);

      final querySnapshot = await db.collection('users').get();

      return querySnapshot;
    } catch (e) {
      debugLog('[getUsers] Error getting users collection: $e');
      return null;
    }
  }

  Future<int> getTodaysTestCount() async {
    final now = DateTime.now();

    final startOfDay = DateTime(now.year, now.month, now.day);
    final startOfNextDay = startOfDay.add(const Duration(days: 1));

    final snapshot = await FirebaseFirestore.instance
        .collectionGroup('tractate-pages')
        .where(
          'quiz_date',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .where(
          'quiz_date',
          isLessThan: Timestamp.fromDate(startOfNextDay),
        )
        .get();

    return snapshot.docs.length;
  }

  String formatDate(String isoString) {
    DateTime dateTime = DateTime.parse(isoString);
    return intl.DateFormat('dd-MM-yyyy').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    debugLog('DashboardPage: building...');
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
            title: Center(
              child: Text("שמש בגבעון",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ),
            backgroundColor: CommonConsts.appBarColor),
        body: Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                FutureBuilder<DashboardStats>(
                  future: DashboardStats.loadStats(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      debugLog('LoadStats: Waiting for data...');
                      return CircularProgressIndicator();
                    }
                    if (!snapshot.hasData) {
                      debugLog('LoadStats: No data');
                      return CircularProgressIndicator();
                    }

                    if (snapshot.hasError) {
                      return Text("Error: ${snapshot.error}");
                    }

                    debugLog('Got data!');
                    final stats = snapshot.data!;

                    return Wrap(
                      runAlignment: WrapAlignment.end,
                      alignment: WrapAlignment.end,
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        statCard("סה'כ משתמשים", stats.totalUsers.toString(),
                            Colors.blue),
                        statCard("שאלונים שהוגשו היום", stats.quizzesToday.toString(),
                            Colors.brown),
                        statCard(
                            "שאלונים שהוגשו בחודש האחרון",
                            stats.quizzesSubmittedRecently.toString(),
                            Colors.green),
                        statCard(
                            "משתמשים פעילים (${CommonConsts.daysForActiveUsers} ימים)",
                            stats.activeUsers.toString(),
                            Colors.orange),
                        statCard(
                            "משתמשים חדשים (${CommonConsts.daysForNewUsers} ימים אחרונים)",
                            stats.newUsersNDays.toString(),
                            Colors.purple),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 24),

                /// SCROLLABLE CHARTS
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: const [
                        QuizTotalBarChart(),
                        SizedBox(height: 30),
                        UserGrowthChart(),
                        SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget statCard(String title, String value, Color color) {
    return Card(
      elevation: 4,
      child: Container(
        width: 220,
        height: 150,
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 16, color: CommonConsts.primaryTextColor)),
            Spacer(),
            Text(
              value,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
