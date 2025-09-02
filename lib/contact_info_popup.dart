import 'dart:ui';
import 'package:flutter/material.dart';
import 'contact.dart';

class ContactInfoPopup extends StatelessWidget {
  final Contact contact;

  const ContactInfoPopup({super.key, required this.contact});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Задний блюр
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(color: Colors.black.withOpacity(0.6)),
        ),
        // Основное окно
        Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: contact.avatarUrl.isNotEmpty
                      ? NetworkImage(contact.avatarUrl)
                      : null,
                  backgroundColor: const Color(0xFF3A3A3C),
                  child: contact.avatarUrl.isEmpty
                      ? const Icon(Icons.person, color: Colors.white, size: 40)
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  contact.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '+7 000 000-00-00', // Заглушка телефона
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Закрыть'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Функция-обёртка для вызова
void showContactInfoPopup(BuildContext context, Contact contact) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) => ContactInfoPopup(contact: contact),
  );
}
