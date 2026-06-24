import 'package:flutter/material.dart';
import 'package:front_end/features/home/screens/home_screen.dart';
import 'package:front_end/features/map/screens/map_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  // Lista das telas que serão navegáveis
  static const List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    MapScreen(),
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
      appBar: AppBar(title: Text(_appBarTitles[_selectedIndex])),
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
}
