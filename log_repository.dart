import 'package:uuid/uuid.dart'; // flutter pub add uuid (útil para IDs locais)
import '../models/log_embarque_model.dart'; // Seu model existente
import 'db_helper.dart';

class LogRepository {
  final dbHelper = DbHelper.instance;

  // Insere o bipaço do aluno no banco local do celular/tablet
  Future<void> inserirLogLocal(LogEmbarqueModel log) async {
    final db = await dbHelper.database;
    await db.insert(
      DbHelper.tableLogs,
      {
        'id': const Uuid().v4(), // Identificador único do log local
        'aluno_id': log.alunoId,
        'veiculo_id': log.veiculoId,
        'rota_id': log.rotaId,
        'timestamp_dispositivo': log.timestampDispositivo.toIso8601String(),
        'latitude': log.latitude,
        'longitude': log.longitude,
      },
    );
  }

  // Busca todos os logs que estão represados no aparelho aguardando internet
  Future<List<LogEmbarqueModel>> buscarLogsRetidos() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(DbHelper.tableLogs);

    return List.generate(maps.length, (i) {
      return LogEmbarqueModel(
        alunoId: maps[i]['aluno_id'],
        veiculoId: maps[i]['veiculo_id'],
        rotaId: maps[i]['rota_id'],
        timestampDispositivo: DateTime.parse(maps[i]['timestamp_dispositivo']),
        latitude: maps[i]['latitude'],
        longitude: maps[i]['longitude'],
        sincronizacaoOffline: true,
      );
    });
  }

  // Limpa o lote do banco local assim que o FastAPI confirmar o recebimento
  Future<void> limparLoteSincronizado(List<LogEmbarqueModel> lote) async {
    final db = await dbHelper.database;
    for (var log in lote) {
      await db.delete(
        DbHelper.tableLogs,
        where: 'aluno_id = ? AND timestamp_dispositivo = ?',
        whereArgs: [log.alunoId, log.timestampDispositivo.toIso8601String()],
      );
    }
  }
}