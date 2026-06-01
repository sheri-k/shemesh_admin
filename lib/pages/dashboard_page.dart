import 'package:flutter/material.dart';
import 'package:shemesh_admin/config/common_consts.dart';
import 'package:shemesh_admin/services/dashboard_stats.dart';
import 'package:shemesh_admin/widgets/quiz_total_bar_chart.dart';
import 'package:shemesh_admin/widgets/stat_card.dart';
import 'package:shemesh_admin/widgets/user_growth_chart.dart';
import 'package:shemesh_admin/utilities/debug_log.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late Future<DashboardStats> _futureStats;

  @override
  void initState() {
    super.initState();
    _futureStats = DashboardStats.loadStats();
  }

  void _refreshStats() {
    setState(() {
      _futureStats = DashboardStats.loadStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    debugLog('DashboardPage: building...');
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Center(
            child: Text(
              CommonConsts.appName,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          backgroundColor: CommonConsts.appBarColor,
        ),
        body: Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                FutureBuilder<DashboardStats>(
                  future: _futureStats,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    }
                    if (!snapshot.hasData) {
                      debugLog('LoadStats: waiting for data...');
                      return const CircularProgressIndicator();
                    }
                    return _buildStatsSection(snapshot.data!);
                  },
                ),
                const SizedBox(height: 24),
                const Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
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

  Widget _buildStatsSection(DashboardStats stats) {
    return Column(
      children: [
        _buildRefreshButton(),
        const SizedBox(height: 16),
        _buildStatCards(stats),
      ],
    );
  }

  Widget _buildRefreshButton() {
    return ElevatedButton(
      onPressed: _refreshStats,
      style: ElevatedButton.styleFrom(
        backgroundColor: CommonConsts.actionButtonColor,
        foregroundColor: CommonConsts.primaryTextColor,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
      child: const Text(
        'רענן נתונים',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: CommonConsts.primaryTextColor,
        ),
      ),
    );
  }

  Widget _buildStatCards(DashboardStats stats) {
    return Wrap(
      runAlignment: WrapAlignment.end,
      alignment: WrapAlignment.end,
      spacing: 16,
      runSpacing: 16,
      children: [
        StatCard(title: "סה'כ משתמשים", value: stats.totalUsers.toString(), color: Colors.blue),
        StatCard(title: 'שאלונים שהוגשו היום', value: stats.quizzesToday.toString(), color: Colors.brown),
        StatCard(title: 'שאלונים שהוגשו בחודש האחרון', value: stats.quizzesSubmittedRecently.toString(), color: Colors.green),
        StatCard(title: 'משתמשים פעילים (${CommonConsts.daysForActiveUsers} ימים)', value: stats.activeUsers.toString(), color: Colors.orange),
        StatCard(title: 'משתמשים חדשים (${CommonConsts.daysForNewUsers} ימים אחרונים)', value: stats.newUsersNDays.toString(), color: Colors.purple),
        StatCard(title: 'סך השאלונים שהוגשו על ידי אורחים', value: stats.totalGuestQuizzes.toString(), color: Colors.deepPurple),
        StatCard(title: 'סך כניסות כאורח', value: stats.totalGuestLogins.toString(), color: Colors.deepPurple),
      ],
    );
  }
}
