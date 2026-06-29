/// AUTOR:Arquiteto de Solução e Desenvolvedor Líder
/// Márcio Rodrigues de Oliveira
/// cda.marcio@gmail.com
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:front_end/features/auth/controllers/auth_controller.dart';
import 'package:front_end/features/trip/repositories/trip_repository_local.dart';
import 'package:front_end/locator.dart';

/// Serviço responsável por sincronizar os dados locais com a API de backend.
class SyncService {
  final TripRepositoryLocal _tripRepository = locator<TripRepositoryLocal>();
  final AuthController _authController = locator<AuthController>();
  final String _baseUrl =
      dotenv.env['API_BASE_URL'] ?? 'https://localhost:7123';

  /// Tenta sincronizar todas as viagens pendentes com o servidor.
  Future<void> sincronizarViagens() async {
    // 1. Verifica se o usuário está autenticado.
    final token = _authController.token;
    if (token == null) {
      print("SyncService: Usuário não autenticado. Sincronização cancelada.");
      return;
    }

    // 2. Busca todas as viagens pendentes com seus dados completos.
    final viagensPendentes = await _tripRepository.obterViagensPendentes();

    if (viagensPendentes.isEmpty) {
      print("SyncService: Nenhuma viagem pendente para sincronizar.");
      return;
    }

    print(
      "SyncService: ${viagensPendentes.length} viagem(ns) para sincronizar.",
    );

    // 3. Itera sobre cada viagem e a envia para a API.
    for (final viagem in viagensPendentes) {
      try {
        final response = await http.post(
          Uri.parse('$_baseUrl/api/viagens/sincronizar'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(viagem),
        );

        if (response.statusCode == 200) {
          // 4. Se a sincronização for bem-sucedida, marca a viagem como sincronizada localmente.
          await _tripRepository.marcarViagemComoSincronizada(viagem['id']);
          print(
            "SyncService: Viagem ID ${viagem['id']} sincronizada com sucesso.",
          );
        } else {
          print(
            "SyncService: Falha ao sincronizar viagem ID ${viagem['id']}. Status: ${response.statusCode}, Body: ${response.body}",
          );
        }
      } catch (e) {
        print(
          "SyncService: Erro de rede ao sincronizar viagem ID ${viagem['id']}: $e",
        );
      }
    }
  }
}
