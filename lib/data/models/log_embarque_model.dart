class LogEmbarque {
  final String id;
  final String alunoId;
  final String timestamp;
  final double latitude;
  final double longitude;
  final String metodoValidacao; // "BIOMETRIA" ou "MANUAL"
  final int sincronizado;

  LogEmbarque({
    required this.id,
    required this.alunoId,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.metodoValidacao,
    this.sincronizado = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'aluno_id': alunoId,
      'timestamp': timestamp,
      'latitude': latitude,
      'longitude': longitude,
      'metodo_validacao': metodoValidacao,
      'sincronizado': sincronizado,
    };
  }
}
