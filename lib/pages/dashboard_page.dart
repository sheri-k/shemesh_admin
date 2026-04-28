import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart' as intl;
import 'package:shemesh_admin/config/common_consts.dart';
import 'package:shemesh_admin/pages/dashboard_stats.dart';
import 'package:shemesh_admin/pages/dashboard_stats.dart';
import 'package:shemesh_admin/services/firebase_service.dart';
import 'package:shemesh_admin/utilities/debug_log.dart';
//import 'package:intl/intl.dart';

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
            backgroundColor: Colors.blue),
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
                        statCard(
                            "מבחנים שהוגשו בחודש האחרון",
                            stats.testsSubmittedRecently.toString(),
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

                /// Top Stats
                // FutureBuilder<QuerySnapshot?>(
                //   future: getUsers(),
                //   builder: (context, snapshot) {
                //     if (snapshot.connectionState == ConnectionState.waiting) {
                //       print('Waiting for data...');
                //       return CircularProgressIndicator();
                //     }
                //     if (!snapshot.hasData) {
                //       print('No data');
                //       return CircularProgressIndicator();
                //     }

                //     if (snapshot.hasError) {
                //       return Text("Error: ${snapshot.error}");
                //     }

                //     int totalUsers = snapshot.data!.docs.length;

                //     return Row(
                //       children: [
                //         statCard("Users", totalUsers.toString(), Colors.blue),
                //       ],
                //     );
                //   },
                // ),

                SizedBox(height: 30),

                /// Users Table
                // Expanded(
                //   child: StreamBuilder<QuerySnapshot>(
                //     stream: db.collection('users').snapshots(),
                //     builder: (context, snapshot) {
                //       if (!snapshot.hasData) {
                //         return Center(child: CircularProgressIndicator());
                //       }

                //       var users = snapshot.data!.docs;

                //       return SingleChildScrollView(
                //         child: DataTable(
                //           columns: [
                //             DataColumn(label: Text("שם")),
                //             DataColumn(label: Text("כתובת אימייל")),
                //             //DataColumn(label: Text("Tests Done")),
                //             DataColumn(label: Text("כניסה אחרונה")),
                //           ],
                //           rows: users.map((user) {
                //             var data = user.data() as Map<String, dynamic>;

                //             String name = data['display_name'] ?? '';
                //             String email = data['email_address'] ?? '';
                //             //int tests = data['testsDone'] ?? 0;
                //             String ts = data['last_login'];
                //             //Timestamp? ts = data['last_login'];
                //             /*
                //             lastLogin: DateTime.parse(map['last_login']),
                //             */
                //             // String lastLogin = ts != null
                //             //     ? intl.DateFormat('dd/MM/yyyy').format(ts.toDate())
                //             //     : '';

                //             String lastLogin = formatDate(ts);

                //             return DataRow(
                //               cells: [
                //                 DataCell(Text(name)),
                //                 DataCell(Text(email)),
                //                 //DataCell(Text(tests.toString())),
                //                 DataCell(Text(lastLogin)),
                //               ],
                //             );
                //           }).toList(),
                //         ),
                //       );
                //     },
                //   ),
                // ),
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
            Text(title, style: TextStyle(fontSize: 16, color: Colors.grey)),
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
