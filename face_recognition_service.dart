/// ## Arquiteto de Solução e Desenvolvedor Líder
///
/// **Márcio Rodrigues de Oliveira**
///
/// * Desenvolvedor Full Stack
/// * cda.marcio@gmail.com

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

/// Serviço para encapsular a lógica de reconhecimento facial.
///
/// Esta classe será responsável por:
/// 1. Processar a imagem vinda da câmera.
/// 2. Detectar rostos na imagem.
/// 3. Converter o rosto detectado em um vetor facial (embedding).
/// 4. Comparar o vetor com os armazenados no banco de dados.
class FaceRecognitionService {
  // Instância do detector de faces do ML Kit.
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.fast,
      enableContours: true,
    ),
  );

  late final Interpreter _interpreter;
  // Instância do detector de faces do ML Kit.
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.fast,
      enableContours: true,
    ),
  );

  late final Interpreter _interpreter;

  // TODO: Carregar o modelo TensorFlow Lite (ex: FaceNet ou MobileFaceNet)
  FaceRecognitionService() {
    _loadModel();
  }

  void _loadModel() async {
    // TODO: Adicionar o arquivo do modelo .tflite nos assets do pubspec.yaml
    // Ex: assets:
    //      - assets/models/mobilefacenet.tflite
    try {
      _interpreter = await Interpreter.fromAsset('models/mobilefacenet.tflite');
    } catch (e) {
      print("Erro ao carregar o modelo TFLite: $e");
    }
  }

  /// Processa a imagem da câmera, detecta um rosto e retorna o vetor facial.
  Future<FaceProcessingResult?> processarImagem(
    CameraImage cameraImage,
    CameraDescription cameraDescription,
  ) async {
    final inputImage = _inputImageFromCameraImage(
      cameraImage,
      cameraDescription,
    );
    if (inputImage == null) return FaceProcessingResult(faces: []);

    final faces = await _faceDetector.processImage(inputImage);
    if (faces.isEmpty) {
      return FaceProcessingResult(faces: []);
    }

    // Pega o primeiro rosto detectado
    final face = faces.first;

    // Converte a imagem da câmera para um formato que o TFLite entenda
    final faceImage = _cropFace(cameraImage, face);
    if (faceImage == null) {
      // Se o recorte falhar, ainda retorna os dados do rosto para o overlay.
      return FaceProcessingResult(faces: faces);
    }

    // Extrai o vetor facial (embedding)
    final embedding = _getEmbedding(faceImage);
    return FaceProcessingResult(embedding: embedding, faces: faces);
  }

  /// Converte um [CameraImage] para um [InputImage] para uso no ML Kit.
  /// Esta função lida com as diferenças de formato entre Android (YUV) e iOS (BGRA).
  InputImage? _inputImageFromCameraImage(
    CameraImage image,
    CameraDescription cameraDescription,
  ) {
    // Obtém a rotação da imagem com base na orientação do sensor da câmera.
    // Isso é crucial para que o ML Kit processe a imagem na orientação correta.
    final sensorOrientation = cameraDescription.sensorOrientation;
    final InputImageRotation imageRotation = InputImageRotation.values
        .firstWhere(
          (element) => element.rawValue == sensorOrientation,
          orElse: () => InputImageRotation.rotation0deg,
        );

    // Formato da imagem de entrada para o ML Kit.
    final InputImageFormat inputImageFormat;
    // Bytes da imagem.
    final Uint8List bytes;
    // Metadados dos planos da imagem (relevante para Android/YUV).
    final List<InputImagePlaneMetadata> planeData;

    if (Platform.isIOS) {
      // iOS usa o formato BGRA8888.
      inputImageFormat = InputImageFormat.bgra8888;
      bytes = image.planes[0].bytes;
      planeData = const []; // Não é necessário para BGRA.
    } else {
      // Android usa o formato YUV_420_888.
      inputImageFormat = InputImageFormat.yuv420;
      // Concatena os bytes dos 3 planos (Y, U, V) em um único array.
      bytes = Uint8List.fromList(
        image.planes.fold<List<int>>(
          [],
          (list, plane) => list..addAll(plane.bytes),
        ),
      );
      planeData = image.planes
          .map(
            (plane) => InputImagePlaneMetadata(
              bytesPerRow: plane.bytesPerRow,
              height: plane.height,
              width: plane.width,
            ),
          )
          .toList();
    }

    return InputImage.fromBytes(
      bytes: bytes,
      inputImageData: InputImageData(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        imageRotation: imageRotation,
        inputImageFormat: inputImageFormat,
        planeData: planeData,
      ),
    );
  }

  /// Converte um [CameraImage] para um [img.Image] (da biblioteca 'image').
  /// Lida com a conversão de YUV (Android) e BGRA (iOS) para RGB.
  img.Image _convertCameraImage(CameraImage image) {
    final int width = image.width;
    final int height = image.height;

    if (Platform.isAndroid) {
      // Converte de YUV_420_888 para um formato de imagem RGB.
      final img.Image rgbImage = img.Image(width, height);
      final int uvRowStride = image.planes[1].bytesPerRow;
      final int uvPixelStride = image.planes[1].bytesPerPixel!;

      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final int uvIndex =
              uvPixelStride * (x / 2).floor() + uvRowStride * (y / 2).floor();
          final int index = y * width + x;

          final yp = image.planes[0].bytes[index];
          final up = image.planes[1].bytes[uvIndex];
          final vp = image.planes[2].bytes[uvIndex];

          // Converte YUV para RGB (fórmulas padrão)
          int r = (yp + vp * 1.402).round().clamp(0, 255);
          int g = (yp - up * 0.344 - vp * 0.714).round().clamp(0, 255);
          int b = (yp + up * 1.772).round().clamp(0, 255);

          rgbImage.setPixelRgba(x, y, r, g, b, 255);
        }
      }
      return rgbImage;
    } else if (Platform.isIOS) {
      // Converte de BGRA8888 para um formato de imagem RGB.
      return img.Image.fromBytes(
        width,
        height,
        image.planes[0].bytes,
        format: img.Format.bgra,
      );
    } else {
      // Retorna uma imagem vazia se a plataforma não for suportada.
      return img.Image(0, 0);
    }
  }

  img.Image? _cropFace(CameraImage image, Face face) {
    // 1. Converte a imagem da câmera (YUV ou BGRA) para uma imagem RGB padrão.
    final img.Image convertedImage = _convertCameraImage(image);

    // 2. Extrai as coordenadas do rosto detectado.
    final x = face.boundingBox.left.toInt();
    final y = face.boundingBox.top.toInt();
    final w = face.boundingBox.width.toInt();
    final h = face.boundingBox.height.toInt();

    // 3. Recorta a imagem RGB para obter apenas a região do rosto.
    final img.Image croppedImage = img.copyCrop(convertedImage, x, y, w, h);

    return croppedImage;
  }

  List<double> _getEmbedding(img.Image faceImage) {
    // Redimensiona a imagem para o tamanho esperado pelo modelo (ex: 112x112)
    final resizedImage = img.copyResize(faceImage, width: 112, height: 112);

    // Converte a imagem para um array de floats normalizado
    final imageBytes = resizedImage.getBytes();
    final input = List.generate(
      112 * 112 * 3,
      (i) => (imageBytes[i] - 127.5) / 128.0,
    ).reshape([1, 112, 112, 3]);

    // Define o tensor de saída
    final output = List.filled(1 * 192, 0.0).reshape([1, 192]);

    // Executa a inferência
    _interpreter.run(input, output);

    // Retorna o vetor de saída
    return (output[0] as List<double>);
  }

  /// Compara um vetor facial detectado com um vetor armazenado.
  /// Retorna a "distância" entre eles (um valor numérico).
  static double calcularDistancia(List<double> vetor1, List<double> vetor2) {
    if (vetor1.length != vetor2.length) {
      throw ArgumentError("Os vetores devem ter o mesmo tamanho");
    }

    double sum = 0.0;
    for (int i = 0; i < vetor1.length; i++) {
      sum += pow(vetor1[i] - vetor2[i], 2);
    }
    return sqrt(sum);
  }

  void dispose() {
    _faceDetector.close();
    _interpreter.close();
  }
}

extension Reshape on List {
  List reshape(List<int> shape) {
    if (shape.reduce((a, b) => a * b) != length) {
      throw Exception("A forma (shape) não corresponde ao tamanho da lista.");
    }

    if (shape.length == 1) return this;

    int size = shape.removeAt(0);
    List<dynamic> result = [];
    int chunkSize = length ~/ size;

    for (var i = 0; i < size; i++) {
      result.add(
        sublist(i * chunkSize, (i + 1) * chunkSize).reshape(List.from(shape)),
      );
    }
    return result;
  }
}
