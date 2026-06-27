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
import 'package:front_end/features/sync/services/geofence_sync_trigger.dart';
import 'package:front_end/features/sync/services/connectivity_sync_trigger.dart';
import 'package:front_end/features/student/screens/student_registration_screen.dart';
import 'package:front_end/features/student/screens/student_list_screen.dart';
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
  // Instâncias dos nossos gatilhos de sincronização.
  late final ConnectivitySyncTrigger _connectivityTrigger;
  late final GeofenceSyncTrigger _geofenceTrigger;

  @override
  void initState() {
    super.initState();
    _authController = locator<AuthController>();
    // Inicia os monitoramentos de conectividade e geofence.
    _connectivityTrigger = ConnectivitySyncTrigger()..initialize();
    _geofenceTrigger = GeofenceSyncTrigger()..initialize();
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
      floatingActionButton: _selectedIndex == 0
          ? _buildHomeFABs(context)
          : null,
    );
  }

  /// Constrói os botões de ação flutuantes para a tela Home.
  Widget _buildHomeFABs(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FloatingActionButton.extended(
          heroTag: 'fab_register_student', // Tag única para o Hero
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const StudentRegistrationScreen(),
              ),
            );
          },
          icon: const Icon(Icons.person_add),
          label: const Text('Cadastrar'),
        ),
        const SizedBox(width: 16),
        FloatingActionButton.extended(
          heroTag: 'fab_list_students', // Tag única para o Hero
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const StudentListScreen()),
            );
          },
          icon: const Icon(Icons.people),
          label: const Text('Alunos'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _authController.removeListener(_onAuthChange);
    // Para os monitoramentos ao fazer logout para liberar recursos.
    _connectivityTrigger.dispose();
    _geofenceTrigger.dispose();
    // Não chamamos o dispose do controller aqui, pois ele é um singleton.
    super.dispose();
  }
}
