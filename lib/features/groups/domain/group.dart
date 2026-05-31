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

  static Group create(
      {required String name, required List<String> memberJids}) {
    final rnd = Random();
    final id =
        '${DateTime.now().millisecondsSinceEpoch}-${rnd.nextInt(999999)}';
    return Group(
      id: id,
      name: name.trim(),
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

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      memberJids: (json['memberJids'] as List? ?? const [])
          .map((e) => e.toString())
          .toList(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now(),
    );
  }

  Group copyWith({
    String? id,
    String? name,
    List<String>? memberJids,
    DateTime? createdAt,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      memberJids: memberJids ?? this.memberJids,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
