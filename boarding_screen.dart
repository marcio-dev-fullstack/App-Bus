/// ## Arquiteto de Solução e Desenvolvedor Líder
///
/// **Márcio Rodrigues de Oliveira**
///
import 'dart:ui' as ui;

/// * Desenvolvedor Full Stack
/// * cda.marcio@gmail.com

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:front_end/features/face_recognition/services/face_recognition_service.dart';
import 'package:front_end/features/student/repositories/student_repository_local.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:front_end/core/services/location_service.dart';
import 'package:front_end/locator.dart';
import 'package:front_end/features/trip/repositories/trip_repository_local.dart';

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
  // Serviços e Repositórios
  final FaceRecognitionService _faceRecognitionService =
      FaceRecognitionService();
  final StudentRepositoryLocal _studentRepository = StudentRepositoryLocal();
  final LocationService _locationService = locator<LocationService>();
  final TripRepositoryLocal _tripRepository = TripRepositoryLocal();

  // Controle da Câmera
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  CameraDescription? _cameraDescription;

  // Estado da UI
  String _permissionStatusMessage = "Inicializando...";
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  bool _isFaceDetected = false; // Novo estado para rastrear a detecção de rosto
  List<Face> _detectedFaces = []; // Novo estado para armazenar os contornos
  String _recognitionResult = "Aponte a câmera para o rosto do aluno";
  Color _resultColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _requestPermissionsAndInitialize();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceRecognitionService.dispose();
    super.dispose();
  }

  Future<void> _requestPermissionsAndInitialize() async {
    // Solicita permissões de câmera e localização simultaneamente.
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.location,
    ].request();

    // Verifica se ambas as permissões foram concedidas.
    if (statuses[Permission.camera]!.isGranted &&
        statuses[Permission.location]!.isGranted) {
      await _initializeCamera();
    } else {
      // Se alguma permissão for negada permanentemente, informa o usuário.
      setState(() {
        _permissionStatusMessage =
            "Permissões de câmera e localização são necessárias para usar esta funcionalidade. Por favor, habilite-as nas configurações do aplicativo.";
      });
    }
  }

  Future<void> _initializeCamera() async {
    setState(() {
      _permissionStatusMessage = "Inicializando câmera...";
    });

    _cameras = await availableCameras();
    // Usa a câmera frontal por padrão
    _cameraDescription = _cameras?.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => _cameras!.first,
    );

    if (_cameraDescription == null) return;

    _cameraController = CameraController(
      _cameraDescription!,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await _cameraController!.initialize();

    if (!mounted) return;

    setState(() {
      _isCameraInitialized = true;
    });

    // Inicia o stream de imagens para processamento
    _cameraController!.startImageStream(_processImageStream);
  }

  void _processImageStream(CameraImage cameraImage) async {
    if (_isProcessing || !mounted) return;

    _isProcessing = true;

    try {
      // Processa a imagem para obter o vetor facial
      final result = await _faceRecognitionService.processarImagem(
        cameraImage,
        _cameraDescription!,
      );

      final bool faceDetectedThisFrame = result?.embedding != null;

      // Atualiza o estado da UI se o status de detecção de rosto mudou.
      if (_isFaceDetected != faceDetectedThisFrame ||
          _detectedFaces != (result?.faces ?? [])) {
        setState(() {
          _isFaceDetected = faceDetectedThisFrame;
          _detectedFaces = result?.faces ?? [];
        });
      }

      if (faceDetectedThisFrame) {
        // Se um rosto foi detectado e o vetor extraído, busca no banco
        final student = await _studentRepository.obterAlunoPorVetorFacial(
          result!.embedding!,
        );

        if (student != null) {
          // Aluno encontrado! Para o processamento e exibe o resultado.
          await _cameraController!.stopImageStream();
          setState(() {
            _recognitionResult = "Bem-vindo(a), ${student['nome']}!";
            _resultColor = Colors.greenAccent;
          });

          // ** REGISTRA O EMBARQUE NO BANCO DE DADOS LOCAL **
          final tripId = await _tripRepository.obterViagemAtualId();
          if (tripId != null) {
            // Captura a localização atual no momento do embarque.
            final position = await _locationService.getCurrentLocation();
            await _tripRepository.salvarEmbarque({
              'id_viagem': tripId,
              'id_aluno': student['id'],
              'data_hora': DateTime.now().toIso8601String(),
              // Adiciona as coordenadas ao registro.
              'latitude': position.latitude,
              'longitude': position.longitude,
            });
          }

          // Aguarda um pouco e reinicia o processo
          await Future.delayed(const Duration(seconds: 3));
          _resetRecognition();
        }
      }
    } catch (e) {
      print("Erro durante o processamento da imagem: $e");
      // Opcional: Exibir uma mensagem de erro na UI
      setState(() {
        _recognitionResult = "Erro ao processar. Tente novamente.";
        _resultColor = Colors.red;
      });
      await Future.delayed(const Duration(seconds: 2));
      _resetRecognition();
    } finally {
      // Libera para o próximo frame
      _isProcessing = false;
    }
  }

  void _resetRecognition() {
    if (!_isCameraInitialized || _cameraController == null) return;

    setState(() {
      _recognitionResult = "Aponte a câmera para o rosto do aluno";
      _resultColor = Colors.white;
      _isFaceDetected = false;
      _detectedFaces = [];
    });
    _cameraController!.startImageStream(_processImageStream);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Embarque - ${widget.routeName}')),
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Câmera View
          if (_isCameraInitialized && _cameraController != null)
            Transform.scale(
              scale:
                  1 /
                  (_cameraController!.value.aspectRatio *
                      MediaQuery.of(context).size.aspectRatio),
              alignment: Alignment.topCenter,
              child: CameraPreview(_cameraController!),
            )
          else
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [const CircularProgressIndicator(), const SizedBox(height: 16), Text(_permissionStatusMessage)],
              ),
            ),

          // Overlay para guiar o posicionamento do rosto
          if (_isCameraInitialized)
            CustomPaint(
              size: MediaQuery.of(context).size,
              painter: FaceOverlayPainter(
                isFaceDetected: _isFaceDetected,
                resultColor: _resultColor,
                faces: _detectedFaces,
                imageSize: _cameraController!.value.previewSize!,
                cameraLensDirection: _cameraDescription!.lensDirection,
              ),
            ),

          // Overlay com o resultado
          Positioned(
            bottom: 50,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _recognitionResult,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _resultColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Um CustomPainter para desenhar um overlay com um recorte oval.
/// Isso ajuda o usuário a centralizar o rosto na câmera.
class FaceOverlayPainter extends CustomPainter {
  final bool isFaceDetected;
  final Color resultColor;
  final List<Face> faces;
  final Size imageSize;
  final CameraLensDirection cameraLensDirection;

  FaceOverlayPainter({
    required this.isFaceDetected,
    required this.resultColor,
    required this.faces,
    required this.imageSize,
    required this.cameraLensDirection,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.6);
    // Desenha o overlay escuro com o recorte oval
    _drawOvalOverlay(canvas, size, paint);

    // Define as dimensões e a posição do recorte oval.
    final double ovalHorizontalMargin = size.width * 0.12;
    final double ovalVerticalMargin = size.height * 0.25;
    final Rect ovalRect = Rect.fromLTRB(
      ovalHorizontalMargin,
      ovalVerticalMargin,
      size.width - ovalHorizontalMargin,
      size.height - ovalVerticalMargin,
    );

    // Desenha a borda do oval com a cor dinâmica
    _drawOvalBorder(canvas, ovalRect);

    // Desenha os contornos do rosto
    _drawFaceContours(canvas, size);
  }

  void _drawOvalBorder(Canvas canvas, Rect ovalRect) {
    final Color borderColor;
    if (resultColor == Colors.greenAccent) {
      borderColor = Colors.greenAccent; // Sucesso
    } else if (isFaceDetected) {
      borderColor = Colors.yellow; // Rosto detectado, processando
    } else {
      borderColor = Colors.white; // Padrão
    }

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawOval(ovalRect, borderPaint);
  }

  void _drawOvalOverlay(Canvas canvas, Size size, Paint paint) {
    final double ovalHorizontalMargin = size.width * 0.12;
    final double ovalVerticalMargin = size.height * 0.25;
    final Rect ovalRect = Rect.fromLTRB(
      ovalHorizontalMargin,
      ovalVerticalMargin,
      size.width - ovalHorizontalMargin,
      size.height - ovalVerticalMargin,
    );

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(ovalRect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
  }

  void _drawFaceContours(Canvas canvas, Size size) {
    if (faces.isEmpty) return;

    final contourPaint = Paint()
      ..color = Colors.yellow.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (final face in faces) {
      final Map<FaceContourType, FaceContour?> contours = face.contours;
      contours.forEach((type, contour) {
        if (contour != null) {
          final List<Offset> points = contour.points
              .map((p) => _translatePoint(p, size))
              .toList();
          canvas.drawPoints(ui.PointMode.polygon, points, contourPaint);
        }
      });
    }
  }

  /// Traduz um ponto das coordenadas da imagem para as coordenadas da tela.
  Offset _translatePoint(ui.Offset point, Size canvasSize) {
    // Calcula os fatores de escala para largura e altura.
    final double scaleX = canvasSize.width / imageSize.height;
    final double scaleY = canvasSize.height / imageSize.width;

    // A imagem da câmera vem rotacionada. Precisamos ajustar as coordenadas.
    final double x, y;
    if (cameraLensDirection == CameraLensDirection.front) {
      // A câmera frontal é espelhada horizontalmente.
      x = canvasSize.width - (point.dy * scaleX);
    } else {
      x = point.dy * scaleX;
    }
    y = point.dx * scaleY;

    return Offset(x, y);
  }

  @override
  bool shouldRepaint(covariant FaceOverlayPainter oldDelegate) {
    // Redesenha se o status de detecção, a cor do resultado ou os rostos mudarem.
    return oldDelegate.isFaceDetected != isFaceDetected ||
        oldDelegate.resultColor != resultColor ||
        oldDelegate.faces != faces;
  }
}

/// Classe para encapsular os resultados do processamento facial.
class FaceProcessingResult {
  final List<double>? embedding;
  final List<Face> faces;

  FaceProcessingResult({this.embedding, required this.faces});
}
