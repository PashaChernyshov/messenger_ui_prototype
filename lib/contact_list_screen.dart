// contact_list_screen.dart
import 'package:flutter/material.dart';
import 'package:characters/characters.dart';
import 'contact.dart';
import 'contact_tile.dart';

class ContactListScreen extends StatelessWidget {
  final List<Contact> contacts;

  const ContactListScreen({super.key, required this.contacts});

  @override
  Widget build(BuildContext context) {
// Группируем контакты по первой видимой букве (учитывая эмодзи/диакритику)
    final Map<String, List<Contact>> grouped = {};
    for (final c in contacts) {
      final name = c.name.trim();
      final graphemes = name.isNotEmpty ? name.characters : '#'.characters;
      final String first =
          graphemes.isEmpty ? '#' : graphemes.first.toUpperCase();
      grouped.putIfAbsent(first, () => []).add(c);
    }

// Сортируем группы и элементы внутри группы (без изменения стиля)
    final keys = grouped.keys.toList()..sort((a, b) => a.compareTo(b));
    for (final k in keys) {
      grouped[k]!
          .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Контакты'),
      ),
      body: ListView.builder(
        itemCount: keys.length,
        itemBuilder: (context, index) {
          final letter = keys[index];
          final list = grouped[letter]!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок секции (буква/символ)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  letter,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              // Элементы группы
              ...list.map((c) => ContactTile(contact: c)),
            ],
          );
        },
      ),
    );
  }
}
