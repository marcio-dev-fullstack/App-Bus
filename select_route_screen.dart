/// ## Arquiteto de Solução e Desenvolvedor Líder
///
/// **Márcio Rodrigues de Oliveira**
///
/// * Desenvolvedor Full Stack
/// * cda.marcio@gmail.com

import 'package:flutter/material.dart';
import 'package:front_end/features/trip/screens/boarding_screen.dart';

// Modelo simples para representar uma rota. Em um app real, viria de um arquivo de modelo.
class _RouteInfo {
  final String id;
  final String name;
  final String description;

  const _RouteInfo({
    required this.id,
    required this.name,
    required this.description,
  });
}

class SelectRouteScreen extends StatelessWidget {
  const SelectRouteScreen({super.key});

  // Dados de exemplo. Em um app real, viriam do banco de dados local.
  final List<_RouteInfo> _availableRoutes = const [
    _RouteInfo(
      id: '1',
      name: 'Rota 01 - Centro',
      description: 'Passa pelo centro da cidade e bairros adjacentes.',
    ),
    _RouteInfo(
      id: '2',
      name: 'Rota 02 - Zona Rural Norte',
      description: 'Atende as comunidades da região norte.',
    ),
    _RouteInfo(
      id: '3',
      name: 'Rota 03 - Bairros Sul',
      description: 'Cobre os bairros da zona sul do município.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Selecione a Rota')),
      body: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: _availableRoutes.length,
        itemBuilder: (context, index) {
          final route = _availableRoutes[index];
          return Card(
            child: ListTile(
              title: Text(route.name),
              subtitle: Text(route.description),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // Inicia a viagem com a rota selecionada e navega para a tela de embarque.
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => BoardingScreen(
                      routeId: route.id,
                      routeName: route.name,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
