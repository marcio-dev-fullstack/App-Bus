import 'package:flutter/foundation.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:path/path.dart';

class DbHelper {
  static final DbHelper instance = DbHelper._init();
  static Database? _database;

  DbHelper._init();

  // Chave de criptografia AES-256 (Em produção, deve vir de um ambiente seguro/KeyStore)
  final String _dbSecretKey = "DiretoriaTI_SEMEC_2026_SecureKey#";

  Future<Database> get database async {
    if (_database != null) return _database!;
    
    if (kIsWeb) {
      throw UnsupportedError("SQLite com SQLCipher não roda diretamente no navegador Web.");
    }

    _database = await _initDB('bus_escolar_secure.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    // openDatabase do sqflite_sqlcipher exige o parâmetro password para encriptar o disco
    return await openDatabase(
      path, 
      version: 1, 
      password: _dbSecretKey,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // Tabela de Alunos (Cache Local)
    await db.execute('''
      CREATE TABLE alunos (
        id TEXT PRIMARY KEY,
        nome TEXT NOT NULL,
        matricula TEXT NOT NULL,
        embedding_facial TEXT
      )
    ''');

    // Tabela de Logs de Embarque (Fila Offline)
    await db.execute('''
      CREATE TABLE logs_embarque (
        id TEXT PRIMARY KEY,
        aluno_id TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        metodo_validacao TEXT NOT NULL,
        sincronizado INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> limparBanco() async {
    if (kIsWeb) return;
    final db = await database;
    await db.delete('alunos');
    await db.delete('logs_embarque');
  }
}