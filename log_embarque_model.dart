import 'dart:convert';

class LogEmbarqueModel {
  final String alunoId;
  final String veiculoId;
  final String rotaId;
  final DateTime timestampDispositivo;
  final double latitude;
  final double longitude;
  final bool sincronizacaoOffline;

  LogEmbarqueModel({
    required this.alunoId,
    required this.veiculoId,
    required this.rotaId,
    required this.timestampDispositivo,
    required this.latitude,
    required this.longitude,
    this.sincronizacaoOffline = true,
  });

  // Converte o objeto para o mapa (JSON) esperado pela API
  Map<String, dynamic> toJson() {
    return {
      'aluno_id': alunoId,
      'veiculo_id': veiculoId,
      'rota_id': rotaId,
      'timestamp_dispositivo': timestampDispositivo.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'sincronizacao_offline': sincronizacaoOffline,
    };
  }
}