import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/rota_provider.dart';

class EmbarqueScreen extends StatelessWidget {
  const EmbarqueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final rotaProvider = Provider.of<RotaProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Controle de Embarque'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: rotaProvider.rotas.length,
        itemBuilder: (context, index) {
          final rota = rotaProvider.rotas[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Linha ${rota.numeroLinha}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(rota.nomeLinha, style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 8),
                      Text('Passageiros a bordo: ${rota.passageirosAtuais}',
                          style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      rotaProvider.registrarEmbarque(rota.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Embarque registrado na Linha ${rota.numeroLinha}!'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Embarcar'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}