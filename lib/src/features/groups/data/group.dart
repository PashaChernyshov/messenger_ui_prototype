import 'dart:math';

class Group {
  final String id;
  final String name;
  final List<String> memberJids;
  final DateTime createdAt;

  const Group({
    required this.id,
    required this.name,
    required this.memberJids,
    required this.createdAt,
  });

  factory Group.create({
    required String name,
    required List<String> memberJids,
  }) {
    final r = Random().nextInt(999999);
    return Group(
      id: 'g$r',
      name: name,
      memberJids: memberJids,
      createdAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'memberJids': memberJids,
        'createdAt': createdAt.toIso8601String(),
      };

  static Group fromJson(Map<String, dynamic> json) {
    return Group(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      memberJids: (json['memberJids'] is List)
          ? (json['memberJids'] as List).map((e) => e.toString()).toList()
          : const [],
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}
