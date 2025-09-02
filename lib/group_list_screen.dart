// group_list_screen.dart
import 'package:flutter/material.dart';
import 'package:characters/characters.dart';
import 'contact.dart';
import 'group_creation_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class Group {
  final String name;
  final String lastMessage;
  final String time;
  final List<Contact> members;

  Group({
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.members,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'lastMessage': lastMessage,
        'time': time,
        'members': members
            .map((e) => {
                  'name': e.name,
                  'lastMessage': e.lastMessage,
                  'time': e.time,
                  'avatarUrl': e.avatarUrl,
                })
            .toList(),
      };

  static Group fromJson(Map<String, dynamic> json) {
    final membersJson = (json['members'] as List?) ?? [];
    final members = membersJson
        .map((i) => Contact(
              name: i['name'] ?? '',
              lastMessage: i['lastMessage'] ?? '',
              time: i['time'] ?? '',
              avatarUrl: i['avatarUrl'] ?? '',
            ))
        .toList();
    return Group(
      name: json['name'] ?? '',
      lastMessage: json['lastMessage'] ?? '',
      time: json['time'] ?? '',
      members: members,
    );
  }
}

class GroupListScreen extends StatefulWidget {
  final List<Contact> allContacts;

  const GroupListScreen({super.key, required this.allContacts});

  @override
  State<GroupListScreen> createState() => _GroupListScreenState();
}

class _GroupListScreenState extends State<GroupListScreen> {
  List<Group> groups = [];

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('groups') ?? '[]';
    final decoded = json.decode(raw) as List;
    setState(() {
      groups = decoded
          .map((e) => Group.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  Future<void> _saveGroups() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(groups.map((e) => e.toJson()).toList());
    await prefs.setString('groups', encoded);
  }

  Future<void> _createGroup() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GroupCreationScreen(
          contacts: widget.allContacts,
          onGroupCreated: (name, selected) async {
            final now = TimeOfDay.now();
            final group = Group(
              name: name,
              lastMessage: 'Группа создана',
              time:
                  '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
              members: selected,
            );
            setState(() {
              groups.add(group);
            });
            await _saveGroups();
            if (mounted) Navigator.pop(context);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Группы'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createGroup,
          ),
        ],
      ),
      body: groups.isEmpty
          ? const Center(
              child: Text('Групп пока нет',
                  style: TextStyle(color: Colors.white70)),
            )
          : ListView.builder(
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final group = groups[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF3A3A3C),
                    child: Text(
                      (group.name.characters.isEmpty
                              ? '#'
                              : group.name.characters.first)
                          .toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(group.name,
                      style: const TextStyle(color: Colors.white)),
                  subtitle: Text('${group.lastMessage} • ${group.time}',
                      style: const TextStyle(color: Colors.grey)),
                  onTap: () {
                    // Здесь может быть переход в экран группы
                  },
                );
              },
            ),
    );
  }
}
