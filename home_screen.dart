/// AUTOR:Arquiteto de Solução e Desenvolvedor Líder
/// Márcio Rodrigues de Oliveira
/// cda.marcio@gmail.com
import 'package:front_end/features/trip/screens/route_details_screen.dart';

import 'package:flutter/material.dart';
import 'package:front_end/features/trip/screens/select_route_screen.dart';
import 'package:front_end/features/trip/screens/select_route_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Card com informações do monitor
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Monitor',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                    Text(
                      'Márcio Rodrigues', // TODO: Obter nome do usuário logado
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Rota Atribuída',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                    Text(
                      'Rota 01 - Centro', // TODO: Obter rota do usuário
                      style: theme.textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(), // Ocupa o espaço disponível no centro
            // Botão para iniciar a viagem
            ElevatedButton.icon(
              icon: const Icon(Icons.directions_bus, size: 28),
              label: const Text('INICIAR NOVA VIAGEM'),
              onPressed: () {
                // Navega para a tela de seleção de rota.
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SelectRouteScreen()),
                );
              },
            ),
            const Spacer(), // Ocupa o espaço disponível no centro
          ],
        ),
      ),
    );
  }
}
