// menu_widget.dart
import 'package:flutter/material.dart';
import 'dart:ui';

class MenuWidget extends StatelessWidget {
  final VoidCallback onClose;
  final VoidCallback onOpenSettings; // Добавлено для открытия настроек

  const MenuWidget(
      {super.key,
      required this.onClose,
      required this.onOpenSettings}); // Обновлено

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.grey[850]?.withOpacity(0.8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: onOpenSettings, // Обновлено для открытия настроек
            ),
            const CircleAvatar(
              radius: 40,
              backgroundImage: NetworkImage(
                  'https://via.placeholder.com/150'), // Ваша аватарка
            ),
            const SizedBox(height: 10),
            const Text('Ваше имя',
                style: TextStyle(color: Colors.white, fontSize: 20)),
            const Text('+7 921 873-43-77',
                style: TextStyle(color: Colors.grey)),
            const Divider(color: Colors.grey),
            MenuItem(
              title: 'Контакты',
              icon: Icons.contacts,
              onTap: () {},
            ),
            MenuItem(
              title: 'Группы',
              icon: Icons.group,
              onTap: () {},
            ),
            MenuItem(
              title: 'Избранное',
              icon: Icons.favorite,
              onTap: () {},
            ),
            MenuItem(
              title: 'Настройки',
              icon: Icons.settings,
              onTap: () {
                onOpenSettings(); // Передаем действие для открытия настроек
              },
            ),
          ],
        ),
      ),
    );
  }
}

class MenuItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const MenuItem({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: onTap,
    );
  }
}
