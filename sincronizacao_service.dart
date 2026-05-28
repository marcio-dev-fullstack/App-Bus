import 'package:dio/dio';
import 'log_embarque_model.dart';

class SincronizacaoService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://api.appbus.semec.gov.br/v1', // URL fictícia de produção/homologação
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  /// Envia um lote de logs salvos localmente para o servidor
  Future<bool> sincronizarLoteLogs(List<LogEmbarqueModel> logsLocais) async {
    if (logsLocais.isEmpty) return true;

    try {
      // Monta o payload conforme a estrutura do Pydantic (LoteLogsEmbarque)
      final Map<String, dynamic> payload = {
        'logs': logsLocais.map((log) => log.toJson()).toList(),
      };

      final response = await _dio.post(
        '/logs/sincronizar-lote',
        data: payload,
      );

      if (response.statusCode == 201) {
        print('App-Bus: Sincronização em lote realizada com sucesso.');
        return true;
      }
      
      return false;
    } on DioException catch (e) {
      print('App-Bus Erro [Dio]: Falha ao sincronizar lote: ${e.message}');
      // Tratar erros específicos de rede ou servidor aqui
      return false;
    } catch (e) {
      print('App-Bus Erro [Generico]: $e');
      return false;
    }
  }
}