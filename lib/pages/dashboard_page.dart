import 'package:flutter/material.dart';
import 'package:shemesh_admin/config/common_consts.dart';
import 'package:shemesh_admin/config/dashboard_labels.dart';
import 'package:shemesh_admin/services/dashboard_stats.dart';
import 'package:shemesh_admin/widgets/quiz_total_bar_chart.dart';
import 'package:shemesh_admin/widgets/stat_card.dart';
import 'package:shemesh_admin/widgets/user_growth_chart.dart';
import 'package:shemesh_admin/utilities/debug_log.dart';

const double _maxCardWidth = 240;   // hard cap on each card's width
const double _maxGridWidth = 1500;  // group stays centered beyond this

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  static String tag = 'DashboardPage';
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
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FutureBuilder<DashboardStats>(
                future: _futureStats,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }
                  if (!snapshot.hasData) {
                    debugLog('LoadStats: waiting for data...');
                    return const Center(child: CircularProgressIndicator());
                  }
                  return _buildStatsSection(snapshot.data!);
                },
              ),
              const SizedBox(height: 24),
              const QuizTotalBarChart(),
              const SizedBox(height: 30),
              const UserGrowthChart(),
              const SizedBox(height: 30),
            ],
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
    return Align(
      alignment: Alignment.center,
      child: ElevatedButton(
        onPressed: _refreshStats,
        style: ElevatedButton.styleFrom(
          backgroundColor: CommonConsts.actionButtonColor,
          foregroundColor: CommonConsts.primaryTextColor,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      ),
    );
  }

  Widget _buildStatCards(DashboardStats stats) {
    final cards = [
      StatCard(
          title: DashboardLabels.totalUsers,
          value: stats.totalUsers.toString(),
          color: Colors.blue),
      StatCard(
          title: DashboardLabels.quizzesToday,
          value: stats.quizzesToday.toString(),
          color: Colors.brown),
      StatCard(
          title: DashboardLabels.quizzesThisMonth,
          value: stats.quizzesSubmittedRecently.toString(),
          color: Colors.green),
      StatCard(
          title: DashboardLabels.activeUsers,
          value: stats.activeUsers.toString(),
          color: Colors.orange),
      StatCard(
          title: DashboardLabels.newUsers,
          value: stats.newUsersNDays.toString(),
          color: Colors.purple),
      StatCard(
          title: DashboardLabels.totalGuestQuizzes,
          value: stats.totalGuestQuizzes.toString(),
          color: Colors.deepPurple),
      StatCard(
          title: DashboardLabels.totalGuestLogins,
          value: stats.totalGuestLogins.toString(),
          color: Colors.deepPurple),
    ];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxGridWidth),
        child: GridView.extent(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          maxCrossAxisExtent: _maxCardWidth,
          childAspectRatio: 1.5,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: cards,
        ),
      ),
    );
  }
}
