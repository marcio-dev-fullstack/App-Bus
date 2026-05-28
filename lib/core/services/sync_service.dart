import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import '../database/db_helper.dart'; // <-- Garanta que o import está assim e nada mais

class SyncService {
  final DbHelper _dbHelper = DbHelper.instance;
  
  final String _apiEndpoint = "https://api.esemec.conceicaodoaraguaia.pa.gov.br/v1/transporte/embarque";

  Future<bool> verificarConexaoAtiva() async {
    var resultado = await (Connectivity().checkConnectivity());
    return resultado == ConnectivityResult.mobile || resultado == ConnectivityResult.wifi;
  }

  Future<bool> sincronizarLogsPendentes() async {
    if (!await verificarConexaoAtiva()) return false;

    try {
      final db = await _dbHelper.database;
      
      final List<Map<String, dynamic>> pendentes = await db.query(
        'logs_embarque',
        where: 'sincronizado = ?',
        whereArgs: [0],
      );

      if (pendentes.isEmpty) return true;

      for (var log in pendentes) {
        final payload = jsonEncode({
          "id_evento": log['id'],
          "id_aluno": log['aluno_id'],
          "data_hora": log['timestamp'],
          "coordenadas": {
            "lat": log['latitude'],
            "lng": log['longitude']
          },
          "validacao": log['metodo_validacao']
        });

        final response = await http.post(
          Uri.parse(_apiEndpoint),
          headers: {"Content-Type": "application/json"},
          body: payload,
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200 || response.statusCode == 201) {
          await db.update(
            'logs_embarque',
            {'sincronizado': 1},
            where: 'id = ?',
            whereArgs: [log['id']],
          );
        } else {
          return false;
        }
      }
      return true;
    } catch (e) {
      print("Falha na sincronização em background: $e");
      return false;
    }
  }
}