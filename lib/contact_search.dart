// contact_search.dart
import 'package:flutter/material.dart';
import 'package:characters/characters.dart';
import 'contact.dart';
import 'contact_tile.dart';

class ContactSearch extends SearchDelegate<Contact?> {
  final List<Contact> contacts;

  ContactSearch(this.contacts);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final q = query.characters.toString().toLowerCase();
    final results =
        contacts.where((c) => c.name.toLowerCase().contains(q)).toList();
    return ListView(
      children: results.map((c) => ContactTile(contact: c)).toList(),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final q = query.characters.toString().toLowerCase();
    final suggestions =
        contacts.where((c) => c.name.toLowerCase().contains(q)).toList();
    return ListView(
      children: suggestions.map((c) => ContactTile(contact: c)).toList(),
    );
  }
}
