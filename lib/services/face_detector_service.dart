import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:camera/camera.dart';

class FaceDetectorService {
  late FaceDetector _faceDetector;

  FaceDetectorService() {
    // Configuramos para alta precisão, ideal para validar embarque
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enablePerformanceMode: FaceDetectorMode.accurate,
        enableLandmarks: true,
      ),
    );
  }

  Future<List<Face>> detectFaces(CameraImage image) async {
    // Converte o frame da câmera para o formato que o ML Kit entende
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final inputImage = InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: InputImageRotation.rotation0deg, // Ajustar conforme a orientação do tablet
        format: InputImageFormatValue.fromRawValue(image.format.raw) ?? InputImageFormat.nv21,
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );

    return await _faceDetector.processImage(inputImage);
  }

  void dispose() {
    _faceDetector.close();
  }
}