/// ## Arquiteto de Solução e Desenvolvedor Líder
///
/// **Márcio Rodrigues de Oliveira**
///
/// * Desenvolvedor Full Stack
/// * cda.marcio@gmail.com

import 'package:flutter/material.dart';
import 'package:front_end/features/auth/controllers/auth_controller.dart';
import 'package:front_end/features/auth/screens/login_screen.dart';
import 'package:front_end/features/home/screens/home_screen.dart';
import 'package:front_end/features/map/screens/map_screen.dart';
import 'package:front_end/locator.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  // Obtém a instância singleton do AuthController.
  late final AuthController _authController;

  @override
  void initState() {
    super.initState();
    _authController = locator<AuthController>();
    _authController.addListener(_onAuthChange);
  }

  void _onAuthChange() {
    // Se, por algum motivo, o estado de autenticação mudar para falso
    // (ex: logout), navega de volta para a tela de login.
    if (!_authController.isAuthenticated && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false, // Remove todas as rotas anteriores.
      );
    }
  }

  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    const HomeScreen(),
    MapScreen(), // MapScreen não é mais const
  ];

  // Lista dos títulos para o AppBar, correspondendo à ordem das telas
  static const List<String> _appBarTitles = <String>[
    'Bem-vindo',
    'Mapa de Ônibus',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // O Scaffold agora é envolvido por um AnimatedBuilder para reagir ao isLoading.
      appBar: AppBar(
        title: Text(_appBarTitles[_selectedIndex]),
        actions: [
          // Adiciona um botão de logout na AppBar.
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            // Agora chama o diálogo de confirmação.
            onPressed: () {
              // Chama o método de logout do controller.
              _authController.logout();
            },
          ),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: _widgetOptions),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            label: 'Mapa',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // Garante boa visibilidade
      ),
    );
  }

  @override
  void dispose() {
    _authController.removeListener(_onAuthChange);
    // Não chamamos o dispose do controller aqui, pois ele é um singleton.
    super.dispose();
  }
}
