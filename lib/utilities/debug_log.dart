// lib/utils/debug_log.dart
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

//  Cross-platform debug log function
void debugLog(String message,
    {String name = 'DebugLog',
    bool includeTimestamp = true}) {
  if (kIsWeb) {
    // On web, print() writes to the browser console
    if (includeTimestamp) {
      _printWebWithTimestamp(message, name);
    } else {
      print('$name: $message');
    }
  } else {
    // mobile/desktop
    if (includeTimestamp) {
      _printMobileWithTimestamp(message, name);
    } else {
      developer.log(message, name: name);
    }
  }
}

void _printWebWithTimestamp(String message, String name) {
  final timestamp = DateTime.now().toIso8601String(); // ISO timestamp
  print('$timestamp | $name: $message');
}

void _printMobileWithTimestamp(String message, String name) {
  developer.log(message, name: name, time: DateTime.now());
}
