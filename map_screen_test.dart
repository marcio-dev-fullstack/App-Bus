/// ## Arquiteto de Solução e Desenvolvedor Líder
///
/// **Márcio Rodrigues de Oliveira**
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:front_end/api/directions_service.dart';
import 'package:front_end/api/places_service.dart';
import 'package:front_end/core/services/location_service.dart';
import 'package:front_end/features/map/screens/map_screen.dart';
import 'package:front_end/locator.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mockito/mockito.dart';

import '../../../../mocks/generated.mocks.dart';

void main() {
  // Configuração inicial para os mocks, similar ao teste de unidade.
  setUp(() {
    locator.reset();
    locator.registerLazySingleton<PlacesService>(() => MockPlacesService());
    locator.registerLazySingleton<DirectionsService>(
      () => MockDirectionsService(),
    );
    locator.registerLazySingleton<LocationService>(() => MockLocationService());
  });

  group('MapScreen Widget Tests', () {
    testWidgets(
      'deve exibir CircularProgressIndicator quando estiver carregando',
      (WidgetTester tester) async {
        // Arrange: Renderiza a MapScreen. O controller interno começará
        // no estado de carregamento por padrão, pois o LocationService mockado
        // ainda não retornou uma posição.
        final mockLocationService = locator<LocationService>();
        when(
          mockLocationService.getCurrentLocation(),
        ).thenAnswer((_) async => Future.delayed(const Duration(seconds: 1)));
        // no estado de carregamento por padrão.
        await tester.pumpWidget(const MaterialApp(home: MapScreen()));

        // Assert: Verifica se o indicador de progresso está na tela.
        // O pump inicial pode não ser suficiente, então damos um pump a mais.
        await tester.pump();
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      },
    );

    testWidgets('deve exibir o mapa após obter a localização', (
      WidgetTester tester,
    ) async {
      // Arrange
      final mockLocationService = locator<LocationService>();
      when(mockLocationService.getCurrentLocation()).thenAnswer(
        (_) async => Position(
          latitude: -15.79,
          longitude: -47.86,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
        ),
      );

      await tester.pumpWidget(const MaterialApp(home: MapScreen()));
      await tester.pumpAndSettle(); // Espera a localização e a UI estabilizar
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });
}
