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

  /// Obtém todas as viagens que ainda não foram sincronizadas com o servidor.
  /// Retorna uma lista de viagens, cada uma contendo seus respectivos embarques.
  Future<List<Map<String, dynamic>>> obterViagensPendentes() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> viagens = await db.query(
      'viagens',
      where: 'sincronizado = ?',
      whereArgs: [0],
    );

    // Para cada viagem, busca os embarques associados.
    for (var i = 0; i < viagens.length; i++) {
      final embarques = await db.query(
        'embarques',
        where: 'id_viagem = ?',
        whereArgs: [viagens[i]['id']],
      );
      viagens[i] = {...viagens[i], 'embarques': embarques};
    }

    return viagens;
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
}
