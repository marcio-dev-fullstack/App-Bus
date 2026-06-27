/// ## Arquiteto de Solução e Desenvolvedor Líder
///
/// **Márcio Rodrigues de Oliveira**
///
/// * Desenvolvedor Full Stack
/// * cda.marcio@gmail.com

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:front_end/features/sync/services/sync_service.dart';
import 'package:front_end/locator.dart';

/// Serviço responsável por disparar a sincronização automática
/// com base no estado da conectividade de rede.
class ConnectivitySyncTrigger {
  final SyncService _syncService = locator<SyncService>();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  /// Inicia o monitoramento do estado da rede.
  void initialize() {
    // Cancela qualquer monitoramento anterior para evitar duplicidade.
    _connectivitySubscription?.cancel();

    // Ouve as mudanças no estado da conectividade.
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      ConnectivityResult result,
    ) {
      print("Connectivity changed: $result");
      // Se o resultado não for 'none', significa que há uma conexão.
      if (result != ConnectivityResult.none) {
        print("Conexão detectada. Iniciando tentativa de sincronização...");
        // Dispara o serviço de sincronização.
        _syncService.sincronizarViagens();
      }
    });

    // Verifica o estado atual da conexão ao inicializar.
    _checkInitialConnection();
  }

  Future<void> _checkInitialConnection() async {
    final initialResult = await Connectivity().checkConnectivity();
    if (initialResult != ConnectivityResult.none) {
      print(
        "Conexão inicial detectada. Iniciando tentativa de sincronização...",
      );
      _syncService.sincronizarViagens();
    }
  }

  /// Para o monitoramento para liberar recursos.
  void dispose() {
    _connectivitySubscription?.cancel();
  }
}
