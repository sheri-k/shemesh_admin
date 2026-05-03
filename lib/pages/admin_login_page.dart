import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shemesh_admin/config/common_consts.dart';
import 'package:shemesh_admin/pages/daf_voice_page.dart';
import 'package:shemesh_admin/pages/dashboard_page.dart';
import 'package:shemesh_admin/pages/voice_input_page.dart';
import 'package:shemesh_admin/pages/voice_question_page.dart';
import 'package:shemesh_admin/utilities/debug_log.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  static String tag = 'AdminLoginPage';
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  bool _loading = false;
  String _error = '';

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      // await FirebaseAuth.instance.signInWithEmailAndPassword(
      //   email: _emailController.text.trim(),
      //   password: _passwordController.text.trim(),
      // );

      // Temporary
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: 'admin@shemeshbegivon.com',
        password: 'totafjlhruakhoG7?',
      );

      // SUCCESS: go to dashboard
      Navigator.pushReplacement(
        context,
        //MaterialPageRoute(builder: (_) => DashboardPage()),
        MaterialPageRoute(builder: (_) => DafVoicePage()),
      );
    } on FirebaseAuthException catch (e) {
      debugLog(name: tag, 'FirebaseAuthException: ${e.code} - ${e.message}');
      setState(() {
        _error = e.message ?? 'Login failed';
      });
    } catch (e) {
      debugLog(e.toString());
      setState(() {
        _error = 'Unexpected error';
      });
    }

    setState(() {
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: CommonConsts.secondaryScaffoldBckgrndColor,
        body: Center(
          child: Container(
            width: 380,
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 6,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'כניסת מנהל',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'אימייל',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'סיסמה',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_error.isNotEmpty)
                      Text(
                        _error,
                        style: const TextStyle(color: Colors.red),
                      ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _login,
                        style: ButtonStyle(
                          backgroundColor: WidgetStatePropertyAll(
                              CommonConsts.actionButtonColor),
                          // overlayColor:
                          //     WidgetStatePropertyAll(CommonConsts.appBarColor),
                        ),
                        child: _loading
                            ? const CircularProgressIndicator(
                                color: CommonConsts.progressIndicatorColor,
                              )
                            : const Text('התחבר',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: CommonConsts.primaryTextColor)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
