/// AUTOR:Arquiteto de Solução e Desenvolvedor Líder
/// Márcio Rodrigues de Oliveira
/// cda.marcio@gmail.com

import 'dart:async';

import 'package:front_end/core/services/location_service.dart';
import 'package:front_end/features/trip/repositories/trip_repository_local.dart';
import 'package:front_end/locator.dart';

/// Serviço responsável pelo rastreamento contínuo de GPS durante uma viagem.
class TrackingService {
  final LocationService _locationService = locator<LocationService>();
  final TripRepositoryLocal _tripRepository = locator<TripRepositoryLocal>();

  StreamSubscription? _positionStreamSubscription;
  int? _currentTripId;

  /// Inicia o rastreamento para uma viagem específica.
  Future<void> startTracking(int tripId) async {
    _currentTripId = tripId;

    // Cancela qualquer rastreamento anterior para evitar duplicidade.
    await stopTracking();

    // Configura o stream de localização para ouvir as mudanças de posição.
    _positionStreamSubscription = _locationService.getPositionStream().listen(
      (position) {
        if (_currentTripId != null) {
          // Salva cada ponto da trilha no banco de dados.
          _tripRepository.salvarPontoTrilha({
            'id_viagem': _currentTripId,
            'latitude': position.latitude,
            'longitude': position.longitude,
            'timestamp': DateTime.now().toIso8601String(),
          });
        }
      },
      onError: (error) {
        print("Erro no stream de localização: $error");
        // Adicionar lógica de tratamento de erro, se necessário.
      },
    );
  }

  /// Para o rastreamento de GPS.
  Future<void> stopTracking() async {
    await _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _currentTripId = null;
  }
}
