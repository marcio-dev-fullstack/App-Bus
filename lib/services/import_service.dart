import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';

class ImportService {
  static Future<int> importarAlunosCSV() async {
    final dbHelper = DatabaseHelper();
    int contagem = 0;

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true, 
    );

    if (result != null && result.files.first.bytes != null) {
      Uint8List fileBytes = result.files.first.bytes!;
      String csvString;
      try {
        csvString = utf8.decode(fileBytes);
      } catch (_) {
        csvString = latin1.decode(fileBytes);
      }
      
      List<String> linhas = csvString.split(RegExp(r'\r\n|\n|\r'));
      
      for (var linha in linhas) {
        if (linha.trim().isEmpty) continue;
        List<String> colunas = linha.contains(';') ? linha.split(';') : linha.split(',');

        if (colunas.length >= 2) {
          String matricula = colunas[0].replaceAll(RegExp(r'[^\d]'), '').trim();
          String nome = colunas[1].replaceAll('"', '').trim().toUpperCase();

          if (nome == 'NOME' || nome.contains('ALUNO') || nome.isEmpty) continue;

          await dbHelper.insertAluno({
            'nome': nome,
            'matricula': matricula,
            'presenca': 0,
          });
          contagem++;
        }
      }
    }
    return contagem;
  }
}