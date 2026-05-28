import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/rota_provider.dart';

class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key});

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _cnhController = TextEditingController();
  String _linhaSelecionada = '105'; // Linha padrão inicial

  @override
  void dispose() {
    _nomeController.dispose();
    _cnhController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rotaProvider = Provider.of<RotaProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastro de Funcionários'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Lado Esquerdo: Formulário de Cadastro
            Expanded(
              flex: 2,
              child: Card(
                elevation: 3,
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Novo Motorista',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _nomeController,
                        decoration: const InputDecoration(
                          labelText: 'Nome Completo',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) => value == null || value.isEmpty ? 'Insira o nome' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _cnhController,
                        decoration: const InputDecoration(
                          labelText: 'CNH (Carteira de Habilitação)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.badge),
                        ),
                        validator: (value) => value == null || value.isEmpty ? 'Insira a CNH' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _linhaSelecionada,
                        decoration: const InputDecoration(
                          labelText: 'Atribuir Linha',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.directions_bus),
                        ),
                        items: rotaProvider.rotas.map((rota) {
                          return DropdownMenuItem(
                            value: rota.numeroLinha,
                            child: Text('Linha ${rota.numeroLinha}'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _linhaSelecionada = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade800,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              rotaProvider.cadastrarMotorista(
                                _nomeController.text,
                                _cnhController.text,
                                _linhaSelecionada,
                              );
                              
                              // Limpa os campos
                              _nomeController.clear();
                              _cnhController.clear();
                              
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Motorista cadastrado com sucesso!')),
                              );
                            }
                          },
                          child: const Text('Salvar Cadastro', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 24),
            
            // Lado Direito: Lista de Motoristas Atuais
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Equipe de Motoristas Ativos',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: rotaProvider.motoristas.length,
                      itemBuilder: (context, index) {
                        final motorista = rotaProvider.motoristas[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.drive_eta),
                            ),
                            title: Text(motorista.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('CNH: ${motorista.cnh}'),
                            trailing: Chip(
                              backgroundColor: Colors.blue.shade50,
                              label: Text('Linha ${motorista.linhaAtribuida}'),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}