import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  /// Verifica o estado atual da conexão
  Future<bool> verificarConexaoAtiva() async {
    final List<ConnectivityResult> resultados = await _connectivity.checkConnectivity();
    return _validarResultados(resultados);
  }

  /// Escuta as mudanças de rede em tempo real (Stream)
  Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.map((List<ConnectivityResult> resultados) {
      return _validarResultados(resultados);
    });
  }

  // Regra auxiliar: valida se há pelo menos uma interface de rede ativa e conectada
  bool _validarResultados(List<ConnectivityResult> resultados) {
    if (resultados.isEmpty || resultados.contains(ConnectivityResult.none)) {
      return false;
    }
    return resultados.contains(ConnectivityResult.mobile) || 
           resultados.contains(ConnectivityResult.wifi) ||
           resultados.contains(ConnectivityResult.ethernet);
  }
}