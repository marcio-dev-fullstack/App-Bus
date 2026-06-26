/// ## Arquiteto de Solução e Desenvolvedor Líder
///
/// **Márcio Rodrigues de Oliveira**
///
/// * Desenvolvedor Full Stack
/// * cda.marcio@gmail.com

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Controller responsável por gerenciar o estado de autenticação
/// e o armazenamento seguro do token JWT.
class AuthController extends ChangeNotifier {
  // Instância do flutter_secure_storage para armazenamento seguro.
  final _storage = const FlutterSecureStorage();
  final String _tokenKey = 'jwt_token'; // Chave para armazenar o token.

  String? _token;
  bool _isAuthenticated = false;
  bool _isLoading = true;

  // Getters públicos para a UI reagir.
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get token => _token;

  /// Tenta fazer o login do usuário.
  /// Em um app real, isso chamaria um `AuthService` que se comunica com a API.
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    try {
      // --- LÓGICA DE CHAMADA À API ---
      // final apiToken = await _authService.login(email, password);
      // Para este exemplo, vamos simular um token recebido da API.
      final apiToken = "simulated_jwt_token_from_api";

      if (apiToken != null) {
        // 1. Armazena o token de forma segura.
        await _storage.write(key: _tokenKey, value: apiToken);
        _token = apiToken;
        _isAuthenticated = true;
        
        _setLoading(false);
        notifyListeners();
        return true;
      }
    } catch (e) {
      // Lidar com erros de login (ex: credenciais inválidas, falha de rede)
      print("Erro no login: $e");
    }

    _setLoading(false);
    return false;
  }

  /// Tenta carregar um token do armazenamento seguro para auto-login.
  /// Chamado na inicialização do app.
  Future<void> tryAutoLogin() async {
    _setLoading(true);

    // Tenta ler o token do armazenamento seguro.
    final storedToken = await _storage.read(key: _tokenKey);

    if (storedToken != null) {
      // TODO: Idealmente, validar o token com a API antes de autenticar.
      _token = storedToken;
      _isAuthenticated = true;
    }

    _setLoading(false);
    notifyListeners();
  }

  /// Realiza o logout do usuário.
  Future<void> logout() async {
    _token = null;
    _isAuthenticated = false;
    
    // Deleta o token do armazenamento seguro.
    await _storage.delete(key: _tokenKey);
    
    notifyListeners();
  }

  /// Método privado para gerenciar o estado de carregamento.
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }
}

```

### 2. How to Use the Token in API Calls

To use the stored token, you'll need to add it to the `Authorization` header of your API requests. The best practice is to create a centralized HTTP client or service that automatically includes the token.

Here is a conceptual example of how you might create a service to make authenticated API calls:

**`core/services/api_service.dart` (Example)**
```dart
import 'package:http/http.dart' as http;
import 'package:front_end/locator.dart';
import 'package:front_end/features/auth/controllers/auth_controller.dart';

class ApiService {
  final String _baseUrl = "https://your-api-url.com/api";
  final AuthController _authController = locator<AuthController>();

  Future<http.Response> post(String endpoint, {Object? body}) async {
    final token = _authController.token;

    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    return http.post(
      Uri.parse('$_baseUrl/$endpoint'),
      headers: headers,
      body: body,
    );
  }

  // Implement other methods like get, put, delete...
}
```

By implementing this `AuthController`, your application will now securely manage the user's session, persisting the login state across app restarts and providing the necessary token for authenticated API communication.

<!--
[PROMPT_SUGGESTION]How can I create the `GET /api/rotas/{idVeiculo}/alunos` endpoint for the app to download initial data?[/PROMPT_SUGGESTION]
[PROMPT_SUGGESTION]How can I handle token expiration and automatically refresh it?[/PROMPT_SUGGESTION]
-->