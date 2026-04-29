import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';

class PdfService {
  Future<void> gerarRelatorioDiario(int rotaId, String nomeRota) async {
    final pdf = pw.Document();
    final DateTime agora = DateTime.now();
    final String dataCabecalho = DateFormat('dd/MM/yyyy HH:mm').format(agora);
    
    // Busca registros de hoje no banco local
    final db = await DatabaseHelper().database;
    final List<Map<String, dynamic>> registros = await db.rawQuery('''
      SELECT a.nome, a.matricula, l.data_hora, l.metodo_validacao 
      FROM logs_embarque l
      JOIN alunos a ON l.aluno_id = a.id
      WHERE a.rota_id = ? AND date(l.data_hora) = date('now')
      ORDER BY l.data_hora ASC
    ''', [rotaId]);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Cabeçalho Institucional
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("PREFEITURA DE CONCEIÇÃO DO ARAGUAIA", 
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                    pw.Text("SECRETARIA MUNICIPAL DE EDUCAÇÃO - SEMEC", 
                        style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                    pw.Text("Sistema BusEscolar - Gestão de Transporte", 
                        style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
                pw.Text(dataCabecalho, style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
            pw.Divider(thickness: 1, color: PdfColors.blue900),
            pw.SizedBox(height: 15),

            // Título e Identificação da Rota
            pw.Center(
              child: pw.Text("RELATÓRIO DIÁRIO DE EMBARQUE", 
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
            ),
            pw.SizedBox(height: 10),
            pw.Container(
              padding: const pw.EdgeInsets.all(5),
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              child: pw.Row(children: [
                pw.Text("ROTA ATENDIDA: ", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text(nomeRota),
              ]),
            ),
            pw.SizedBox(height: 20),

            // Tabela de Frequência
            pw.TableHelper.fromTextArray(
              headers: ['ALUNO', 'MATRÍCULA', 'HORA', 'VALIDAÇÃO'],
              data: registros.map((r) => [
                r['nome'],
                r['matricula'],
                DateFormat('HH:mm').format(DateTime.parse(r['data_hora'])),
                r['metodo_validacao'].toString().toUpperCase(),
              ]).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue900),
              cellHeight: 22,
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.center,
                2: pw.Alignment.center,
                3: pw.Alignment.center,
              },
            ),

            pw.Spacer(),

            // Rodapé com Assinatura
            pw.Column(
              children: [
                pw.Container(width: 250, border: const pw.Border(top: pw.BorderSide())),
                pw.Text("Assinatura do Monitor Responsável", style: const pw.TextStyle(fontSize: 10)),
                pw.Text("Marcio Rodrigues de Oliveira", 
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
              ],
            ),
          ];
        },
      ),
    );

    // Abre a interface de visualização/impressão/compartilhamento
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Relatorio_${nomeRota.replaceAll(' ', '_')}_$dataCabecalho.pdf',
    );
  }
}