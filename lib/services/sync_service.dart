import 'package:connectivity_plus/connectivity_plus.dart';
import '../database/database_helper.dart';

class SyncService {
  final dbHelper = DatabaseHelper();

  Future<void> checkAndSync() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    
    // Se tiver Wi-Fi ou Dados Móveis
    if (connectivityResult != ConnectivityResult.none) {
      print("Conexão detectada. Iniciando sincronização...");
      await _uploadLogs();
    }
  }

  Future<void> _uploadLogs() async {
    final db = await dbHelper.database;
    
    // Busca logs pendentes
    List<Map<String, dynamic>> pendingLogs = await db.query(
      'logs_embarque', 
      where: 'status_sincronizado = ?', 
      whereArgs: [0]
    );

    if (pendingLogs.isEmpty) return;

    try {
      // Aqui entrará sua lógica de POST para o backend da SEMEC
      // Se o envio for sucesso:
      await db.update(
        'logs_embarque',
        {'status_sincronizado': 1},
        where: 'status_sincronizado = ?',
        whereArgs: [0],
      );
      print("Sincronização concluída!");
    } catch (e) {
      print("Erro ao sincronizar: $e");
    }
  }
}