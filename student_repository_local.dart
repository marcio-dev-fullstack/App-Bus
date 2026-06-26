/// ## Arquiteto de Solução e Desenvolvedor Líder
///
/// **Márcio Rodrigues de Oliveira**
///
/// * Desenvolvedor Full Stack
/// * cda.marcio@gmail.com

import 'dart:typed_data';

import 'package:front_end/core/database/database_service.dart';
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
    Uint8List vetorFacial,
  ) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> todosAlunos = await db.query('alunos');

    // --- LÓGICA DE COMPARAÇÃO (SIMULADA) ---
    // Em um cenário real, aqui ocorreria a comparação matemática dos vetores.
    // Para esta demonstração, vamos simplesmente retornar um aluno fixo
    // para simular uma correspondência bem-sucedida.
    if (vetorFacial.isNotEmpty) {
      return {'id': 2, 'nome': 'Maria Oliveira', 'matricula': '2026002', 'id_rota': 1};
    }
    return null;
  }
}
