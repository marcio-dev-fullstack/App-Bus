/// ## Arquiteto de Solução e Desenvolvedor Líder
///
/// **Márcio Rodrigues de Oliveira**
///
/// * Desenvolvedor Full Stack
/// * cda.marcio@gmail.com

import 'dart:typed_data';

import 'dart:typed_data';

import 'package:front_end/core/database/database_service.dart';
import 'package:front_end/features/face_recognition/services/face_recognition_service.dart';
import 'package:sqflite/sqflite.dart';

/// Repositório para gerenciar as operações de Alunos
/// no banco de dados local.
class StudentRepositoryLocal {
  final DatabaseService _dbService = DatabaseService();

  /// Salva uma lista de alunos no banco de dados local.
  /// Usa um batch para performance, e o `replace` para lidar com
  /// alunos que já existem (atualizando-os).
  Future<void> salvarAlunos(List<Map<String, dynamic>> alunos) async {
    final db = await _dbService.database;
    final batch = db.batch();

    for (final aluno in alunos) {
      batch.insert(
        'alunos',
        aluno,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// Obtém um aluno comparando o vetor facial fornecido com os
  /// vetores armazenados no banco de dados.
  ///
  /// NOTA: A comparação de vetores faciais é uma operação complexa.
  /// Esta implementação busca todos os vetores e a comparação real
  /// seria delegada a um serviço de IA.
  Future<Map<String, dynamic>?> obterAlunoPorVetorFacial(
    List<double> vetorFacialDetectado,
  ) async {
    final db = await _dbService.database;
    // Busca apenas alunos que tenham um vetor facial cadastrado.
    final List<Map<String, dynamic>> todosAlunos = await db.query(
      'alunos',
      where: 'vetor_facial IS NOT NULL',
    );

    // Define um limiar de distância. Quanto menor, mais rigorosa a correspondência.
    // Este valor deve ser ajustado empiricamente com testes.
    const double limiarDeDistancia = 1.0;

    for (final aluno in todosAlunos) {
      final blob = aluno['vetor_facial'] as Uint8List;
      // Converte o BLOB (Uint8List) de volta para uma lista de doubles.
      // Isso assume que o BLOB foi salvo a partir de um Float64List.
      final vetorArmazenado = blob.buffer.asFloat64List();

      final double distancia = FaceRecognitionService.calcularDistancia(
        vetorFacialDetectado,
        vetorArmazenado.toList(),
      );

      if (distancia <= limiarDeDistancia) {
        return aluno; // Encontrou uma correspondência!
      }
    }
    return null;
  }

  /// Cadastra um novo aluno ou atualiza um existente com seu vetor facial.
  ///
  /// Usa a matrícula como chave única para determinar se deve inserir ou atualizar.
  Future<void> cadastrarOuAtualizarAlunoComVetor({
    required String nome,
    required String matricula,
    required List<double> vetorFacial,
  }) async {
    final db = await _dbService.database;

    // Converte o vetor de double para um BLOB (Uint8List) para armazenamento.
    final vetorFacialBlob = Float64List.fromList(
      vetorFacial,
    ).buffer.asUint8List();

    final alunoData = {
      'nome': nome,
      'matricula': matricula,
      'vetor_facial': vetorFacialBlob,
    };

    await db.insert(
      'alunos',
      alunoData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Obtém todos os alunos cadastrados no banco de dados local.
  Future<List<Map<String, dynamic>>> obterTodosAlunos({
    String orderBy = 'nome ASC',
    String? searchTerm,
  }) async {
    final db = await _dbService.database;

    String? whereClause;
    List<dynamic>? whereArgs;

    if (searchTerm != null && searchTerm.isNotEmpty) {
      // Usa LOWER() para garantir uma busca case-insensitive em qualquer localidade.
      final lowerCaseSearchTerm = searchTerm.toLowerCase();
      whereClause = 'LOWER(nome) LIKE ? OR LOWER(matricula) LIKE ?';
      whereArgs = ['%$lowerCaseSearchTerm%', '%$lowerCaseSearchTerm%'];
    }

    final List<Map<String, dynamic>> alunos = await db.query(
      'alunos',
      orderBy: orderBy,
      where: whereClause,
      whereArgs: whereArgs,
    );
    return alunos;
  }

  /// Atualiza os dados de um aluno existente no banco de dados.
  Future<void> atualizarDadosAluno(
    int id,
    String nome,
    String matricula,
  ) async {
    final db = await _dbService.database;
    await db.update(
      'alunos',
      {'nome': nome, 'matricula': matricula},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Deleta um aluno do banco de dados local com base no ID.
  Future<void> deletarAluno(int id) async {
    final db = await _dbService.database;
    await db.delete('alunos', where: 'id = ?', whereArgs: [id]);
  }
}
