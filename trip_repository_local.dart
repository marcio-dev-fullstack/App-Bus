/// ## Arquiteto de Solução e Desenvolvedor Líder
///
/// **Márcio Rodrigues de Oliveira**
///
/// * Desenvolvedor Full Stack
/// * cda.marcio@gmail.com

import 'package:front_end/core/database/database_service.dart';
import 'package:sqflite/sqflite.dart';

/// Repositório para gerenciar as operações de Viagem e Embarque
/// no banco de dados local.
class TripRepositoryLocal {
  final DatabaseService _dbService = DatabaseService();

  /// Salva uma nova viagem no banco de dados local e retorna seu ID.
  ///
  /// O [viagemData] deve ser um mapa contendo as chaves 'data_inicio' e 'id_rota'.
  Future<int> salvarViagem(Map<String, dynamic> viagemData) async {
    final db = await _dbService.database;
    final id = await db.insert(
      'viagens',
      viagemData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return id;
  }

  /// Salva um novo evento de embarque/desembarque no banco de dados local.
  ///
  /// O [embarqueData] deve conter as chaves 'id_viagem', 'id_aluno', 'data_hora',
  /// 'latitude', 'longitude' e 'tipo'.
  Future<void> salvarEmbarque(Map<String, dynamic> embarqueData) async {
    final db = await _dbService.database;
    await db.insert(
      'embarques',
      embarqueData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Salva um ponto da trilha de GPS no banco de dados local.
  Future<void> salvarPontoTrilha(Map<String, dynamic> trilhaData) async {
    final db = await _dbService.database;
    await db.insert(
      'trilha_gps',
      trilhaData,
      conflictAlgorithm:
          ConflictAlgorithm.ignore, // Ignora se houver duplicatas
    );
  }

  /// Obtém todas as viagens que ainda não foram sincronizadas com o servidor.
  /// Retorna uma lista de viagens, cada uma contendo seus respectivos embarques.
  Future<List<Map<String, dynamic>>> obterViagensPendentes() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> viagens = await db.query(
      'viagens',
      where: 'sincronizado = ?',
      whereArgs: [0],
    );

    if (viagens.isEmpty) {
      return [];
    }

    // Otimização: Evita o problema N+1.
    // 1. Coleta todos os IDs das viagens pendentes.
    final List<int> idsViagens = viagens.map((v) => v['id'] as int).toList();

    // 2. Busca todos os embarques para essas viagens em uma única consulta.
    final Future<List<Map<String, dynamic>>> futureEmbarques = db.query(
      'embarques',
      where: 'id_viagem IN (${List.filled(idsViagens.length, '?').join(',')})',
      whereArgs: idsViagens,
    );

    // 3. Busca todos os pontos da trilha de GPS para essas viagens.
    final Future<List<Map<String, dynamic>>> futureTrilhas = db.query(
      'trilha_gps',
      where: 'id_viagem IN (${List.filled(idsViagens.length, '?').join(',')})',
      whereArgs: idsViagens,
    );

    // Executa as consultas em paralelo para otimizar o tempo.
    final results = await Future.wait([futureEmbarques, futureTrilhas]);
    final todosEmbarques = results[0];
    final todasTrilhas = results[1];

    // 3. Associa os embarques às suas respectivas viagens em memória.
    final List<Map<String, dynamic>> viagensCompletas = viagens.map((viagem) {
      final embarquesDaViagem = todosEmbarques
          .where((e) => e['id_viagem'] == viagem['id'])
          .toList();
      final trilhaDaViagem = todasTrilhas
          .where((t) => t['id_viagem'] == viagem['id'])
          .toList();

      return {
        ...viagem,
        'embarques': embarquesDaViagem,
        'trilhaGps': trilhaDaViagem,
      };
    }).toList();

    return viagensCompletas;
  }

  /// Marca uma viagem específica como sincronizada no banco de dados local.
  Future<void> marcarViagemComoSincronizada(int id) async {
    final db = await _dbService.database;
    await db.update(
      'viagens',
      {'sincronizado': 1}, // O valor a ser atualizado.
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Finaliza uma viagem, definindo sua data_fim para o momento atual.
  Future<void> finalizarViagem(int id) async {
    final db = await _dbService.database;
    await db.update(
      'viagens',
      {'data_fim': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Obtém o ID da viagem que está atualmente em andamento (sem data_fim).
  /// Retorna o ID da viagem mais recente que não foi finalizada.
  Future<int?> obterViagemAtualId() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> result = await db.query(
      'viagens',
      where: 'data_fim IS NULL',
      orderBy: 'data_inicio DESC',
      limit: 1,
    );
    return result.isNotEmpty ? result.first['id'] as int? : null;
  }
}
