import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../services/pdf_service.dart';

class HistoricoScreen extends StatefulWidget {
  const HistoricoScreen({super.key});

  @override
  State<HistoricoScreen> createState() => _HistoricoScreenState();
}

class _HistoricoScreenState extends State<HistoricoScreen> {
  final PdfService _pdfService = PdfService();
  List<Map<String, dynamic>> _historicoViagens = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarHistorico();
  }

  Future<void> _carregarHistorico() async {
    setState(() => _isLoading = true);
    final db = await DatabaseHelper().database;

    // Busca as últimas rotas que tiveram registros de embarque
    // Agrupamos por dia e rota para mostrar como uma "viagem concluída"
    final List<Map<String, dynamic>> resultados = await db.rawQuery('''
      SELECT 
        r.id as rota_id, 
        r.nome as rota_nome, 
        date(l.data_hora) as data_viagem,
        COUNT(l.id) as total_alunos
      FROM logs_embarque l
      JOIN alunos a ON l.aluno_id = a.id
      JOIN rotas r ON a.rota_id = r.id
      GROUP BY date(l.data_hora), r.id
      ORDER BY l.data_hora DESC
      LIMIT 20
    ''');

    setState(() {
      _historicoViagens = resultados;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Histórico de Rotas"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _historicoViagens.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: _historicoViagens.length,
                  itemBuilder: (context, index) {
                    final viagem = _historicoViagens[index];
                    final dataStr = DateFormat('dd/MM/yyyy').format(DateTime.parse(viagem['data_viagem']));

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.bottom(15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(15),
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade100,
                          child: const Icon(Icons.history_edu, color: Color(0xFF0D47A1)),
                        ),
                        title: Text(
                          viagem['rota_nome'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 5),
                            Text("Data: $dataStr"),
                            Text("Alunos transportados: ${viagem['total_alunos']}"),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
                          onPressed: () {
                            _pdfService.gerarRelatorioDiario(
                              viagem['rota_id'], 
                              viagem['rota_nome']
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 15),
          const Text("Nenhuma viagem registrada ainda.", 
            style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }
}