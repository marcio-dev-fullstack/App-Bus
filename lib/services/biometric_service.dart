import 'dart:math';
import 'package:tflite_flutter/tflite_flutter.dart';

class BiometricService {
  Interpreter? _interpreter;

  // Carrega o modelo MobileFaceNet (leve para tablets)
  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('mobilefacenet.tflite');
      print("Modelo biométrico carregado.");
    } catch (e) {
      print("Erro ao carregar modelo: $e");
    }
  }

  // Calcula a Distância Euclidiana entre dois vetores
  // Quanto menor a distância, maior a probabilidade de ser a mesma pessoa
  double compare(List face1, List face2) {
    double sum = 0;
    for (int i = 0; i < face1.length; i++) {
      sum += pow((face1[i] - face2[i]), 2);
    }
    return sqrt(sum);
  }

  // Define se é a mesma pessoa (Threshold)
  // Geralmente, uma distância menor que 1.0 indica que é o mesmo aluno
  bool isSamePerson(List embedding1, List embedding2) {
    double distance = compare(embedding1, embedding2);
    return distance < 0.85; // Ajuste conforme os testes nos tablets
  }
}