import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../core/storage/prefs_store.dart';
import '../data/group.dart';

class GroupsController extends ChangeNotifier {
  static const _prefsKeyGroups = 'groups_v1';

  final PrefsStore _prefs;

  GroupsController(this._prefs);

  List<Group> _groups = const [];
  List<Group> get groups => _groups;

  void bootstrap() {
    final gStr = _prefs.getString(_prefsKeyGroups);
    if (gStr != null) {
      try {
        final arr = (jsonDecode(gStr) as List).cast<Map<String, dynamic>>();
        _groups = arr.map(Group.fromJson).toList();
      } catch (_) {
        _groups = const [];
      }
    }
  }

  Future<void> _save() async {
    await _prefs.setString(
      _prefsKeyGroups,
      jsonEncode(_groups.map((g) => g.toJson()).toList()),
    );
  }

  Future<Group> createGroup({
    required String name,
    required List<String> memberJids,
  }) async {
    final g = Group.create(name: name, memberJids: memberJids);
    _groups = [g, ..._groups];
    await _save();
    notifyListeners();
    return g;
  }

  Future<void> deleteGroup(String groupId) async {
    _groups = _groups.where((g) => g.id != groupId).toList();
    await _save();
    notifyListeners();
  }

  Group? findGroup(String groupId) {
    try {
      return _groups.firstWhere((g) => g.id == groupId);
    } catch (_) {
      return null;
    }
  }
}
