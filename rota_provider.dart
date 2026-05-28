// Dentro da classe RotaProvider em lib/providers/rota_provider.dart:

// Guarda temporariamente os IDs dos alunos que já embarcaram nesta viagem
final Set<String> _alunosEmbarcadosNestaViagem = {};

Set<String> get alunosEmbarcadosNestaViagem => _alunosEmbarcadosNestaViagem;

/// Limpa a lista ao iniciar uma nova rota/turno
void iniciarNovaViagem() {
  _alunosEmbarcadosNestaViagem.clear();
  notifyListeners();
}