import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/rota_provider.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(
    // Injetando o Provider no topo da árvore de Widgets do App
    ChangeNotifierProvider(
      create: (context) => RotaProvider(),
      child: const MeuAppBus(),
    ),
  );
}

class MeuAppBus extends StatelessWidget {
  const MeuAppBus({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Bus Desktop',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // CORRIGIDO: Removido o 'const' daqui para aceitar os Providers dinâmicos
      home: const HomeScreen(), 
    );
  }
}