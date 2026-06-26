/// ## Arquiteto de Solução e Desenvolvedor Líder
///
/// **Márcio Rodrigues de Oliveira**
///
/// * Desenvolvedor Full Stack
/// * cda.marcio@gmail.com

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
  Future<List<double>?> processarImagem(CameraImage cameraImage) async {
    final inputImage = _inputImageFromCameraImage(cameraImage);
    if (inputImage == null) return null;

    final faces = await _faceDetector.processImage(inputImage);
    if (faces.isEmpty) return null;

    // Pega o primeiro rosto detectado
    final face = faces.first;

    // Converte a imagem da câmera para um formato que o TFLite entenda
    final faceImage = _cropFace(cameraImage, face);
    if (faceImage == null) return null;

    // Extrai o vetor facial (embedding)
    final embedding = _getEmbedding(faceImage);
    return embedding;
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    // TODO: Implementar a conversão correta de YUV_420_888 para InputImage
    // Esta parte pode ser complexa e depende do formato da imagem da câmera.
    // A documentação do google_mlkit_face_detection pode ajudar.
    // Por enquanto, retornamos null como placeholder.
    return null;
  }

  img.Image? _cropFace(CameraImage image, Face face) {
    // TODO: Implementar a conversão de CameraImage para img.Image
    // e depois cortar o rosto usando o boundingBox do objeto Face.
    // A biblioteca 'image' será necessária aqui.
    return null;
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
      result.add(sublist(i * chunkSize, (i + 1) * chunkSize).reshape(List.from(shape)));
    }
    return result;
  }
}
    // Quanto menor a distância, mais parecidos são os rostos.
    return 1.0; // Retorna um valor alto como placeholder.
  }
}