import 'package:flutter/material.dart';
import 'frequencia_screen.dart';
import 'historico_screen.dart';
import '../services/sync_service.dart';
import '../database/database_helper.dart';
import '../models/checklist_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SyncService _syncService = SyncService();
  int _logsPendentes = 0;
  String _selectedRotaLabel = "Selecione a Rota Rural";
  int? _selectedRotaId;

  // Lista de rotas (Exemplo: No futuro virá do seu banco PostgreSQL/SQLite)
  final List<Map<String, dynamic>> _rotas = [
    {'id': 1, 'nome': 'Rota 01 - Vila Planalto'},
    {'id': 2, 'nome': 'Rota 02 - Distrito Alacid Nunes'},
    {'id': 3, 'nome': 'Rota 03 - Centro / Escolas Estaduais'},
  ];

  @override
  void initState() {
    super.initState();
    _atualizarStatusSincronizacao();
  }

  // Verifica quantos registros (embarques e inspeções) aguardam internet
  Future<void> _atualizarStatusSincronizacao() async {
    final db = await DatabaseHelper().database;
    
    final embarques = await db.rawQuery('SELECT COUNT(*) as total FROM logs_embarque WHERE status_sincronizado = 0');
    final inspecoes = await db.rawQuery('SELECT COUNT(*) as total FROM inspecoes_veiculo WHERE status_sincronizado = 0');
    
    setState(() {
      _logsPendentes = (embarques.first['total'] as int) + (inspecoes.first['total'] as int);
    });
  }

  // Persiste a inspeção de segurança no SQLite para auditoria posterior
  Future<void> _salvarInspecao(ChecklistModel checklist) async {
    final db = await DatabaseHelper().database;
    await db.insert('inspecoes_veiculo', {
      'rota_id': _selectedRotaId,
      'data_hora': DateTime.now().toIso8601String(),
      'itens_check': 'Pneus:${checklist.pneusOk}|Freios:${checklist.freiosOk}|Cintos:${checklist.cintosOk}|Luzes:${checklist.luzesOk}|Extintor:${checklist.extintorOk}|Limpeza:${checklist.limpezaOk}',
      'status_sincronizado': 0,
    });
  }

  // Modal de Checklist obrigatório antes de iniciar a viagem
  void _abrirChecklistSeguranca() {
    if (_selectedRotaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Selecione uma rota antes de iniciar!")),
      );
      return;
    }

    ChecklistModel checklist = ChecklistModel();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: const EdgeInsets.all(25),
              height: MediaQuery.of(context).size.height * 0.8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Inspeção de Segurança", 
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1))),
                  const SizedBox(height: 5),
                  const Text("Verificação obrigatória antes da partida."),
                  const Divider(height: 30),
                  
                  Expanded(
                    child: ListView(
                      children: [
                        _buildCheckItem("Pneus em bom estado?", checklist.pneusOk, (v) => setModalState(() => checklist.pneusOk = v!)),
                        _buildCheckItem("Sistema de freios operacional?", checklist.freiosOk, (v) => setModalState(() => checklist.freiosOk = v!)),
                        _buildCheckItem("Cintos de segurança disponíveis?", checklist.cintosOk, (v) => setModalState(() => checklist.cintosOk = v!)),
                        _buildCheckItem("Faróis e setas funcionando?", checklist.luzesOk, (v) => setModalState(() => checklist.luzesOk = v!)),
                        _buildCheckItem("Extintor de incêndio carregado?", checklist.extintorOk, (v) => setModalState(() => checklist.extintorOk = v!)),
                        _buildCheckItem("Higiene e limpeza interna OK?", checklist.limpezaOk, (v) => setModalState(() => checklist.limpezaOk = v!)),
                      ],
                    ),
                  ),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: checklist.isTudoOk 
                        ? () async {
                            await _salvarInspecao(checklist);
                            if (!mounted) return;
                            Navigator.pop(context);
                            _irParaFrequencia();
                          }
                        : null,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700),
                      child: const Text("CONFIRMAR E INICIAR ROTA", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _irParaFrequencia() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FrequenciaScreen(rotaId: _selectedRotaId!)),
    ).then((_) => _atualizarStatusSincronizacao());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Painel do Monitor"),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: "Histórico de Viagens",
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoricoScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.cloud_sync),
            tooltip: "Sincronizar Dados",
            onPressed: () async {
              await _syncService.checkAndSync();
              _atualizarStatusSincronizacao();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildVeiculoCard(),
            const SizedBox(height: 30),
            
            const Text("Configuração da Viagem", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),

            // Dropdown de Seleção de Rota
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  isExpanded: true,
                  hint: Text(_selectedRotaLabel),
                  items: _rotas.map((rota) {
                    return DropdownMenuItem<int>(
                      value: rota['id'],
                      child: Text(rota['nome']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedRotaId = value;
                      _selectedRotaLabel = _rotas.firstWhere((r) => r['id'] == value)['nome'];
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 25),

            // Botão Principal de Início de Rota
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: _abrirChecklistSeguranca,
                icon: const Icon(Icons.play_circle_fill, size: 30),
                label: const Text("INICIAR EMBARQUE", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D47A1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Alerta de Sincronização Pendente
            if (_logsPendentes > 0) _buildSyncAlert(),
          ],
        ),
      ),
    );
  }

  Widget _buildVeiculoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [const Color(0xFF0D47A1), Colors.blue.shade700]),
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("VEÍCULO OFICIAL", style: TextStyle(color: Colors.white70, fontSize: 12)),
              Icon(Icons.bus_alert, color: Colors.white54),
            ],
          ),
          const SizedBox(height: 5),
          const Text("ÔNIBUS ESCOLAR - SEMEC", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const Divider(color: Colors.white24, height: 25),
          Row(
            children: [
              const CircleAvatar(backgroundColor: Colors.white24, child: Icon(Icons.person, color: Colors.white)),
              const SizedBox(width: 15),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Monitor Responsável", style: TextStyle(color: Colors.white70, fontSize: 12)),
                  Text("Márcio Rodrigues", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSyncAlert() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              "Você possui $_logsPendentes registros pendentes de envio para a SEMEC.",
              style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.brown),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckItem(String titulo, bool valor, Function(bool?) onChanged) {
    return CheckboxListTile(
      title: Text(titulo),
      value: valor,
      onChanged: onChanged,
      activeColor: const Color(0xFF0D47A1),
      controlAffinity: ListTileControlAffinity.leading,
    );
  }
}