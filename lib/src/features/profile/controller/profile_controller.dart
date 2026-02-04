import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../../../core/storage/prefs_store.dart';
import '../data/profile_data.dart';

class ProfileController extends ChangeNotifier {
  static const _prefsKeyProfile = 'profile_data_v1';

  final PrefsStore _prefs;

  ProfileController(this._prefs);

  ProfileData _profile = const ProfileData(
    name: 'User',
    phone: '',
    status: 'Available',
    avatarBytes: null,
  );

  ProfileData get profile => _profile;

  void bootstrap() {
    final profileStr = _prefs.getString(_prefsKeyProfile);
    if (profileStr != null) {
      try {
        _profile = ProfileData.fromJson(
          jsonDecode(profileStr) as Map<String, dynamic>,
        );
      } catch (_) {}
    }
  }

  Future<void> update(ProfileData next) async {
    _profile = next;
    await _prefs.setString(_prefsKeyProfile, jsonEncode(_profile.toJson()));
    notifyListeners();
  }

  /// Совместимость с UI: ProfileSettingsScreen вызывает profile.save(...)
  Future<void> save({
    required String name,
    required String phone,
    Uint8List? avatarBytes,
  }) async {
    final next = ProfileData(
      name: name.trim().isEmpty ? 'User' : name.trim(),
      phone: phone,
      status: _profile.status,
      avatarBytes: avatarBytes,
    );
    await update(next);
  }
}
