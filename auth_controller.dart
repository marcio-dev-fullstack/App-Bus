/// ## Arquiteto de Solução e Desenvolvedor Líder
///
/// **Márcio Rodrigues de Oliveira**
///
/// * Desenvolvedor Full Stack
/// * cda.marcio@gmail.com

import 'package:flutter/foundation.dart';
import 'package:front_end/api/auth_service.dart';
import 'package:front_end/core/services/secure_storage_service.dart';
import 'package:front_end/locator.dart';

class AuthController with ChangeNotifier {
  final AuthService _authService = locator<AuthService>();
  final SecureStorageService _storageService = locator<SecureStorageService>();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _authToken;
  bool get isAuthenticated => _authToken != null;

  Future<void> login(String email, String password) async {
    _setLoading(true);
    try {
      final token = await _authService.login(email, password);
      _authToken = token;
      await _storageService.saveToken(token);
      notifyListeners();
    } catch (e) {
      // Relança a exceção para que a UI (LoginScreen) possa tratá-la.
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> logout() async {
    _setLoading(true);
    _authToken = null;
    await _storageService.deleteToken();
    _setLoading(false);
    notifyListeners(); // Notifica a UI que o usuário não está mais autenticado.
  }

  /// Tenta carregar um token do armazenamento seguro para auto-login.
  /// Deve ser chamado na inicialização do aplicativo.
  Future<void> tryAutoLogin() async {
    _setLoading(true);
    _authToken = await _storageService.getToken();
    _setLoading(false);
    notifyListeners();
  }
}
