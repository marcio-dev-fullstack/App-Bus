/// ## Arquiteto de Solução e Desenvolvedor Líder
///
/// **Márcio Rodrigues de Oliveira**
///
/// * Desenvolvedor Full Stack
/// * cda.marcio@gmail.com

/// Serviço para encapsular as chamadas de API relacionadas à sincronização.
class SyncApiService {
  /// Busca os dados iniciais necessários para a operação offline.
  /// Em um cenário real, faria uma chamada GET para um endpoint como /api/sync/initial-data
  Future<Map<String, dynamic>> fetchInitialData() async {
    // Simula um atraso de rede.
    await Future.delayed(const Duration(seconds: 2));
    // Retorna dados de exemplo.
    return {
      'alunos': [
        {
          'id': 1,
          'nome': 'João da Silva',
          'matricula': '2026001',
          'id_rota': 1,
        },
        {
          'id': 2,
          'nome': 'Maria Oliveira',
          'matricula': '2026002',
          'id_rota': 1,
        },
      ],
      'rotas': [
        {
          'id': 1,
          'nome': 'Rota 01 - Centro',
          'descricao': 'Passa pelo centro da cidade',
        },
      ],
    };
  }

  /// Envia os dados de uma viagem concluída para o servidor.
  Future<void> sendCompletedTrip(Map<String, dynamic> tripData) async {
    // Simula uma chamada POST para /api/viagens/sincronizar
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
