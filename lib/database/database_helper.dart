// Dentro do método _onCreate no database_helper.dart
await db.execute('''
  CREATE TABLE inspecoes_veiculo (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    rota_id INTEGER,
    data_hora TEXT,
    itens_check TEXT, -- String formatada com os resultados
    status_sincronizado INTEGER DEFAULT 0
  )
''');