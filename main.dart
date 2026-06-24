import 'package:flutter/material.dart';
import 'package:front_end/features/shell/screens/app_shell.dart';

void main() {
  // Garante que os bindings do Flutter foram inicializados antes de rodar o app.
  // É útil se você precisar executar código assíncrono antes de runApp().
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AppBus());
}

class AppBus extends StatelessWidget {
  const AppBus({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App-Bus',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const AppShell(),
    );
  }
}
