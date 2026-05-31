import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart' as intl;
import 'package:shemesh_admin/config/common_consts.dart';
import 'package:shemesh_admin/pages/dashboard_stats.dart';
import 'package:shemesh_admin/pages/quiz_total_bar_chart.dart';
import 'package:shemesh_admin/pages/scan_collection.dart';
import 'package:shemesh_admin/pages/user_growth_chart.dart';
import 'package:shemesh_admin/services/firebase_service.dart';
import 'package:shemesh_admin/utilities/debug_log.dart';

class DashboardPage extends StatefulWidget {
  DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final FirebaseFirestore _db = FirebaseService().firestore;
  late Future<DashboardStats> _futureStats; // Declare _futureStats

  static const Color actionButtonColor = Color(0xFFB9E192);
  static const Color secondaryActionButtonColor = Color(0xFFCBD3E7);
  static const Color primaryTextColor = Color(0xFF263554);

  @override
  void initState() {
    super.initState();
    // Initialize _futureStats with the data-fetching function
    _futureStats = DashboardStats.loadStats();
  }

  void scanQuestions() async {
    await ScanCollection().scan();
  }

  @override
  Widget build(BuildContext context) {
    debugLog('DashboardPage: building...');
    //scanQuestions(); // Run the scan when the dashboard builds
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
                  future: _futureStats, //DashboardStats.loadStats(),
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

                    return Column(
                      children: [
                        // Refresh button
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              // Trigger a refresh of the data
                              _futureStats = DashboardStats
                                  .loadStats(); //  fetchStatsFromDatabase();
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                actionButtonColor, // very light blue
                            foregroundColor: primaryTextColor,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                          child: const Text(
                            'רענן נתונים',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: primaryTextColor,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),
                        Wrap(
                          runAlignment: WrapAlignment.end,
                          alignment: WrapAlignment.end,
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            statCard("סה'כ משתמשים",
                                stats.totalUsers.toString(), Colors.blue),
                            statCard("שאלונים שהוגשו היום",
                                stats.quizzesToday.toString(), Colors.brown),
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
                            statCard(
                                "סך השאלונים שהוגשו על ידי אורחים",
                                stats.totalGuestQuizzes.toString(),
                                Colors.deepPurple),
                            statCard(
                                "סך כניסות כאורח",
                                stats.totalGuestLogins.toString(),
                                Colors.deepPurple),
                          ],
                        ),
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
            Text(title,
                style: TextStyle(
                    fontSize: 16, color: CommonConsts.primaryTextColor)),
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
