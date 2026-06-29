/// AUTOR:Arquiteto de Solução e Desenvolvedor Líder
/// Márcio Rodrigues de Oliveira
/// cda.marcio@gmail.com

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Um serviço para encapsular o acesso ao armazenamento seguro do dispositivo.
/// Utiliza o Keychain (iOS) e Keystore (Android).
class SecureStorageService {
  final _storage = const FlutterSecureStorage();
  static const _tokenKey = 'auth_token';

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }
}
