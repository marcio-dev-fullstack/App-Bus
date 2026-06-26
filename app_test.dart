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
import 'package:front_end/locator.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mockito/mockito.dart';

// Importa o ponto de entrada principal do seu aplicativo.
import 'package:front_end/main.dart' as app;

// Importa os mocks gerados.
import 'package:front_end/test/mocks/generated.mocks.dart';

void setupMockDependencies() {
  // Limpa quaisquer registros anteriores.
  locator.reset();

  // Registra os mocks para os serviços de API.
  locator.registerLazySingleton<PlacesService>(() => MockPlacesService());
  locator.registerLazySingleton<DirectionsService>(
    () => MockDirectionsService(),
  );
}

void main() {
  // Garante que o binding de teste de integração seja inicializado.
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Teste de Integração da Tela de Mapa', () {
    testWidgets('deve calcular e exibir uma rota ao definir origem e destino', (
      WidgetTester tester,
    ) async {
      // ARRANGE: Inicia o aplicativo.
      // Obtém as instâncias dos mocks que serão configuradas.
      final mockPlacesService = locator<PlacesService>();
      final mockDirectionsService = locator<DirectionsService>();

      // Configura o mock para a busca de ORIGEM
      when(
        mockPlacesService.getAutocomplete('Praça do Relógio, Taguatinga'),
      ).thenAnswer(
        (_) async => [
          {
            'description': 'Praça do Relógio, Taguatinga, Brasil',
            'place_id': 'fake_place_id_relogio',
          },
        ],
      );

      // Configura o mock para os detalhes da ORIGEM
      when(
        mockPlacesService.getPlaceDetails('fake_place_id_relogio'),
      ).thenAnswer(
        (_) async => {
          'geometry': {
            'location': {'lat': -15.83, 'lng': -48.05},
          },
        },
      );

      // Configura o mock para a busca de DESTINO
      when(
        mockPlacesService.getAutocomplete('Congresso Nacional, Brasília'),
      ).thenAnswer(
        (_) async => [
          {
            'description': 'Congresso Nacional, Brasília, Brasil',
            'place_id': 'fake_place_id_congresso',
          },
        ],
      );

      // Configura o mock para os detalhes do DESTINO
      when(
        mockPlacesService.getPlaceDetails('fake_place_id_congresso'),
      ).thenAnswer(
        (_) async => {
          'geometry': {
            'location': {'lat': -15.79, 'lng': -47.86},
          },
        },
      );

      // Configura o mock para a API de Direções
      when(mockDirectionsService.getDirections(any, any, any, any)).thenAnswer(
        (_) async => {
          'routes': [
            {
              'bounds': {
                'southwest': {'lat': -15.83, 'lng': -48.05},
                'northeast': {'lat': -15.79, 'lng': -47.86},
              },
              'overview_polyline': {'points': '_p~iF~ps|U_ulLnnqC_mqNvxq`@'},
              'legs': [
                {
                  'distance': {'text': '22 km'},
                  'duration': {'text': '35 min'},
                },
              ],
            },
          ],
        },
      );

      // Agora passamos a função que configura os mocks.
      app.main(setupDependencies: setupMockDependencies);
      // Espera o app renderizar e todas as animações terminarem.
      await tester.pumpAndSettle();

      // ACT 1: Navega para a tela de mapa.
      // Encontra o ícone do mapa na barra de navegação e toca nele.
      final mapIcon = find.byIcon(Icons.map_outlined);
      expect(mapIcon, findsOneWidget);
      await tester.tap(mapIcon);
      await tester.pumpAndSettle(
        const Duration(seconds: 2),
      ); // Espera a tela carregar

      // ASSERT 1: Verifica se a tela do mapa está visível.
      // Procuramos por um dos campos de texto para confirmar.
      final originField = find.widgetWithText(TextField, 'Origem');
      expect(originField, findsOneWidget);

      // ACT 2: Define uma origem.
      // Simula a digitação do usuário no campo de origem.
      await tester.enterText(originField, 'Praça do Relógio, Taguatinga');
      await tester.pumpAndSettle(
        const Duration(seconds: 2),
      ); // Espera as sugestões da API

      // Encontra a primeira sugestão e toca nela.
      final firstSuggestion = find.byType(ListTile).first;
      expect(firstSuggestion, findsOneWidget);
      await tester.tap(firstSuggestion);
      await tester.pumpAndSettle();

      // ACT 3: Define um destino.
      final destinationField = find.widgetWithText(TextField, 'Destino');
      expect(destinationField, findsOneWidget);
      await tester.enterText(destinationField, 'Congresso Nacional, Brasília');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final secondSuggestion = find.byType(ListTile).first;
      expect(secondSuggestion, findsOneWidget);
      await tester.tap(secondSuggestion);
      // Espera um tempo maior para a API de direções e a renderização da rota.
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // ASSERT 2: Verifica se o card de informações da rota foi exibido.
      // Esta é a prova de que a rota foi calculada e o estado da UI foi atualizado.
      expect(find.textContaining('km'), findsOneWidget);
      expect(find.textContaining('min'), findsOneWidget);
    });

    testWidgets(
      'não deve exibir sugestões quando a busca por locais falhar (offline)',
      (WidgetTester tester) async {
        // ARRANGE 1: Configura o mock para simular uma falha de rede.
        // Obtemos a instância do mock registrada no locator.
        final mockPlacesService = locator<PlacesService>();

        // Quando `getAutocomplete` for chamado com qualquer string,
        // ele irá lançar uma exceção, simulando uma falha de rede.
        when(
          mockPlacesService.getAutocomplete(any),
        ).thenThrow(Exception("Falha de rede simulada"));

        // ARRANGE 2: Inicia o aplicativo com os mocks.
        app.main(setupDependencies: setupMockDependencies);
        await tester.pumpAndSettle();

        // ACT 1: Navega para a tela de mapa.
        final mapIcon = find.byIcon(Icons.map_outlined);
        await tester.tap(mapIcon);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // ACT 2: Tenta buscar por um local.
        final originField = find.widgetWithText(TextField, 'Origem');
        await tester.enterText(originField, 'Qualquer lugar');
        // Espera o debounce do controller e a tentativa de chamada da API.
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // ASSERT: Verifica se nenhuma lista de sugestões apareceu na tela.
        // Isso prova que o app lidou com a falha de rede sem quebrar
        // e não exibiu dados incorretos.
        expect(find.byType(ListTile), findsNothing);
      },
    );
  });
}
