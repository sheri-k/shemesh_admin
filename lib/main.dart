import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shemesh_admin/pages/admin_login_page.dart';
import 'package:shemesh_admin/services/firebase_service.dart';
import 'pages/dashboard_page.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final firebaseService = FirebaseService();
  await firebaseService.init(); // or omit for default

  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );

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
