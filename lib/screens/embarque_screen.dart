import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/rota_provider.dart';

class EmbarqueScreen extends StatefulWidget {
  const EmbarqueScreen({super.key});

  @override
  State<EmbarqueScreen> createState() => _EmbarqueScreenState();
}

class _EmbarqueScreenState extends State<EmbarqueScreen> {
  // IDs de teste simulando a sessão ativa do veículo e rota da SEMEC
  final String veiculoId = "3fbc53b2-6028-4e8b-967a-18b3263dfbf8";
  final String rotaId = "8a7c2a11-b45a-4933-91ee-0bda7e312f45";

  // Lista simulada de estudantes vinculados a esta rota específica
  final List<Map<String, String>> alunosDaRota = [
    {"id": "a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d", "nome": "João Silva"},
    {"id": "b2c3d4e5-f6a7-8b9c-0d1e-2f3a4b5c6d7e", "nome": "Maria Santos"},
    {"id": "c3d4e5f6-a7b8-9c0d-1e2f-3a4b5c6d7e8f", "nome": "Pedro Oliveira"},
    {"id": "d4e5f6a7-b8c9-0d1e-2f3a-4b5c6d7e8f9a", "nome": "Ana Costa"},
  ];

  @override
  Widget build(BuildContext context) {
    // Escuta ativamente as mudanças de estado vindas do RotaProvider
    final rotaProvider = Provider.of<RotaProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('App-Bus — Embarque Escolar'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        actions: [
          // Botão manual de sincronização (Desabilitado se já estiver sincronizando)
          IconButton(
            icon: const Icon(Icons.sync_all),
            tooltip: 'Sincronizar Lote Manualmente',
            onPressed: rotaProvider.estaSincronizando 
                ? null 
                : () => rotaProvider.executarSincronizacao(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Painel Superior Interativo: Monitoramento de Rede e GPS em Tempo Real
            Card(
              elevation: 2,
              color: Colors.grey.shade100,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.around,
                  children: [
                    // Status de Conexão (Gerenciado de forma automática pelo connectivity_plus no Provider)
                    Row(
                      children: [
                        Icon(
                          rotaProvider.temInternet ? Icons.cloud_done : Icons.cloud_off, 
                          color: rotaProvider.temInternet ? Colors.green.shade600 : Colors.orange.shade700,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          rotaProvider.temInternet 
                              ? "Conectado (Tempo Real)" 
                              : "Modo Offline (Salva Local)",
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                      ],
                    ),
                    // Indicador de busca de satélites GPS do aparelho móvel
                    if (rotaProvider.capturandoGps)
                      Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5, 
                              color: Colors.blue.shade800
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            "Buscando GPS...",
                            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            const Text(
              'Painel de Chamada dos Alunos:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Grid adaptado para telas mobile e tablets (Botões amplos para evitar erros em movimento)
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, 
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.3, 
                ),
                itemCount: alunosDaRota.length,
                itemBuilder: (context, index) {
                  final aluno = alunosDaRota[index];
                  
                  // Regra de Negócio Visual: Verifica no Provider se este ID já bateu ponto nesta viagem
                  final bool jaEmbarcou = rotaProvider.alunosEmbarcadosNestaViagem.contains(aluno["id"]);

                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      // Altera dinamicamente as cores se o aluno já estiver dentro do veículo
                      backgroundColor: jaEmbarcou ? Colors.green.shade50 : Colors.blue.shade50,
                      foregroundColor: jaEmbarcou ? Colors.green.shade900 : Colors.blue.shade900,
                      side: BorderSide(
                        color: jaEmbarcou ? Colors.green.shade300 : Colors.blue.shade300, 
                        width: 1.8
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: jaEmbarcou ? 0 : 2,
                    ),
                    // Bloqueia clique se o GPS estiver processando OU se o aluno já embarcou
                    onPressed: (rotaProvider.capturandoGps || jaEmbarcou)
                        ? null 
                        : () async {
                            await rotaProvider.registrarEmbarqueComGps(
                              alunoId: aluno["id"]!,
                              veiculoId: veiculoId,
                              rotaId: rotaId,
                            );

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Embarque registrado: ${aluno["nome"]}'),
                                  duration: const Duration(milliseconds: 900),
                                  backgroundColor: Colors.green.shade700,
                                ),
                              );
                            }
                          },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (jaEmbarcou) ...[
                          const Icon(Icons.check_circle, size: 22, color: Colors.green),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(
                            aluno["nome"]!,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}