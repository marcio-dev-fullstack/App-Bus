import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // O AppBar agora é gerenciado por cada tela individualmente
    return const Center(
      child: Text('Bem-vindo ao App-Bus!', style: TextStyle(fontSize: 24)),
    );
  }
}
