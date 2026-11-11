import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'queue_model.dart';

pw.Widget _table(List<List<String>> rows) {
  return pw.Table(
    border: pw.TableBorder.all(color: PdfColors.grey500, width: 0.5),
    children: [
      for (var i = 0; i < rows.length; i++)
        pw.TableRow(
          decoration: i == 0 ? const pw.BoxDecoration(color: PdfColors.green100) : null,
          children: [
            for (final c in rows[i])
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text(c,
                    style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: i == 0 ? pw.FontWeight.bold : pw.FontWeight.normal)),
              ),
          ],
        ),
    ],
  );
}

/// Genera el informe PDF. Solo usa caracteres Latin-1 (fuente estandar del PDF).
Future<Uint8List> buildReport(QueueInputData d, QueueResult r) async {
  final doc = pw.Document();
  final now = DateTime.now();
  final date =
      '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

  String interpretation() {
    if (!r.stable) {
      return 'El sistema es INESTABLE (rho = ${fmt(r.rho, 3)} >= 1): la fila crece sin limite. '
          'Se requieren mas servidores o reducir el tiempo de servicio.';
    }
    var t = 'Cada servidor esta ocupado en promedio el ${fmt(r.rho * 100, 1)} % del tiempo. '
        'La probabilidad de que un usuario tenga que esperar es ${fmt(r.pw! * 100, 1)} %, '
        'con una espera media en fila de ${fmt(r.wqSec!, 1)} s y un tiempo total en el '
        'sistema de ${fmt(r.wSec!, 1)} s.';
    if (d.cvService != null) {
      t += ' Con la correccion de Allen-Cunneen (CV del servicio = ${fmt(d.cvService!, 2)}), '
          'Wq seria aproximadamente ${fmt(QueueModel.correctedWq(r.wqSec!, d.cvService!), 1)} s.';
    }
    return t;
  }

  final resultRows = <List<String>>[
    ['Parametro', 'Valor'],
    ['a = lambda / mu', fmt(r.a, 4)],
    ['rho (utilizacion)', '${fmt(r.rho, 4)} (${fmt(r.rho * 100, 1)} %)'],
    if (r.stable) ...[
      ['P0', fmt(r.p0!, 4)],
      ['Pw (prob. de esperar)', fmt(r.pw!, 4)],
      ['Lq (personas en fila)', fmt(r.lq!, 4)],
      ['Wq (espera en fila)', '${fmt(r.wqSec!, 2)} s'],
      ['W (tiempo en el sistema)', '${fmt(r.wSec!, 2)} s'],
      ['L (personas en el sistema)', fmt(r.l!, 4)],
    ] else
      ['Estado', 'Inestable (rho >= 1)'],
  ];

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (ctx) => [
        pw.Header(
            level: 0,
            child: pw.Text('Informe de teoria de colas ${d.modelLabel}',
                style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold))),
        pw.Text('Sistema: ${d.station.isEmpty ? "Taquillas de recarga" : d.station}'),
        pw.Text('Fecha: $date'),
        pw.SizedBox(height: 10),
        pw.Header(level: 1, text: '1. Datos de entrada'),
        _table([
          ['Dato', 'Valor'],
          ['Modelo', d.modelLabel],
          ['Servidores (s)', '${r.servers}'],
          ['Tiempo medio entre llegadas',
              '${fmt(d.meanArrivalSec)} s${d.nArrivals != null ? " (n = ${d.nArrivals})" : ""}'],
          ['Tiempo medio de servicio',
              '${fmt(d.meanServiceSec)} s${d.nService != null ? " (n = ${d.nService})" : ""}'],
          ['lambda (tasa de llegadas)', '${fmt(r.lambdaPerMin, 3)} usuarios/min'],
          ['mu (tasa de servicio por servidor)', '${fmt(r.muPerMin, 3)} usuarios/min'],
        ]),
        pw.SizedBox(height: 10),
        pw.Header(level: 1, text: '2. Ecuaciones empleadas'),
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          color: PdfColors.grey200,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              for (final e in QueueModel.equations(d.model))
                pw.Text(e, style: pw.TextStyle(font: pw.Font.courier(), fontSize: 9.5)),
            ],
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Header(level: 1, text: '3. Resultados'),
        _table(resultRows),
        pw.SizedBox(height: 8),
        pw.Paragraph(text: interpretation()),
        pw.Header(level: 1, text: '4. Escenarios de demanda (mismo tiempo de servicio)'),
        pw.Text('Espera en fila Wq en segundos segun tiempo entre llegadas y numero de taquillas.',
            style: const pw.TextStyle(fontSize: 10)),
        pw.SizedBox(height: 4),
        _table([
          ['T. entre llegadas (s)', 'lambda (/min)', '1 taquilla', '2 taquillas', '3 taquillas', '4 taquillas'],
          ...QueueModel.scenarioRows(d.meanServiceSec, QueueModel.scenarioArrivals),
        ]),
        pw.SizedBox(height: 10),
        pw.Header(level: 1, text: '5. Supuestos del modelo'),
        pw.Bullet(text: 'Llegadas de Poisson (tiempos entre llegadas exponenciales).'),
        pw.Bullet(text: 'Tiempos de servicio exponenciales e identicos en todos los servidores.'),
        pw.Bullet(text: 'Fila unica con disciplina FIFO, capacidad y poblacion infinitas, sin abandonos.'),
        pw.Bullet(text: 'Regimen estable: rho < 1.'),
      ],
    ),
  );
  return doc.save();
}
