import 'package:flutter/material.dart';
import 'metro_decor.dart';
import 'queue_model.dart';
import 'results_screen.dart';

class InputScreen extends StatefulWidget {
  const InputScreen({super.key});

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  final _station = TextEditingController();
  final _arrivals = TextEditingController();
  final _service = TextEditingController();
  final _meanArr = TextEditingController();
  final _meanSrv = TextEditingController();
  final _servers = TextEditingController(text: '2');

  QueueModelType _model = QueueModelType.mms;
  bool _raw = true;

  static const _exampleService =
      '20.43 11.83 20.98 27.71 14.35 17.18 16.97 41.78 24.71 30.78 12.34 14.34 24.83 31.95 18.41\n'
      '7 45 58 21 11 10 48 20 11 15 11 30 12 18 16 15 16 36 14 11';

  @override
  void dispose() {
    for (final c in [_station, _arrivals, _service, _meanArr, _meanSrv, _servers]) {
      c.dispose();
    }
    super.dispose();
  }

  void _loadExample() {
    setState(() {
      _station.text = 'Estación Estadio';
      _model = QueueModelType.mms;
      _servers.text = '2';
      _raw = false;
      _meanArr.text = '40';
      _service.text = _exampleService;
      _meanSrv.text = fmt(Stats.of(parseNumbers(_exampleService)).mean, 2);
    });
  }

  void _error(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
  }

  double _single(TextEditingController c, String name) {
    final v = double.tryParse(c.text.trim().replaceAll(',', '.'));
    if (v == null || v <= 0) {
      throw FormatException('Ingresa un valor mayor que 0 en "$name".');
    }
    return v;
  }

  void _calculate() {
    try {
      final servers =
          _model == QueueModelType.mm1 ? 1 : (int.tryParse(_servers.text.trim()) ?? 0);
      if (servers < 1) throw const FormatException('El número de taquillas debe ser al menos 1.');

      double meanArr, meanSrv;
      int? nA, nS;
      double? cv;
      if (_raw) {
        final a = parseNumbers(_arrivals.text);
        final s = parseNumbers(_service.text);
        if (a.isEmpty || s.isEmpty) {
          throw const FormatException('Ingresa al menos un dato en cada lista.');
        }
        final sa = Stats.of(a), ss = Stats.of(s);
        meanArr = sa.mean;
        meanSrv = ss.mean;
        nA = sa.n;
        nS = ss.n;
        cv = ss.n > 1 ? ss.cv : null;
      } else {
        meanArr = _single(_meanArr, 'Tiempo medio entre llegadas');
        meanSrv = _single(_meanSrv, 'Tiempo medio de servicio');
        final s = parseNumbers(_service.text);
        if (s.length > 1) {
          final ss = Stats.of(s);
          nS = ss.n;
          cv = ss.cv;
        }
      }

      Navigator.of(context).push(PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (_, __, ___) => ResultsScreen(
          data: QueueInputData(
            station: _station.text.trim(),
            model: _model,
            servers: servers,
            meanArrivalSec: meanArr,
            meanServiceSec: meanSrv,
            nArrivals: nA,
            nService: nS,
            cvService: cv,
          ),
        ),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, 0.06), end: Offset.zero).animate(anim),
            child: child,
          ),
        ),
      ));
    } on FormatException catch (e) {
      _error(e.message);
    }
  }

  Widget _dataField(TextEditingController c, String label, String hint) {
    return TextField(
      controller: c,
      minLines: 3,
      maxLines: 6,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: metroInput(context,
          label: label,
          hint: hint,
          helper: 'Un dato por línea o separados por espacio. Segundos.'),
      onChanged: (_) => setState(() {}),
    );
  }

  int _count(TextEditingController c) {
    try {
      return parseNumbers(c.text).length;
    } catch (_) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: metroAppBar(context, 'Colas Metro', actions: [
        IconButton(
            tooltip: 'Cargar datos de ejemplo (Estadio)',
            icon: const Icon(Icons.science_outlined),
            onPressed: _loadExample),
      ]),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          const MetroHeader(
            title: 'Teoría de colas',
            subtitle: 'Modela la fila de tus taquillas: ρ, Wq, W, L e informe PDF.',
          ),
          const SectionTitle('Sistema'),
          TextField(
            controller: _station,
            decoration: metroInput(context,
                label: 'Estación / sistema', icon: Icons.place_outlined),
          ),
          const SectionTitle('Modelo de colas', color: Color(0xFFFACC15)),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<QueueModelType>(
              segments: const [
                ButtonSegment(value: QueueModelType.mm1, label: Text('M/M/1')),
                ButtonSegment(value: QueueModelType.mms, label: Text('M/M/s')),
              ],
              selected: {_model},
              onSelectionChanged: (s) => setState(() => _model = s.first),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            child: _model == QueueModelType.mms
                ? Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: TextField(
                      controller: _servers,
                      keyboardType: TextInputType.number,
                      decoration: metroInput(context,
                          label: 'Número de taquillas abiertas (s)',
                          icon: Icons.confirmation_number_outlined),
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
          SectionTitle('Datos de campo', color: cs.primary),
          AppCard(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: cs.secondary,
                title: const Text('Ingresar tiempos individuales'),
                subtitle: Text(_raw
                    ? 'Se calculan los promedios con tus mediciones'
                    : 'Ingreso directo de promedios'),
                value: _raw,
                onChanged: (v) => setState(() => _raw = v),
              ),
              const SizedBox(height: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _raw
                    ? Column(key: const ValueKey('raw'), children: [
                        _dataField(_arrivals,
                            'Tiempos entre llegadas (n = ${_count(_arrivals)})', '38.5 12 61 ...'),
                        const SizedBox(height: 12),
                        _dataField(_service,
                            'Tiempos de servicio (n = ${_count(_service)})', '20.4 11.8 7 ...'),
                      ])
                    : Column(key: const ValueKey('mean'), children: [
                        TextField(
                          controller: _meanArr,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: metroInput(context,
                              label: 'Tiempo medio entre llegadas (s)',
                              icon: Icons.timer_outlined),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _meanSrv,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: metroInput(context,
                              label: 'Tiempo medio de servicio (s)',
                              icon: Icons.hourglass_bottom),
                        ),
                      ]),
              ),
            ]),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            style: FilledButton.styleFrom(
                backgroundColor: cs.secondary,
                foregroundColor: cs.onSecondary,
                padding: const EdgeInsets.symmetric(vertical: 16)),
            onPressed: _calculate,
            icon: const Icon(Icons.calculate_outlined),
            label: const Text('Calcular'),
          ),
          const SizedBox(height: 4),
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: cs.primary),
            onPressed: _loadExample,
            icon: const Icon(Icons.science_outlined),
            label: const Text('Cargar ejemplo (Estación Estadio)'),
          ),
        ],
      ),
    );
  }
}
