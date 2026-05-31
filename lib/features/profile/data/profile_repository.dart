import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_design/features/profile/domain/profile_data.dart';

abstract interface class ProfileRepository {
  Future<ProfileData> load();
  Future<void> save(ProfileData profile);
}

class SharedPrefsProfileRepository implements ProfileRepository {
  static const _profileKey = 'profile_data_v1';

  @override
  Future<ProfileData> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profileKey);
    if (raw == null) return _defaultProfile;

    try {
      return ProfileData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return _defaultProfile;
    }
  }

  @override
  Future<void> save(ProfileData profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey, jsonEncode(profile.toJson()));
  }

  static const _defaultProfile = ProfileData(
    name: 'User',
    phone: '',
    status: 'Available',
    avatarBytes: null,
  );
}
