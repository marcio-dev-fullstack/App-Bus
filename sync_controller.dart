/// ## Arquiteto de Solução e Desenvolvedor Líder
///
/// **Márcio Rodrigues de Oliveira**
///
/// * Desenvolvedor Full Stack
/// * cda.marcio@gmail.com

import 'package:flutter/foundation.dart';
import 'package:front_end/api/sync_service.dart';
import 'package:front_end/features/student/repositories/student_repository_local.dart';
import 'package:front_end/features/trip/repositories/trip_repository_local.dart';
import 'package:front_end/locator.dart';

/// Controller para gerenciar a lógica de sincronização de dados
/// entre o dispositivo local e o servidor central.
class SyncController with ChangeNotifier {
  final SyncApiService _syncApiService = locator<SyncApiService>();
  final StudentRepositoryLocal _studentRepo = locator<StudentRepositoryLocal>();
  final TripRepositoryLocal _tripRepo = locator<TripRepositoryLocal>();

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  String _syncMessage = '';
  String get syncMessage => _syncMessage;

  void _setSyncState(bool syncing, [String message = '']) {
    _isSyncing = syncing;
    _syncMessage = message;
    notifyListeners();
  }

  /// Baixa os dados essenciais (alunos, rotas) do servidor e os salva
  /// no banco de dados local para operação offline.
  Future<void> baixarDadosIniciais() async {
    _setSyncState(true, 'Baixando dados iniciais...');
    try {
      final initialData = await _syncApiService.fetchInitialData();

      final alunos = List<Map<String, dynamic>>.from(
        initialData['alunos'] ?? [],
      );
      if (alunos.isNotEmpty) {
        await _studentRepo.salvarAlunos(alunos);
      }

      // TODO: Implementar a lógica para salvar as rotas.
      // final rotas = List<Map<String, dynamic>>.from(initialData['rotas'] ?? []);
      // await _routeRepo.salvarRotas(rotas);

      _setSyncState(false, 'Dados iniciais sincronizados com sucesso!');
    } catch (e) {
      _setSyncState(false, 'Erro ao baixar dados: ${e.toString()}');
      rethrow;
    }
  }

  /// Envia todas as viagens pendentes do banco de dados local para o servidor.
  Future<void> enviarViagensConcluidas() async {
    _setSyncState(true, 'Enviando viagens concluídas...');
    try {
      final viagensPendentes = await _tripRepo.obterViagensPendentes();
      for (final viagem in viagensPendentes) {
        await _syncApiService.sendCompletedTrip(viagem);
        await _tripRepo.marcarViagemComoSincronizada(viagem['id']);
      }
      _setSyncState(false, 'Sincronização de viagens concluída!');
    } catch (e) {
      _setSyncState(false, 'Erro ao enviar viagens: ${e.toString()}');
      rethrow;
    }
  }
}
