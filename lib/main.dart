import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'src/app.dart';
import 'src/core/di/scope.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final scope = Scope();
  await scope.bootstrap();

  runApp(
    Provider<Scope>.value(
      value: scope,
      child: const MessengerApp(),
    ),
  );
}
