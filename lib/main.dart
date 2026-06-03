import 'package:flutter/material.dart';
import 'package:shemesh_admin/pages/admin_login_page.dart';
import 'package:shemesh_admin/services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final firebaseService = FirebaseService();
  await firebaseService.init(); // or omit for default

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shemesh Begivon Dashboard',
      debugShowCheckedModeBanner: false,
      home: AdminLoginPage(),
      //home: DashboardPage(),
    );
  }
}
