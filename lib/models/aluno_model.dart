import 'dart:convert';

class AlunoModel {
  final int id;
  final String nome;
  final String matricula;
  final int rotaId;
  final String? escola;
  final String? turma;
  final String? faceTemplate; // Vetor numérico guardado como JSON String
  final int statusAtivo;

  AlunoModel({
    required this.id,
    required this.nome,
    required this.matricula,
    required this.rotaId,
    this.escola,
    this.turma,
    this.faceTemplate,
    this.statusAtivo = 1,
  });

  // Converte um Map do SQLite para o Objeto AlunoModel
  factory AlunoModel.fromMap(Map<String, dynamic> json) {
    return AlunoModel(
      id: json['id'],
      nome: json['nome'],
      matricula: json['matricula'],
      rotaId: json['rota_id'],
      escola: json['escola'],
      turma: json['turma'],
      faceTemplate: json['face_template'],
      statusAtivo: json['status_ativo'] ?? 1,
    );
  }

  // Converte o Objeto AlunoModel para Map para salvar no SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'matricula': matricula,
      'rota_id': rotaId,
      'escola': escola,
      'turma': turma,
      'face_template': faceTemplate,
      'status_ativo': statusAtivo,
    };
  }

  // Helper para facilitar o uso do template biométrico no código
  List<double>? get getFaceVector {
    if (faceTemplate == null) return null;
    List<dynamic> decoded = jsonDecode(faceTemplate!);
    return decoded.map((e) => e as double).toList();
  }
}