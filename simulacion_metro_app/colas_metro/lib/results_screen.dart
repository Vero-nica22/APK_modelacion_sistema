import 'dart:math';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'metro_decor.dart';
import 'pdf_report.dart';
import 'queue_model.dart';

String _pretty(String s) => s
    .replaceAll('lambda', 'λ')
    .replaceAll('mu', 'μ')
    .replaceAll('rho', 'ρ')
    .replaceAll('SUM', 'Σ');

class ResultsScreen extends StatefulWidget {
  final QueueInputData data;
  const ResultsScreen({super.key, required this.data});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  late double _simArrival = widget.data.meanArrivalSec;

  QueueResult _solve(double arrival) => QueueModel.solve(
      meanArrivalSec: arrival,
      meanServiceSec: widget.data.meanServiceSec,
      servers: widget.data.servers);

  Future<void> _pdf() async {
    // El informe siempre usa los datos observados (no el simulador).
    final bytes = await buildReport(widget.data, _solve(widget.data.meanArrivalSec));
    await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: 'informe_colas_${widget.data.modelLabel.replaceAll('/', '')}.pdf');
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final r = _solve(_simArrival);
    final cs = Theme.of(context).colorScheme;
    final isSim = (_simArrival - d.meanArrivalSec).abs() > 0.01;
    final sliderMax = max(120.0, d.meanArrivalSec * 1.5);

    final tiles = <_Metric>[
      _Metric('ρ', 'Utilización', fmt(r.rho * 100, 1), '%'),
      if (r.stable) ...[
        _Metric('Wq', 'Espera en fila', fmt(r.wqSec!, 1), 's'),
        _Metric('W', 'Tiempo en sistema', fmt(r.wSec!, 1), 's'),
        _Metric('Pw', 'Prob. de esperar', fmt(r.pw! * 100, 1), '%'),
        _Metric('Lq', 'Personas en fila', fmt(r.lq!, 3), ''),
        _Metric('L', 'Personas en sistema', fmt(r.l!, 3), ''),
        _Metric('P0', 'Sistema vacío', fmt(r.p0!, 3), ''),
        _Metric('a', 'Carga ofrecida', fmt(r.a, 3), ''),
      ],
    ];

