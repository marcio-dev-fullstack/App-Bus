/// ## Arquiteto de Solução e Desenvolvedor Líder
///
/// **Márcio Rodrigues de Oliveira**
///
/// * Desenvolvedor Full Stack
/// * cda.marcio@gmail.com

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:front_end/core/services/face_recognition_service.dart';
import 'package:front_end/features/student/repositories/student_repository_local.dart';
import 'package:front_end/locator.dart';

// Modelo simples para representar um aluno. Em um app real, viria de um arquivo de modelo.
class _StudentInfo {
  final String id;
  final String name;
  final String status; // Ex: 'Aguardando', 'Embarcado', 'Ausente'

  _StudentInfo({required this.id, required this.name, required this.status});

  _StudentInfo copyWith({String? status}) {
    return _StudentInfo(id: id, name: name, status: status ?? this.status);
  }
}

class BoardingScreen extends StatefulWidget {
  final String routeId;
  final String routeName;

  const BoardingScreen({
    super.key,
    required this.routeId,
    required this.routeName,
  });

  @override
  State<BoardingScreen> createState() => _BoardingScreenState();
}

class _BoardingScreenState extends State<BoardingScreen> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  final FaceRecognitionService _faceRecognitionService =
      locator<FaceRecognitionService>();
  final StudentRepositoryLocal _studentRepository =
      locator<StudentRepositoryLocal>();
  bool _isProcessing = false;

  // Dados de exemplo. Em um app real, viriam do banco de dados local.
  List<_StudentInfo> _students = [
    _StudentInfo(id: '1', name: 'João da Silva', status: 'Aguardando'),
    _StudentInfo(id: '2', name: 'Maria Oliveira', status: 'Aguardando'),
    _StudentInfo(id: '3', name: 'Pedro Martins', status: 'Aguardando'),
    _StudentInfo(id: '4', name: 'Ana Costa', status: 'Aguardando'),
  ];

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      // Seleciona a câmera frontal para o reconhecimento facial.
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () =>
            cameras.first, // Fallback para a primeira câmera disponível.
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false, // Áudio não é necessário.
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
        // Inicia o stream de imagens para o FaceRecognitionService.
        _cameraController!.startImageStream((image) {
          if (_isProcessing)
            return; // Se já estiver processando, ignora este quadro.

          _isProcessing = true;
          _faceRecognitionService
              .processarImagem(image) // Retorna o vetor facial (embedding)
              .then((faceEmbedding) async {
                if (faceEmbedding == null) return;

                // Com o vetor, busca o aluno correspondente no repositório local.
                final recognizedStudent = await _studentRepository
                    .obterAlunoPorVetorFacial(faceEmbedding);

                if (recognizedStudent == null) return;

                // Atualiza o status do aluno na lista da UI.
                setState(() {
                  final studentId = recognizedStudent['id'].toString();
                  final index = _students.indexWhere(
                    (student) => student.id == studentId,
                  );
                  if (index != -1) {
                    _students[index] = _students[index].copyWith(
                      status: 'Embarcado',
                    );
                  }
                });
              })
              .whenComplete(() {
                // Adiciona um pequeno delay antes de liberar o próximo processamento
                // para dar tempo ao usuário de ver a atualização na UI.
                Future.delayed(
                  const Duration(seconds: 2),
                ).then((_) => _isProcessing = false);
              });
        });
      }
    } catch (e) {
      print("Erro ao inicializar a câmera: $e");
      // TODO: Exibir uma mensagem de erro para o usuário.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.routeName),
        actions: [
          TextButton(
            onPressed: () {
              // TODO: Implementar lógica para finalizar a viagem.
            },
            child: const Text('FINALIZAR'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Placeholder para a visualização da câmera
          AspectRatio(
            aspectRatio: 1.0, // Câmera quadrada
            child: _isCameraInitialized
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: CameraPreview(_cameraController!),
                  )
                : Container(
                    color: Colors.black,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
          ),
          // Lista de alunos
          Expanded(
            child: ListView.builder(
              itemCount: _students.length,
              itemBuilder: (context, index) {
                final student = _students[index];
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(student.name),
                  subtitle: Text(student.status),
                  trailing: _getStatusIcon(student.status),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _isProcessing = false;
    super.dispose();
  }

  Icon? _getStatusIcon(String status) {
    if (status == 'Embarcado')
      return const Icon(Icons.check_circle, color: Colors.green);
    if (status == 'Ausente') return const Icon(Icons.cancel, color: Colors.red);
    return null;
  }
}
