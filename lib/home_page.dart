import 'package:flutter/material.dart';
import 'contact_tile.dart';
import 'contact.dart';
import 'menu.dart';
import 'contact_search.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Contact> contacts = [
    Contact(
        name: 'Иван Иванов',
        lastMessage: 'Привет! Как дела?',
        time: '16:20',
        avatarUrl: 'https://via.placeholder.com/150'),
    Contact(
        name: 'Петр Петров',
        lastMessage: 'Не забудь про встречу.',
        time: '15:45',
        avatarUrl: 'https://via.placeholder.com/150'),
    Contact(
        name: 'Анна Смирнова',
        lastMessage: 'Когда будем встречаться?',
        time: '14:30',
        avatarUrl: 'https://via.placeholder.com/150'),
    Contact(
        name: 'Сергей Сергеев',
        lastMessage: 'Все в порядке.',
        time: '13:15',
        avatarUrl: 'https://via.placeholder.com/150'),
    Contact(
        name: 'Мария Кузнецова',
        lastMessage: 'Готова к участию?',
        time: '12:50',
        avatarUrl: 'https://via.placeholder.com/150'),
  ];

  String userName = 'Ваше имя';
  String phoneNumber = '+7 921 873-43-77';
  String status = 'Ваш статус';
  double fontSize = 16.0;

  void _updateProfile(Map<String, String> newProfile) {
    setState(() {
      userName = newProfile['newName'] ?? userName;
      phoneNumber = newProfile['newPhoneNumber'] ?? phoneNumber;
      status = newProfile['newStatus'] ?? status;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      fontSize = prefs.getDouble('fontSize') ?? 16.0;
    });
  }

  void _saveSettings(double size, String language) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setDouble('fontSize', size);
    setState(() {
      fontSize = size;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'AppDesign',
          style: TextStyle(color: Colors.white, fontSize: fontSize),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              showSearch(context: context, delegate: ContactSearch(contacts));
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: contacts.length,
        itemBuilder: (context, index) {
          return ContactTile(
            contact: contacts[index],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (context) => Menu(
              contacts: contacts,
              userName: userName,
              phoneNumber: phoneNumber,
              status: status,
              onUpdateProfile: _updateProfile,
              fontSize: fontSize,
              onSaveSettings: _saveSettings,
            ),
          );
        },
        child: const Icon(Icons.menu),
      ),
    );
  }
}
