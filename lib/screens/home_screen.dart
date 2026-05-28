import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'embarque_screen.dart';
import 'cadastro_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _telaAtualIndex = 0;

  final List<Widget> _telas = [
    const DashboardScreen(),
    const EmbarqueScreen(),
    const CadastroScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _telas[_telaAtualIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _telaAtualIndex,
        onTap: (index) {
          setState(() {
            _telaAtualIndex = index;
          });
        },
        selectedItemColor: Colors.blue.shade800,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_bus),
            label: 'Embarque',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_add),
            label: 'Cadastros',
          ),
        ],
      ),
    );
  }
}