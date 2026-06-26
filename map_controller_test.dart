/// ## Arquiteto de Solução e Desenvolvedor Líder
///
/// **Márcio Rodrigues de Oliveira**
///
/// * Desenvolvedor Full Stack
/// * cda.marcio@gmail.com

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:front_end/api/directions_service.dart';
import 'package:front_end/api/places_service.dart';
import 'package:front_end/features/map/presentation/controllers/map_controller.dart';
import 'package:front_end/locator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mockito/mockito.dart';

import '../../../../mocks/generated.mocks.dart';

void main() {
  // Instâncias dos nossos mocks
  late MockPlacesService mockPlacesService;
  late MockDirectionsService mockDirectionsService;

  // Este bloco é executado ANTES de cada teste.
  setUp(() {
    // Cria novas instâncias dos mocks para garantir que cada teste seja isolado.
    mockPlacesService = MockPlacesService();
    mockDirectionsService = MockDirectionsService();

    // Limpa todos os registros anteriores do locator.
    locator.reset();

    // Registra os mocks no GetIt. Agora, quando o MapController pedir por
    // um PlacesService, ele receberá nosso mock.
    locator.registerLazySingleton<PlacesService>(() => mockPlacesService);
    locator.registerLazySingleton<DirectionsService>(
      () => mockDirectionsService,
    );
  });

  // Agrupa todos os testes relacionados ao MapController
  group('MapController Unit Tests', () {
    // Teste 1: Verifica se o estado inicial do controller está correto.
    test('Initial state is correct', () {
      // Arrange & Act: Cria a instância do controller
      final controller = MapController();

      // Assert: Verifica os valores iniciais
      expect(controller.isLoading, isTrue);
      expect(controller.markers, isEmpty);
      expect(controller.polylines, isEmpty);
      expect(controller.circles, isEmpty);
      expect(controller.origin, isNull);
      expect(controller.destination, isNull);
    });

    // Teste 2: Verifica se o método resetRoute limpa o estado corretamente.
    test('resetRoute should clear all route-related state', () {
      // Arrange: Cria o controller e simula um estado com uma rota ativa.
      final controller = MapController();
      controller.markers.add(const Marker(markerId: MarkerId('origin')));
      controller.polylines.add(const Polyline(polylineId: PolylineId('route')));
      controller.circles.add(const Circle(circleId: CircleId('pulse')));
      controller.originController.text = "Algum Lugar";

      // Act: Chama o método que queremos testar.
      controller.resetRoute();

      // Assert: Verifica se o estado foi limpo como esperado.
      expect(controller.markers, isEmpty);
      expect(controller.polylines, isEmpty);
      expect(controller.circles, isEmpty);
      expect(controller.originController.text, isEmpty);
    });

    // Teste 3: Testa o fluxo de adicionar um ponto de origem no mapa.
    test(
      'handleMapTap for the first time should set origin and call reverse geocoding',
      () async {
        // Arrange
        const tappedPoint = LatLng(10, 20);
        const fakeAddress = "Rua Fictícia, 123";

        // Configura o mock: Quando getAddressFromCoordinates for chamado com
        // o ponto específico, ele deve retornar nosso endereço falso.
        when(
          mockPlacesService.getAddressFromCoordinates(tappedPoint),
        ).thenAnswer((_) async => fakeAddress);

        final controller = MapController();

        // Act: Chama o método assíncrono.
        await controller.handleMapTap(tappedPoint);

        // Assert
        // 1. Verifica se o estado do controller foi atualizado corretamente.
        expect(controller.origin, tappedPoint);
        expect(controller.markers.length, 1);
        expect(controller.markers.first.markerId.value, 'origin');

        // 2. Verifica se o método do nosso serviço mock foi chamado exatamente 1 vez.
        // Isso prova que o controller está interagindo corretamente com suas dependências.
        verify(
          mockPlacesService.getAddressFromCoordinates(tappedPoint),
        ).called(1);

        // 3. (Opcional) Verifica se nenhuma outra interação inesperada ocorreu.
        verifyNoMoreInteractions(mockPlacesService);
        verifyZeroInteractions(mockDirectionsService);
      },
    );
  });
}
