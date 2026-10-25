import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shemesh_admin/utilities/debug_log.dart';

/// Loads the list of user email addresses that should be excluded from
/// quiz counts.
///
/// The list is stored in Firestore at `analytics/excluded_users` in an
/// array field named `emails`, e.g.:
///
///     analytics/excluded_users = { "emails": ["a@b.com", "c@d.com"] }
///
/// Edit that document in the Firebase console to add/remove users — no
/// rebuild or redeploy of the admin app is required.
class ExcludedUsers {
  static const String tag = 'ExcludedUsers';
  static const String collection = 'analytics';
  static const String docId = 'excluded_users';
  static const String field = 'emails';

  /// Returns the excluded email addresses (trimmed). Each address must match
  /// a user's `email_address` field in Firestore exactly. Returns an empty
  /// set if the document is missing or malformed.
  static Future<Set<String>> loadEmails(FirebaseFirestore db) async {
    try {
      final doc = await db.collection(collection).doc(docId).get();
      final raw = doc.data()?[field];
      if (raw is! List) return <String>{};
      return raw
          .whereType<String>()
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toSet();
    } catch (e) {
      debugLog(name: tag, 'Failed to load excluded users: $e');
      return <String>{};
    }
  }

  /// Resolves the configured excluded email addresses to the set of user ids
  /// (uids) whose data should be left out of stats and charts. Returns an
  /// empty set when nothing is configured.
  static Future<Set<String>> loadUids(FirebaseFirestore db) async {
    final emails = (await loadEmails(db)).toList();
    if (emails.isEmpty) {
      debugLog(name: tag, 'No users to be excluded');
      return <String>{};
    }

    final uids = <String>{};
    // whereIn accepts at most 30 values, so query the emails in chunks.
    for (var i = 0; i < emails.length; i += 30) {
      final chunk = emails.sublist(i, math.min(i + 30, emails.length));
      final snap = await db
          .collection('users')
          .where('email_address', whereIn: chunk)
          .get();
      for (final doc in snap.docs) {
        uids.add(doc.id);
        final email = doc.data()['email_address'] ?? doc.id;
        debugLog(name: tag, 'Excluding user "$email" (uid ${doc.id})');
      }
    }
    debugLog(
        name: tag,
        'Excluding ${uids.length} user(s) (${emails.length} email(s)) from stats and charts');
    return uids;
  }
}
