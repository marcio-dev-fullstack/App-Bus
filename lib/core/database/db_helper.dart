import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DbHelper {
  static const _databaseName = "app_bus_local.db";
  static const _databaseVersion = 1;

  static const tableLogs = 'logs_embarque_offline';

  // Singleton para garantir uma única instância do banco aberta
  DbHelper._privateConstructor();
  static final DbHelper instance = DbHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  // Cria a tabela espelho da nossa retaguarda
  Future _onCreate(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $tableLogs (
            id TEXT PRIMARY KEY,
            aluno_id TEXT NOT NULL,
            veiculo_id TEXT NOT NULL,
            rota_id TEXT NOT NULL,
            timestamp_dispositivo TEXT NOT NULL,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL
          )
          ''');
  }
}