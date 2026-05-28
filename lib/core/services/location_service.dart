import 'package:flutter/foundation.dart'; // Necessário para usar kIsWeb
import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<Position> getCurrentLocation() async {
    // 💡 SOLUÇÃO PARA REDE LOCAL: Se estiver rodando no navegador (Web),
    // simula uma localização fixa em Conceição do Araguaia para ignorar a trava do HTTPS.
    if (kIsWeb) {
      return Position(
        latitude: -8.2578, // Coordenadas aproximadas de CDA
        longitude: -49.2630,
        timestamp: DateTime.now(),
        accuracy: 1.0,
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );
    }

    // Código nativo original que roda no Android/iOS (com validações reais de GPS)
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('O serviço de localização está desativado.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Permissão de localização negada.');
      }
    }

    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  bool verificarChegadaEscola(Position currentPos, double escolaLat,
      double escolaLng, double raioMetros) {
    double distanceInMeters = Geolocator.distanceBetween(
        currentPos.latitude, currentPos.longitude, escolaLat, escolaLng);
    return distanceInMeters <= raioMetros;
  }
}