    return Scaffold(
      appBar: metroAppBar(context, 'Resultados ${d.modelLabel}', actions: [
        IconButton(
            tooltip: 'Informe PDF',
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: _pdf),
      ]),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          MetroHeader(
            height: 170,
            title: d.station.isEmpty ? 'Taquillas de recarga' : d.station,
            subtitle: 'Modelo ${d.modelLabel} · s = ${d.servers}',
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('λ = ${fmt(r.lambdaPerMin, 3)} usuarios/min${isSim ? "  (simulado)" : ""}',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text('μ = ${fmt(r.muPerMin, 3)} usuarios/min por taquilla',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              if (d.nService != null || d.nArrivals != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                      'Datos: ${d.nArrivals ?? "–"} llegadas · ${d.nService ?? "–"} servicios',
                      style: TextStyle(color: cs.onSurfaceVariant)),
                ),
            ]),
          ),
          const SizedBox(height: 12),
          MetroUtilization(rho: r.rho),
          const SizedBox(height: 12),
          if (!r.stable)
            AppCard(
              color: cs.errorContainer,
              child: Row(children: [
                Icon(Icons.warning_amber_rounded, color: cs.onErrorContainer),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Sistema inestable (ρ ≥ 1): la fila crece sin límite. Agrega taquillas o reduce el tiempo de servicio.',
                    style: TextStyle(color: cs.onErrorContainer),
                  ),
                ),
              ]),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < tiles.length; i++) _MetricCard(tiles[i], i),
              ],
            ),
          if (r.stable && d.cvService != null) ...[
            const SizedBox(height: 12),
            AppCard(
              color: cs.tertiaryContainer,
              child: Row(children: [
                Icon(Icons.tune, color: cs.onTertiaryContainer),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Wq corregido (Allen–Cunneen): ${fmt(QueueModel.correctedWq(r.wqSec!, d.cvService!), 1)} s\n'
                    'CV del servicio = ${fmt(d.cvService!, 2)}. Si CV ≠ 1 el servicio no es exponencial.',
                    style: TextStyle(color: cs.onTertiaryContainer),
                  ),
                ),
              ]),
            ),
          ],
          SectionTitle('Simular hora pico', color: cs.tertiary),
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Llega un usuario cada ${fmt(_simArrival, 0)} s',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              Slider(
                min: 5,
                max: sliderMax,
                divisions: (sliderMax - 5).round(),
                value: _simArrival.clamp(5, sliderMax).toDouble(),
                label: '${fmt(_simArrival, 0)} s',
                onChanged: (v) => setState(() => _simArrival = v),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                    style: TextButton.styleFrom(foregroundColor: cs.secondary),
                    onPressed: () => setState(() => _simArrival = d.meanArrivalSec),
                    child: const Text('Restablecer valor observado')),
              ),
            ]),
          ),
          SectionTitle('Ecuaciones empleadas', color: cs.primary),
          AppCard(
            color: cs.primaryContainer,
            child: Text(
              QueueModel.equations(d.model).map(_pretty).join('\n'),
              style: TextStyle(
                  fontFamily: 'monospace', height: 1.7, color: cs.onPrimaryContainer),
            ),
          ),
          const SectionTitle('Escenarios: Wq (s)'),
          AppCard(
            padding: const EdgeInsets.all(8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 18,
                headingTextStyle: const TextStyle(fontWeight: FontWeight.w800),
                columns: const [
                  DataColumn(label: Text('Llegada\n(s)')),
                  DataColumn(label: Text('λ\n(/min)')),
                  DataColumn(label: Text('1\ntaq.')),
                  DataColumn(label: Text('2\ntaq.')),
                  DataColumn(label: Text('3\ntaq.')),
                  DataColumn(label: Text('4\ntaq.')),
                ],
                rows: [
                  for (final row
                      in QueueModel.scenarioRows(d.meanServiceSec, QueueModel.scenarioArrivals))
                    DataRow(cells: [
                      for (final c in row)
                        DataCell(Text(c,
                            style: TextStyle(
                                color: c == 'Inestable' ? cs.secondary : null,
                                fontWeight: c == 'Inestable' ? FontWeight.w800 : null))),
                    ]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            style: FilledButton.styleFrom(
                backgroundColor: cs.secondary,
                foregroundColor: cs.onSecondary,
                padding: const EdgeInsets.symmetric(vertical: 16)),
            onPressed: _pdf,
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('Generar informe PDF'),
          ),
          const SizedBox(height: 8),
          Text('El informe usa los datos observados, no el valor simulado del control.',
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
        ],
      ),
    );
  }
}

class _Metric {
  final String symbol, label, value, unit;
  const _Metric(this.symbol, this.label, this.value, this.unit);
}

class _MetricCard extends StatelessWidget {
  final _Metric m;
  final int index;
  const _MetricCard(this.m, this.index);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final palette = [
      (cs.primaryContainer, cs.onPrimaryContainer),
      (cs.secondaryContainer, cs.onSecondaryContainer),
      (cs.tertiaryContainer, cs.onTertiaryContainer),
    ][index % 3];
    final w = (MediaQuery.of(context).size.width - 32 - 16) / 3;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + index * 70),
      curve: Curves.easeOut,
      builder: (_, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, 12 * (1 - v)), child: child),
      ),
      child: Container(
        width: w,
        padding: const EdgeInsets.all(12),
        decoration:
            BoxDecoration(color: palette.$1, borderRadius: BorderRadius.circular(18)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(m.symbol,
              style: TextStyle(
                  fontWeight: FontWeight.w900, fontSize: 13, color: palette.$2)),
          const SizedBox(height: 4),
          Text('${m.value}${m.unit.isEmpty ? "" : " ${m.unit}"}',
              style: TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 17, color: palette.$2)),
          const SizedBox(height: 2),
          Text(m.label, style: TextStyle(fontSize: 11, color: palette.$2)),
        ]),
      ),
    );
  }
}
