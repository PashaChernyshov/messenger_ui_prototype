import 'package:shared_preferences/shared_preferences.dart';

class PrefsStore {
  final SharedPreferences _prefs;

  PrefsStore._(this._prefs);

  static Future<PrefsStore> create() async {
    final p = await SharedPreferences.getInstance();
    return PrefsStore._(p);
  }

  double? getDouble(String key) => _prefs.getDouble(key);
  Future<void> setDouble(String key, double v) async =>
      _prefs.setDouble(key, v);

  String? getString(String key) => _prefs.getString(key);
  Future<void> setString(String key, String v) async =>
      _prefs.setString(key, v);

  bool? getBool(String key) => _prefs.getBool(key);
  Future<void> setBool(String key, bool v) async => _prefs.setBool(key, v);

  Future<void> remove(String key) async => _prefs.remove(key);
}
