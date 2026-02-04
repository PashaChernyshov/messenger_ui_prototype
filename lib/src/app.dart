import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/di/scope.dart';
import 'core/theme/app_theme.dart';
import 'features/home/presentation/home_page.dart';
import 'features/settings/controller/ui_settings_controller.dart';

class MessengerApp extends StatelessWidget {
  const MessengerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = context.read<Scope>();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<UiSettingsController>.value(
          value: scope.uiSettings,
        ),
        ChangeNotifierProvider.value(value: scope.profile),
        ChangeNotifierProvider.value(value: scope.xmpp),
        ChangeNotifierProvider.value(value: scope.contacts),
        ChangeNotifierProvider.value(value: scope.chats),
        ChangeNotifierProvider.value(value: scope.groups),
        ChangeNotifierProvider.value(value: scope.calls),
      ],
      child: Builder(
        builder: (context) {
          final ui = context.watch<UiSettingsController>();

          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Мессенджер',
            themeMode: ThemeMode.dark,
            darkTheme: AppTheme.build(fontSize: ui.fontSize),
            locale: const Locale('ru', 'RU'),
            supportedLocales: const [
              Locale('ru', 'RU'),
              Locale('en', 'US'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const HomePage(),
          );
        },
      ),
    );
  }
}
