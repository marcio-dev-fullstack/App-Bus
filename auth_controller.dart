/// ## Arquiteto de Solução e Desenvolvedor Líder
///
/// **Márcio Rodrigues de Oliveira**
///
/// * Desenvolvedor Full Stack
/// * cda.marcio@gmail.com

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:front_end/features/auth/services/auth_service.dart';
import 'package:front_end/locator.dart';

/// Controller responsável por gerenciar o estado de autenticação
/// e o armazenamento seguro do token JWT.
class AuthController extends ChangeNotifier {
  // Injeta o serviço de autenticação.
  final AuthService _authService = locator<AuthService>();
  // Instância do flutter_secure_storage para armazenamento seguro.
  final _storage = const FlutterSecureStorage();
  final String _accessTokenKey = 'access_token';
  final String _refreshTokenKey = 'refresh_token';

  String? _accessToken;
  String? _refreshToken;
  bool _isAuthenticated = false;
  bool _isLoading = true;

  // Getters públicos para a UI reagir.
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get token => _accessToken; // O getter principal retorna o access token

  /// Tenta fazer o login do usuário.
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    try {
      // Chama o serviço para obter o token da API.
      final tokens = await _authService.login(email, password);

      if (tokens != null && tokens['accessToken'] != null && tokens['refreshToken'] != null) {
        // 1. Armazena os tokens de forma segura.
        await _storage.write(key: _accessTokenKey, value: tokens['accessToken']);
        await _storage.write(key: _refreshTokenKey, value: tokens['refreshToken']);
        _accessToken = tokens['accessToken'];
        _refreshToken = tokens['refreshToken'];
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

  /// Tenta registrar um novo usuário.
  Future<bool> register(String email, String password) async {
    _setLoading(true);
    try {
      final success = await _authService.register(email, password);
      _setLoading(false);
      return success;
    } catch (e) {
      print("Erro no registro: $e");
      _setLoading(false);
      return false;
    }
  }

  /// Tenta carregar um token do armazenamento seguro para auto-login.
  /// Chamado na inicialização do app.
  Future<void> tryAutoLogin() async {
    _setLoading(true);

    // Tenta ler o token do armazenamento seguro.
    final storedAccessToken = await _storage.read(key: _accessTokenKey);
    final storedRefreshToken = await _storage.read(key: _refreshTokenKey);

    if (storedAccessToken != null && storedRefreshToken != null) {
      // Valida o token com a API antes de autenticar o usuário.
      final isTokenValid = await _authService.validateToken(storedAccessToken);

      if (isTokenValid) {
        _accessToken = storedAccessToken;
        _refreshToken = storedRefreshToken;
        _isAuthenticated = true;
      } else {
        // Se o token for inválido, limpa o armazenamento local.
        await logout();
      }
    }

    _setLoading(false);
    notifyListeners();
  }

  /// Realiza o logout do usuário.
  Future<void> logout() async {
    _accessToken = null;
    _refreshToken = null;
    _isAuthenticated = false;
    
    // Deleta os tokens do armazenamento seguro.
    // O ideal seria também chamar o endpoint /revoke da API aqui.
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    
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