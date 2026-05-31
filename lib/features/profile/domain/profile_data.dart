import 'dart:convert';
import 'dart:typed_data';

class ProfileData {
  final String name;
  final String phone;
  final String status;
  final Uint8List? avatarBytes;

  const ProfileData({
    required this.name,
    required this.phone,
    required this.status,
    required this.avatarBytes,
  });

  ProfileData copyWith({
    String? name,
    String? phone,
    String? status,
    Uint8List? avatarBytes,
    bool clearAvatar = false,
  }) {
    return ProfileData(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      status: status ?? this.status,
      avatarBytes: clearAvatar ? null : (avatarBytes ?? this.avatarBytes),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'phone': phone,
        'status': status,
        'avatarBase64': avatarBytes == null ? null : base64Encode(avatarBytes!),
      };

  static ProfileData fromJson(Map<String, dynamic> json) {
    final b64 = json['avatarBase64'];
    return ProfileData(
      name: (json['name'] ?? 'User').toString(),
      phone: (json['phone'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      avatarBytes: (b64 is String && b64.isNotEmpty) ? base64Decode(b64) : null,
    );
  }
}
