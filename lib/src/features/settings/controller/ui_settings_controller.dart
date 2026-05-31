import 'package:flutter/foundation.dart';

import '../../../core/storage/prefs_store.dart';

class UiSettingsController extends ChangeNotifier {
  static const _prefsKeyFontSize = 'ui_font_size_v1';

  final PrefsStore _prefs;

  UiSettingsController(this._prefs);

  double _fontSize = 14;
  double get fontSize => _fontSize;

  void bootstrap() {
    _fontSize = _prefs.getDouble(_prefsKeyFontSize) ?? 14;
  }

  Future<void> setFontSize(double v) async {
    _fontSize = v;
    await _prefs.setDouble(_prefsKeyFontSize, v);
    notifyListeners();
  }
}
