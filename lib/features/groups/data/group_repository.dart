import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_design/features/groups/domain/group.dart';

abstract interface class GroupRepository {
  Future<List<Group>> load();
  Future<void> save(List<Group> groups);
  Future<List<Group>> create({
    required List<Group> current,
    required String name,
    required List<String> memberJids,
  });
  Future<List<Group>> delete({
    required List<Group> current,
    required String groupId,
  });
}

class SharedPrefsGroupRepository implements GroupRepository {
  static const _groupsKey = 'groups_v1';

  @override
  Future<List<Group>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_groupsKey);
    if (raw == null) return const [];

    try {
      final arr = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      return arr.map(Group.fromJson).toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<void> save(List<Group> groups) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _groupsKey,
      jsonEncode(groups.map((group) => group.toJson()).toList()),
    );
  }

  @override
  Future<List<Group>> create({
    required List<Group> current,
    required String name,
    required List<String> memberJids,
  }) async {
    final next = [Group.create(name: name, memberJids: memberJids), ...current];
    await save(next);
    return next;
  }

  @override
  Future<List<Group>> delete({
    required List<Group> current,
    required String groupId,
  }) async {
    final next = current.where((group) => group.id != groupId).toList();
    await save(next);
    return next;
  }
}
