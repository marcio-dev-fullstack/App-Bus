/// ## Arquiteto de Solução e Desenvolvedor Líder
///
/// **Márcio Rodrigues de Oliveira**
///
/// * Desenvolvedor Full Stack
/// * cda.marcio@gmail.com

import 'package:flutter/material.dart';
import 'package:front_end/features/boarding/screens/boarding_screen.dart';
import 'package:front_end/features/tracking/services/tracking_service.dart';
import 'package:front_end/features/trip/repositories/trip_repository_local.dart';
import 'package:front_end/locator.dart';

class RouteDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> rota;

  const RouteDetailsScreen({super.key, required this.rota});

  Future<void> _showStartTripConfirmationDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar Início da Viagem'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  'Você tem certeza que deseja iniciar a viagem para esta rota?',
                ),
                SizedBox(height: 8),
                Text('Esta ação não poderá ser desfeita.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(); // Fecha o diálogo de confirmação
                _startTrip(context); // Inicia a viagem
              },
              child: const Text('Iniciar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _startTrip(BuildContext context) async {
    // Exibe um diálogo de carregamento para o usuário.
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Dialog(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text("Iniciando viagem..."),
              ],
            ),
          ),
        );
      },
    );

    try {
      // 1. Salva a nova viagem no banco de dados local.
      final tripRepository = locator<TripRepositoryLocal>();
      final tripId = await tripRepository.salvarViagem({
        'data_inicio': DateTime.now().toIso8601String(),
        'id_rota': rota['id'],
        'sincronizado': 0, // Marca como não sincronizado
      });

      // 2. Inicia o serviço de rastreamento contínuo por GPS.
      final trackingService = locator<TrackingService>();
      await trackingService.startTracking(tripId);

      // 3. Navega para a tela de embarque, substituindo as telas anteriores.
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => BoardingScreen(
              routeId: rota['id'].toString(),
              routeName: rota['nome'],
            ),
          ),
          (route) => false, // Remove todas as rotas anteriores da pilha.
        );
      }
    } catch (e) {
      // Em caso de erro, fecha o diálogo e exibe uma mensagem.
      if (context.mounted) {
        Navigator.of(context).pop(); // Fecha o diálogo de carregamento
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao iniciar viagem: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final veiculo = rota['veiculo'];

    return Scaffold(
      appBar: AppBar(title: Text(rota['nome'])),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailCard('Descrição da Rota', rota['descricao']),
            const SizedBox(height: 16),
            _buildDetailCard(
              'Veículo',
              '${veiculo['modelo']}\nPlaca: ${veiculo['placa']}',
            ),
            // TODO: Adicionar lista de alunos da rota aqui.
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showStartTripConfirmationDialog(context),
        icon: const Icon(Icons.directions_bus),
        label: const Text('INICIAR VIAGEM'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildDetailCard(String title, String content) {
    return Card(
      elevation: 2,
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(content, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}
