import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/rota_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final rotaProvider = Provider.of<RotaProvider>(context);
    
    int totalPassageiros = rotaProvider.rotas.fold(0, (sum, item) => sum + item.passageirosAtuais);
    int totalRotas = rotaProvider.rotas.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard - App Bus'),
        centerTitle: true,
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Define quantas colunas usar baseado na largura da janela do Windows
          int crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Olá, Bem-vindo de volta!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Aqui está o resumo do sistema de transporte hoje:',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 24),

                // Grid responsivo e seguro contra estouro de memória/layout
                GridView.count(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  shrinkWrap: true,
                  childAspectRatio: crossAxisCount == 4 ? 1.3 : 1.1,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildMenuCard(
                      icon: Icons.directions_bus,
                      title: 'Ônibus Ativos',
                      value: '$totalRotas',
                      color: Colors.blue,
                    ),
                    _buildMenuCard(
                      icon: Icons.map,
                      title: 'Rotas Ativas',
                      value: '$totalRotas',
                      color: Colors.green,
                    ),
                    _buildMenuCard(
                      icon: Icons.people,
                      title: 'Passageiros Total',
                      value: '$totalPassageiros',
                      color: Colors.orange,
                    ),
                    _buildMenuCard(
                      icon: Icons.warning_amber_rounded,
                      title: 'Alertas',
                      value: '0',
                      color: Colors.red,
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                Text(
                  'Status das Linhas em Tempo Real',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
                const SizedBox(height: 12),

                // Lista de rotas dinâmica
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: rotaProvider.rotas.length,
                  itemBuilder: (context, index) {
                    final rota = rotaProvider.rotas[index];
                    
                    Color statusColor = Colors.green;
                    if (rota.status == 'Atrasado') statusColor = Colors.red;
                    if (rota.status == 'Em Viagem') statusColor = Colors.orange;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      elevation: 1,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: statusColor.withOpacity(0.1),
                          child: Icon(Icons.directions_bus, color: statusColor),
                        ),
                        title: Text(
                          'Linha ${rota.numeroLinha} - ${rota.nomeLinha}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text('Partida: ${rota.horarioPartida}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                rota.status,
                                style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              '${rota.passageirosAtuais} pax',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color, size: 26),
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}