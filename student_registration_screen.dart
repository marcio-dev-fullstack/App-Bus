/// ## Arquiteto de Solução e Desenvolvedor Líder
///
/// **Márcio Rodrigues de Oliveira**
///
/// * Desenvolvedor Full Stack
/// * cda.marcio@gmail.com

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:front_end/features/face_recognition/services/face_recognition_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:front_end/features/student/repositories/student_repository_local.dart';

class StudentRegistrationScreen extends StatefulWidget {
  const StudentRegistrationScreen({super.key});

  @override
  State<StudentRegistrationScreen> createState() =>
      _StudentRegistrationScreenState();
}

class _StudentRegistrationScreenState extends State<StudentRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _matriculaController = TextEditingController();

  // Serviços e Câmera
  final FaceRecognitionService _faceRecognitionService =
      FaceRecognitionService();
  final StudentRepositoryLocal _studentRepository = StudentRepositoryLocal();
  CameraController? _cameraController;
  CameraDescription? _cameraDescription;

  // Estado da UI
  String _permissionStatusMessage = "Inicializando...";
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  List<double>? _capturedEmbedding;

  @override
  void initState() {
    super.initState();
    _requestPermissionsAndInitialize();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceRecognitionService.dispose();
    _nameController.dispose();
    _matriculaController.dispose();
    super.dispose();
  }

  Future<void> _requestPermissionsAndInitialize() async {
    final status = await Permission.camera.request();

    if (status.isGranted) {
      await _initializeCamera();
    } else {
      setState(() {
        _permissionStatusMessage =
            "A permissão da câmera é necessária para cadastrar um aluno. Por favor, habilite-a nas configurações do aplicativo.";
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_permissionStatusMessage), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _initializeCamera() async {
    setState(() => _permissionStatusMessage = "Inicializando câmera...");

    final cameras = await availableCameras();
    _cameraDescription = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      _cameraDescription!,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await _cameraController!.initialize();
    if (!mounted) return;
    setState(() => _isCameraInitialized = true);
  }

  Future<void> _captureAndSave() async {
    if (!_formKey.currentState!.validate() || !_isCameraInitialized) {
      return;
    }

    setState(() => _isProcessing = true);

    // 1. Para o stream para garantir uma imagem nítida
    if (_cameraController!.value.isStreamingImages) {
      await _cameraController!.stopImageStream();
    }

    try {
      // 2. Captura um frame do stream da câmera
      // Esta é uma forma mais robusta de obter o CameraImage
      XFile? imageFile;
      await _cameraController!.startImageStream((image) async {
        if (imageFile != null) return; // Evita múltiplas capturas

        // Simula a captura e para o stream
        await _cameraController!.stopImageStream();

        // Processa a imagem capturada
        final result = await _faceRecognitionService.processarImagem(
          image,
          _cameraDescription!,
        );

        if (result?.embedding == null) {
          _showErrorSnackbar('Nenhum rosto detectado. Tente novamente.');
          return;
        }

        // 3. Salva no banco de dados
        await _studentRepository.cadastrarOuAtualizarAlunoComVetor(
          nome: _nameController.text,
          matricula: _matriculaController.text,
          vetorFacial: result!.embedding!,
        );

        _showSuccessSnackbar('Aluno cadastrado com sucesso!');
        Navigator.of(context).pop();
      });
    } catch (e) {
      _showErrorSnackbar('Erro ao capturar: $e');
    } finally {
      // Reinicia o stream se a tela ainda estiver visível
      if (mounted) {
        setState(() => _isProcessing = false);
        if (!_cameraController!.value.isStreamingImages) {
          // Reinicia o stream para permitir nova captura se necessário
        }
      }
    }
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastrar Novo Aluno')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nome Completo'),
                validator: (value) =>
                    value!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _matriculaController,
                decoration: const InputDecoration(labelText: 'Matrícula'),
                validator: (value) =>
                    value!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 24),
              const Text(
                'Posicione o rosto na câmera abaixo e clique em capturar.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 300,
                width: double.infinity,
                child: _isCameraInitialized
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CameraPreview(_cameraController!),
                      )
                    : Center(
                        child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [const CircularProgressIndicator(), const SizedBox(height: 16), Text(_permissionStatusMessage)],
                      )),
              ),
              const SizedBox(height: 24),
              if (_isProcessing)
                const CircularProgressIndicator()
              else
                ElevatedButton.icon(
                  onPressed: _captureAndSave,
                  icon: const Icon(Icons.camera),
                  label: const Text('CAPTURAR E SALVAR'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
