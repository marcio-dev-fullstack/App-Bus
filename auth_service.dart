/// AUTOR:Arquiteto de Solução e Desenvolvedor Líder
/// Márcio Rodrigues de Oliveira
/// cda.marcio@gmail.com

import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Serviço responsável pela comunicação com os endpoints de autenticação da API.
class AuthService {
  final String _baseUrl =
      dotenv.env['API_BASE_URL'] ?? 'https://localhost:7123';

  /// Envia as credenciais para a API e retorna o token JWT em caso de sucesso.
  Future<Map<String, dynamic>?> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data as Map<String, dynamic>;
    } else {
      // Lança uma exceção para ser tratada pelo controller.
      throw Exception('Falha no login: ${response.body}');
    }
  }

  /// Envia os dados de um novo usuário para registro na API.
  Future<bool> register(String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception('Falha no registro: ${response.body}');
    }
  }

  /// Valida um token existente com a API.
  Future<bool> validateToken(String token) async {
    // TODO: Implementar a chamada ao endpoint GET /api/auth/validate
    // Por enquanto, simulamos uma validação bem-sucedida.
    await Future.delayed(const Duration(milliseconds: 300));
    return true;
  }
}
