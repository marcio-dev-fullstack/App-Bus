/// AUTOR:Arquiteto de Solução e Desenvolvedor Líder
/// Márcio Rodrigues de Oliveira
/// cda.marcio@gmail.com

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:front_end/features/auth/controllers/auth_controller.dart';
import 'package:front_end/features/face_recognition/services/face_recognition_service.dart';
import 'package:front_end/features/student/repositories/student_repository_local.dart';
import 'package:front_end/locator.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mockito/mockito.dart';

import 'package:front_end/main.dart' as app;

import 'mocks/generated.mocks.dart';

void setupMockDependencies() {
  locator.reset();

  // Mock para o AuthController, simulando um usuário já logado.
  final mockAuthController = MockAuthController();
  when(mockAuthController.isAuthenticated).thenReturn(true);
  when(mockAuthController.isLoading).thenReturn(false);
  locator.registerSingleton<AuthController>(mockAuthController);

  // Mock para o serviço de reconhecimento facial.
  final mockFaceService = MockFaceRecognitionService();
  // Quando `processarImagem` for chamado, simulamos um resultado bem-sucedido.
  when(mockFaceService.processarImagem(any, any)).thenAnswer(
    (_) async => FaceProcessingResult(
      embedding: List.generate(192, (index) => 1.0), // Vetor facial falso
      faces: [MockFace()], // Objeto de rosto falso
    ),
  );
  locator.registerSingleton<FaceRecognitionService>(mockFaceService);

  // Mock para o repositório de alunos.
  final mockStudentRepo = MockStudentRepositoryLocal();
  locator.registerSingleton<StudentRepositoryLocal>(mockStudentRepo);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Teste de Integração do Cadastro de Aluno', () {
    testWidgets('deve cadastrar um novo aluno com sucesso após capturar o rosto', (
      WidgetTester tester,
    ) async {
      // ARRANGE: Inicia o app com as dependências mockadas.
      setupMockDependencies();
      app.main();
      await tester.pumpAndSettle();

      // ACT 1: Navega para a tela de cadastro.
      final registerButton = find.widgetWithText(
        FloatingActionButton,
        'Cadastrar',
      );
      expect(registerButton, findsOneWidget);
      await tester.tap(registerButton);
      await tester.pumpAndSettle();

      // ASSERT 1: Verifica se a tela de cadastro foi aberta.
      expect(find.text('Cadastrar Novo Aluno'), findsOneWidget);

      // ACT 2: Preenche os dados do aluno.
      final nameField = find.widgetWithText(TextFormField, 'Nome Completo');
      final matriculaField = find.widgetWithText(TextFormField, 'Matrícula');

      await tester.enterText(nameField, 'Aluno de Teste');
      await tester.enterText(matriculaField, '2026-TEST');
      await tester.pumpAndSettle();

      // ACT 3: Toca no botão para capturar e salvar.
      final captureButton = find.widgetWithText(
        ElevatedButton,
        'CAPTURAR E SALVAR',
      );
      expect(captureButton, findsOneWidget);
      await tester.tap(captureButton);

      // Aguarda o processamento simulado da imagem e a chamada ao repositório.
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // ASSERT 2: Verifica se o método de cadastro no repositório foi chamado
      // com os dados corretos.
      final mockStudentRepo = locator<StudentRepositoryLocal>();
      verify(
        mockStudentRepo.cadastrarOuAtualizarAlunoComVetor(
          nome: 'Aluno de Teste',
          matricula: '2026-TEST',
          vetorFacial: anyNamed('vetorFacial'),
        ),
      ).called(1);

      // ASSERT 3: Verifica se o app navegou de volta para a tela anterior (Home).
      // A tela de cadastro não deve mais estar visível.
      expect(find.text('Cadastrar Novo Aluno'), findsNothing);
    });
  });
}

/// Classe mock mínima para satisfazer a dependência do tipo `Face`.
class MockFace extends Mock implements Face {
  @override
  final Rect boundingBox = const Rect.fromLTWH(0, 0, 100, 100);

  @override
  final Map<FaceContourType, FaceContour?> contours = const {};

  @override
  final int? trackingId = 1;
}
