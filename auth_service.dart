/// ## Arquiteto de Solução e Desenvolvedor Líder
///
/// **Márcio Rodrigues de Oliveira**
///
/// * Desenvolvedor Full Stack
/// * cda.marcio@gmail.com

import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  // TODO: Mover a URL base para um arquivo de configuração.
  final String _baseUrl = "https://sua-api.com/api";

  /// Autentica o usuário e retorna um token JWT em caso de sucesso.
  Future<String> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // Assumindo que a API retorna um JSON com uma chave 'token'.
      return data['token'];
    } else {
      throw Exception('Falha ao realizar login. Verifique suas credenciais.');
    }
  }
}
