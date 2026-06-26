/// ## Arquiteto de Solução e Desenvolvedor Líder
///
/// **Márcio Rodrigues de Oliveira**
///
/// * Desenvolvedor Full Stack
/// * cda.marcio@gmail.com

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// Gerencia a conexão e a criação do banco de dados SQLite local.
/// Utiliza o padrão Singleton para garantir uma única instância em todo o app.
class DatabaseService {
  // Instância única (Singleton)
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  /// Retorna a instância do banco de dados, inicializando-a se necessário.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  /// Inicializa o banco de dados, definindo seu caminho e criando as tabelas.
  Future<Database> _initDB() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'app_bus.db');

    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  /// Método chamado na primeira vez que o banco de dados é criado.
  /// Define a estrutura (schema) do banco.
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE rotas (
        id INTEGER PRIMARY KEY,
        nome TEXT NOT NULL,
        descricao TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE alunos (
        id INTEGER PRIMARY KEY,
        nome TEXT NOT NULL,
        matricula TEXT UNIQUE NOT NULL,
        vetor_facial BLOB,
        id_rota INTEGER,
        FOREIGN KEY (id_rota) REFERENCES rotas (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE viagens (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        data_inicio TEXT NOT NULL,
        data_fim TEXT,
        id_rota INTEGER NOT NULL,
        sincronizado INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE embarques (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        id_viagem INTEGER NOT NULL,
        id_aluno INTEGER NOT NULL,
        data_hora TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        tipo TEXT NOT NULL, -- 'embarque' ou 'desembarque'
        FOREIGN KEY (id_viagem) REFERENCES viagens (id),
        FOREIGN KEY (id_aluno) REFERENCES alunos (id)
      )
    ''');
  }
}
