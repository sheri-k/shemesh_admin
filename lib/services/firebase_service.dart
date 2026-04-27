import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shemesh_admin/firebase_options.dart';

class FirebaseService {
  static const String tag = "FirebaseService";
  // Private constructor for singleton
  FirebaseService._internal();

  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;

  late final FirebaseApp app;
  late final FirebaseFirestore _firestore;

  Future<void>? _initFuture;

  /// Public access to Firestore
  FirebaseFirestore get firestore => _firestore;

  Future<void> init() {
    _initFuture ??= _init();
    return _initFuture!;
  }

  Future<bool> _isAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    final token = await user!.getIdTokenResult(true);
    return token.claims?['admin'] == true;
  }

  /// Initialize Firebase once
  Future<void> _init() async {
    // Declare 'app' locally so it is accessible in the scope of this method
    late final FirebaseApp app;

    app = await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // TEMPORARY: Fix this!!!!
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: "admin@shemeshbegivon.com",
      password: "0addHWY!",
    );

    //const databaseId = 'production';
    const databaseId = '(default)';
    _firestore = FirebaseFirestore.instanceFor(
      app: app,
      databaseId: databaseId,
    );

    print('Current user: ${FirebaseAuth.instance.currentUser}');

    if (!await _isAdmin()) {
      print("Firestore Access denied");
    } else {
      print("Firestore Access granted");
    }

    // Apply settings to the specific instance
    // This is a workaround for a problem encountered when running web app from iphone with ios version 26.4.1
    // Sometimes the connection hangs on getting data from firestore, causing it to take very long
    // (over 30 seconds) and this setting seems to fix it ( at least usually).  I didn't differentiate here between
    // android and ios because I didn't have the chance to test it on android, but it seems to be a web issue and not platform specific, so I apply it for all web platforms
    // _firestore.settings = const Settings(
    //   webExperimentalForceLongPolling: true,
    //   persistenceEnabled: false,
    // );
  }
}
