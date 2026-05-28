import 'package:flutter/material.dart';

// Modelo de dados para as Rotas
class RotaOnibus {
  final String id;
  final String numeroLinha;
  final String nomeLinha;
  final String horarioPartida;
  final int passageirosAtuais;
  final String status;

  RotaOnibus({
    required this.id,
    required this.numeroLinha,
    required this.nomeLinha,
    required this.horarioPartida,
    required this.passageirosAtuais,
    required this.status,
  });
}

// NOVO: Modelo de dados para o Motorista
class Motorista {
  final String nome;
  final String cnh;
  final String linhaAtribuida;

  Motorista({
    required this.nome,
    required this.cnh,
    required this.linhaAtribuida,
  });
}

class RotaProvider with ChangeNotifier {
  // Lista de rotas
  final List<RotaOnibus> _rotas = [
    RotaOnibus(id: '1', numeroLinha: '105', nomeLinha: 'Centro / Terminal Central', horarioPartida: '16:30', passageirosAtuais: 45, status: 'No Horário'),
    RotaOnibus(id: '2', numeroLinha: '210', nomeLinha: 'Bairro Novo / Shopping', horarioPartida: '16:45', passageirosAtuais: 22, status: 'Atrasado'),
    RotaOnibus(id: '3', numeroLinha: '302', nomeLinha: 'Universidade / Estação Norte', horarioPartida: '17:00', passageirosAtuais: 68, status: 'Em Viagem'),
  ];

  // NOVO: Lista de motoristas cadastrados (começa com 2 de exemplo)
  final List<Motorista> _motoristas = [
    Motorista(nome: 'Carlos Silva', cnh: '123456789-0', linhaAtribuida: '105'),
    Motorista(nome: 'Ana Souza', cnh: '987654321-1', linhaAtribuida: '210'),
  ];

  List<RotaOnibus> get rotas => [..._rotas];
  List<Motorista> get motoristas => [..._motoristas]; // Getter para os motoristas

  // Função de embarque
  void registrarEmbarque(String idRota) {
    final index = _rotas.indexWhere((r) => r.id == idRota);
    if (index >= 0) {
      _rotas[index] = RotaOnibus(
        id: _rotas[index].id,
        numeroLinha: _rotas[index].numeroLinha,
        nomeLinha: _rotas[index].nomeLinha,
        horarioPartida: _rotas[index].horarioPartida,
        passageirosAtuais: _rotas[index].passageirosAtuais + 1,
        status: _rotas[index].status,
      );
      notifyListeners();
    }
  }

  // NOVO: Função para cadastrar um novo motorista
  void cadastrarMotorista(String nome, String cnh, String linha) {
    _motoristas.add(Motorista(nome: nome, cnh: cnh, linhaAtribuida: linha));
    notifyListeners(); // Atualiza a tela na hora!
  }
}