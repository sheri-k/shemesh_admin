import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shemesh_admin/firebase_options.dart';
import 'package:shemesh_admin/utilities/debug_log.dart';

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

    const databaseId = 'production';
    //const databaseId = '(default)';
    _firestore = FirebaseFirestore.instanceFor(
      app: app,
      databaseId: databaseId,
    );
  }
}
