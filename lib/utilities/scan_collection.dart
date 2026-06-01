import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer';

import 'package:shemesh_admin/services/firebase_service.dart';
import 'package:shemesh_admin/utilities/debug_log.dart';

class ScanCollection {
  static const String tag = 'ScanCollection';

  final FirebaseFirestore firestore;

  ScanCollection({FirebaseFirestore? firestoreInstance})
      : firestore = firestoreInstance ?? FirebaseService().firestore;


Future<void> scan() async {
    try {
      // Gets ALL documents from ALL collections named 'questions'
      final snapshot =
          await firestore.collectionGroup('questions').get();

      // Group by parent collection path
      final Map<String, int> counts = {};

      for (final doc in snapshot.docs) {
        final parentPath = doc.reference.parent.path;

        counts[parentPath] = (counts[parentPath] ?? 0) + 1;
      }

      for (final entry in counts.entries) {
        if (entry.value > 10) {
          debugLog(name: tag,
            'Questions collection "${entry.key}" '
            'contains ${entry.value} documents.',
          );
        }
      }

      log('Finished scanning questions collections.', name: tag);
    } catch (e, st) {
      log(
        'Error scanning Firestore: $e',
        name: tag,
        stackTrace: st,
      );
    }
  }
}


/*
  /// Starts recursive scan from root collections
  Future<void> scan() async {
    final rootCollections = await firestore.listCollections();

    for (final collection in rootCollections) {
      await _scanCollection(collection);
    }

    log('Finished scanning Firestore.', name: tag);
  }

  Future<void> _scanCollection(CollectionReference collection) async {
    try {
      // ----------------------------------------------------------
      // If this collection is named 'questions', count documents
      // ----------------------------------------------------------
      if (collection.id == 'questions') {
        final snapshot = await collection.get();
        final count = snapshot.docs.length;

        if (count > 10) {
          log(
            '⚠️ Collection path "${collection.path}" '
            'contains $count documents.',
            name: tag,
          );
        }
      }

      // ----------------------------------------------------------
      // Recurse into subcollections of every document
      // ----------------------------------------------------------
      final docs = await collection.get();

      for (final doc in docs.docs) {
        final subcollections = await doc.reference.listCollections();

        for (final subcollection in subcollections) {
          await _scanCollection(subcollection);
        }
      }
    } catch (e, st) {
      log(
        'Error scanning collection "${collection.path}": $e',
        name: tag,
        stackTrace: st,
      );
    }
  }
} */
