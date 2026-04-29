import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../database/database_helper.dart';
import '../services/face_detector_service.dart';
import '../services/biometric_service.dart';
import '../models/aluno_model.dart'; // Certifique-se de que este modelo existe
import 'dart:convert';

class FrequenciaScreen extends StatefulWidget {
  final int rotaId; // Recebe a rota selecionada para filtrar os alunos

  const FrequenciaScreen({Key? key, required this.rotaId}) : super(key: key);

  @override
  _FrequenciaScreenState createState() => _FrequenciaScreenState();
}

class _FrequenciaScreenState extends State<FrequenciaScreen> {
  CameraController? _cameraController;
  late FaceDetectorService _faceDetectorService;
  late BiometricService _biometricService;
  
  bool _isProcessing = false;
  bool _mostrarBotaoManual = false;
  int _falhasConsecutivas = 0;
  
  String _statusMensagem = "Aguardando aluno...";
  AlunoModel? _alunoIdentificado;
  List<AlunoModel> _alunosDaRota = [];

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _carregarAlunos();
  }

  // Carrega apenas os alunos da rota atual para otimizar o matching offline
  Future<void> _carregarAlunos() async {
    final db = await DatabaseHelper().database;
    final List<Map<String, dynamic>> maps = await db.query(
      'alunos',
      where: 'rota_id = ?', // Assumindo que você tem essa coluna no banco
      whereArgs: [widget.rotaId],
    );

    setState(() {
      _alunosDaRota = List.generate(maps.length, (i) {
        return AlunoModel.fromMap(maps[i]);
      });
    });
  }

  Future<void> _initializeServices() async {
    _faceDetectorService = FaceDetectorService();
    _biometricService = BiometricService();
    await _biometricService.loadModel();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
    );

    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    await _cameraController!.initialize();
    if (!mounted) return;

    _cameraController!.startImageStream((CameraImage image) {
      if (!_isProcessing && _alunoIdentificado == null) {
        _processImageFrame(image);
      }
    });

    setState(() {});
  }

  Future<void> _processImageFrame(CameraImage image) async {
    _isProcessing = true;

    try {
      final faces = await _faceDetectorService.detectFaces(image);

      if (faces.isNotEmpty) {
        // 1. Aqui o motor gera o embedding do rosto atual (virei código no BiometricService)
        // List faceEmbedding = await _biometricService.getEmbedding(image, faces.first);

        // 2. Busca o aluno por comparação de biometria
        for (var aluno in _alunosDaRota) {
          if (aluno.faceTemplate != null) {
            // Converte a String do banco de volta para lista numérica
            List savedTemplate = jsonDecode(aluno.faceTemplate!);
            
            // Simulação de matching (Substituir pela chamada real do BiometricService)
            bool isMatch = false; // _biometricService.isSamePerson(faceEmbedding, savedTemplate);

            if (isMatch) {
              setState(() {
                _alunoIdentificado = aluno;
                _statusMensagem = "Aluno identificado: ${aluno.nome}";
              });
              await _registrarEmbarque('biometria', aluno.id);
              break;
            }
          }
        }

        // Se após percorrer não achar ninguém
        if (_alunoIdentificado == null) {
          _falhasConsecutivas++;
          if (_falhasConsecutivas > 5) {
            setState(() => _mostrarBotaoManual = true);
          }
        }
      }
    } catch (e) {
      debugPrint("Erro no processamento: $e");
    } finally {
      await Future.delayed(const Duration(milliseconds: 600));
      _isProcessing = false;
    }
  }

  Future<void> _registrarEmbarque(String metodo, int alunoId) async {
    final db = await DatabaseHelper().database;
    
    await db.insert('logs_embarque', {
      'aluno_id': alunoId,
      'data_hora': DateTime.now().toIso8601String(),
      'metodo_validacao': metodo,
      'status_sincronizado': 0,
    });

    // Feedback visual de sucesso
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Embarque de ${_alunoIdentificado?.nome ?? "Aluno"} registrado!')),
      );
    }

    // Aguarda 3 segundos para o próximo aluno (evita registros duplicados)
    await Future.delayed(const Duration(seconds: 3));
    
    setState(() {
      _alunoIdentificado = null;
      _falhasConsecutivas = 0;
      _mostrarBotaoManual = false;
      _statusMensagem = "Aguardando próximo aluno...";
    });
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceDetectorService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Sistema BusEscolar - SEMEC")),
      body: Column(
        children: [
          // View da Câmera
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.45,
            child: CameraPreview(_cameraController!),
          ),

          // Painel de Informações
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _alunoIdentificado != null ? Colors.green.shade50 : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _alunoIdentificado != null ? Icons.check_circle : Icons.face,
                    size: 60,
                    color: _alunoIdentificado != null ? Colors.green : Colors.blueGrey,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _statusMensagem,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  
                  if (_mostrarBotaoManual) ...[
                    const SizedBox(height: 20),
                    const Text("Não reconheceu o aluno?"),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade900,
                        minimumSize: const Size(250, 50),
                      ),
                      onPressed: () {
                        // Aqui abriria uma busca rápida por nome/matrícula
                        _mostrarSelecaoManual();
                      },
                      child: const Text("SELECIONAR ALUNO MANUALMENTE", style: TextStyle(color: Colors.white)),
                    ),
                  ]
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Abre um modal para o monitor escolher o aluno da lista caso a biometria falhe
  void _mostrarSelecaoManual() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView.builder(
          itemCount: _alunosDaRota.length,
          itemBuilder: (context, index) {
            final aluno = _alunosDaRota[index];
            return ListTile(
              leading: const Icon(Icons.person),
              title: Text(aluno.nome),
              subtitle: Text("Matrícula: ${aluno.matricula}"),
              onTap: () {
                Navigator.pop(context);
                setState(() => _alunoIdentificado = aluno);
                _registrarEmbarque('manual', aluno.id);
              },
            );
          },
        );
      },
    );
  }
}