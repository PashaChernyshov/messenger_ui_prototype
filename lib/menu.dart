import 'package:app_design/menu_widget.dart';
import 'package:flutter/material.dart';
import 'contact_list_screen.dart';
import 'contact.dart';
import 'profile_settings_screen.dart';
import 'settings_screen.dart';
import 'group_list_screen.dart';

class Menu extends StatefulWidget {
  final List<Contact> contacts;
  final String userName;
  final String phoneNumber;
  final String status;
  final Function(double, String) onSaveSettings;

  const Menu({
    required this.contacts,
    required this.userName,
    required this.phoneNumber,
    required this.status,
    required this.onSaveSettings,
    super.key,
    required void Function(Map<String, String> newProfile) onUpdateProfile,
    required double fontSize,
  });

  @override
  _MenuState createState() => _MenuState();
}

class _MenuState extends State<Menu> {
  late String userName;
  late String phoneNumber;
  late String status;
  String avatarUrl = '';

  @override
  void initState() {
    super.initState();
    userName = widget.userName;
    phoneNumber = widget.phoneNumber;
    status = widget.status;
  }

  void updateProfile(Map<String, String> newProfile) {
    setState(() {
      userName = newProfile['newName'] ?? userName;
      phoneNumber = newProfile['newPhoneNumber'] ?? phoneNumber;
      status = newProfile['newStatus'] ?? status;
      avatarUrl = newProfile['avatarUrl'] ?? avatarUrl;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Stack(
            alignment: Alignment.topRight,
            children: [
              Column(
                children: [
                  CircleAvatar(
                    radius: 42,
                    backgroundImage: avatarUrl.isNotEmpty
                        ? NetworkImage(avatarUrl)
                        : const AssetImage('assets/default_avatar.png')
                            as ImageProvider,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    phoneNumber,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    status,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.grey),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileSettingsScreen(
                        userName: userName,
                        phoneNumber: phoneNumber,
                        status: status,
                        onUpdateProfile: updateProfile,
                        avatarUrl: avatarUrl,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          MenuItem(
            title: 'Контакты',
            icon: Icons.contacts_rounded,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ContactListScreen(contacts: widget.contacts),
                ),
              );
            },
          ),
          MenuItem(
            title: 'Группы',
            icon: Icons.group_rounded,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      GroupListScreen(allContacts: widget.contacts),
                ),
              );
            },
          ),
          MenuItem(
            title: 'Избранное',
            icon: Icons.favorite_rounded,
            onTap: () {},
          ),
          MenuItem(
            title: 'Настройки',
            icon: Icons.settings_rounded,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      SettingsScreen(onSaveSettings: widget.onSaveSettings),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
