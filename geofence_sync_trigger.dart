/// ## Arquiteto de Solução e Desenvolvedor Líder
///
/// **Márcio Rodrigues de Oliveira**
///
/// * Desenvolvedor Full Stack
/// * cda.marcio@gmail.com

import 'dart:async';
import 'package:geofence_service/geofence_service.dart';
import 'package:front_end/features/sync/services/sync_service.dart';
import 'package:front_end/locator.dart';

/// Serviço responsável por disparar a sincronização automática
/// com base em geofencing (ex: ao entrar na área da escola).
class GeofenceSyncTrigger {
  final SyncService _syncService = locator<SyncService>();

  // Configura a instância do serviço de geofence.
  final _geofenceService = GeofenceService.instance.setup(
    interval: 5000, // Intervalo de verificação em milissegundos (5 segundos)
    accuracy: 100, // Precisão em metros
    loiteringDelayMs:
        60000, // Tempo para considerar que o dispositivo "parou" na área
    statusChangeDelayMs: 10000, // Atraso para notificar mudança de status
    useActivityRecognition: true,
    allowMockLocations: false,
    printDevLog: false, // Mude para true para depuração
    geofenceRadiusSortType: GeofenceRadiusSortType.DESC,
  );

  StreamSubscription<Geofence>? _geofenceStream;

  // Lista de geofences a serem monitoradas.
  // Em um app real, isso viria da API.
  final _geofenceList = <Geofence>[
    Geofence(
      id: 'escola_sede',
      latitude: -5.9045, // Exemplo: Coordenadas da SEMEC
      longitude: -49.1382,
      radius: [
        GeofenceRadius(id: 'radius_200m', length: 200), // Raio de 200 metros
      ],
    ),
  ];

  /// Inicia o monitoramento de geofence.
  void initialize() {
    // Inicia o serviço de geofence em background com a lista de zonas.
    _geofenceService.start(_geofenceList).catchError((error) {
      print("Erro ao iniciar o serviço de geofence: $error");
    });

    // Ouve as mudanças de status do geofence.
    _geofenceStream = _geofenceService.getGeofenceStream()?.listen((
      Geofence geofence,
    ) {
      if (geofence.status == GeofenceStatus.ENTER) {
        print(
          "Geofence: Dispositivo entrou na área '${geofence.id}'. Iniciando sincronização.",
        );
        _syncService.sincronizarViagens();
      }
    });
  }

  /// Para o monitoramento para liberar recursos.
  void dispose() {
    _geofenceService.stop();
    _geofenceStream?.cancel();
  }
}
