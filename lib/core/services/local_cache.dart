import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Tiny JSON cache backed by SharedPreferences, used for offline-first reads.
///
/// Repositories write the last successful response here and fall back to it
/// when the network is unavailable, so core screens (dashboard, groups) still
/// render the last-known state offline.
class LocalCache {
  static const _prefix = 'cache:';

  Future<void> writeJson(String key, Object value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prefix$key', jsonEncode(value));
  }

  Future<dynamic> readJson(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefix$key');
    if (raw == null) return null;
    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }

  /// Drop all cached entries (e.g. on logout, so one account never serves
  /// another's stale data offline).
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefix)).toList();
    for (final k in keys) {
      await prefs.remove(k);
    }
  }
}
