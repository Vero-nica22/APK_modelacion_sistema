import 'dart:math';

enum QueueModelType { mm1, mms }

String fmt(double v, [int d = 2]) => v.toStringAsFixed(d).replaceAll('.', ',');


List<double> parseNumbers(String text) {
  final cleaned = text.trim();
  if (cleaned.isEmpty) return [];
  final parts = cleaned
      .replaceAll(',', '.')
      .split(RegExp(r'[\s;]+'))
      .where((p) => p.isNotEmpty);
  final out = <double>[];
  for (final p in parts) {
    final v = double.tryParse(p);
    if (v == null) throw FormatException('"$p" no es un número válido.');
    if (v <= 0) {
      throw FormatException('Los tiempos deben ser mayores que 0 (encontré $p).');
    }
    out.add(v);
  }
  return out;
}

class Stats {
  final int n;
  final double mean;
  final double std;
  const Stats(this.n, this.mean, this.std);
  double get cv => mean == 0 ? 0 : std / mean;

  factory Stats.of(List<double> x) {
    final n = x.length;
    final mean = x.reduce((a, b) => a + b) / n;
    final ss = x.fold<double>(0, (s, v) => s + (v - mean) * (v - mean));
    final std = n > 1 ? sqrt(ss / (n - 1)) : 0.0;
    return Stats(n, mean, std);
  }
}

class QueueInputData {
  final String station;
  final QueueModelType model;
  final int servers;
  final double meanArrivalSec;
  final double meanServiceSec;
  final int? nArrivals;
  final int? nService;
  final double? cvService;

  const QueueInputData({
    required this.station,
    required this.model,
    required this.servers,
    required this.meanArrivalSec,
    required this.meanServiceSec,
    this.nArrivals,
    this.nService,
    this.cvService,
  });

  String get modelLabel => model == QueueModelType.mm1 ? 'M/M/1' : 'M/M/$servers';
}

class QueueResult {
  final int servers;
  final double lambdaPerMin;
  final double muPerMin;
  final double a;
  final double rho;
  final bool stable;
  final double? p0, pw, lq, wqSec, wSec, l;

  const QueueResult({
    required this.servers,
    required this.lambdaPerMin,
    required this.muPerMin,
    required this.a,
    required this.rho,
    required this.stable,
    this.p0,
    this.pw,
    this.lq,
    this.wqSec,
    this.wSec,
    this.l,
  });
}

class QueueModel {
  static double _fact(int n) {
    double r = 1;
    for (var i = 2; i <= n; i++) {
      r *= i;
    }
    return r;
  }

  /// Resuelve M/M/s (s = 1 equivale a M/M/1). Tiempos en segundos.
  static QueueResult solve({
    required double meanArrivalSec,
    required double meanServiceSec,
    required int servers,
  }) {
    final lambda = 60 / meanArrivalSec; // usuarios/min
    final mu = 60 / meanServiceSec; // usuarios/min por servidor
    final a = lambda / mu;
    final rho = a / servers;
    if (rho >= 1) {
      return QueueResult(
          servers: servers, lambdaPerMin: lambda, muPerMin: mu, a: a, rho: rho, stable: false);
    }
    double sum = 0;
    for (var k = 0; k < servers; k++) {
      sum += pow(a, k).toDouble() / _fact(k);
    }
    final last = pow(a, servers).toDouble() / (_fact(servers) * (1 - rho));
    final p0 = 1 / (sum + last);
    final pw = last * p0;
    final lq = pw * rho / (1 - rho);
    final wq = lq / lambda * 60;
    final w = wq + 60 / mu;
    return QueueResult(
      servers: servers,
      lambdaPerMin: lambda,
      muPerMin: mu,
      a: a,
      rho: rho,
      stable: true,
      p0: p0,
      pw: pw,
      lq: lq,
      wqSec: wq,
      wSec: w,
      l: lq + a,
    );
  }

  static double correctedWq(double wqSec, double cvService) =>
      wqSec * (1 + cvService * cvService) / 2;

  static List<List<String>> scenarioRows(double meanServiceSec, List<double> arrivals) {
    return [
      for (final t in arrivals)
        [
          fmt(t, 0),
          fmt(60 / t, 1),
          for (var s = 1; s <= 4; s++)
            () {
              final r = solve(meanArrivalSec: t, meanServiceSec: meanServiceSec, servers: s);
              return r.stable ? fmt(r.wqSec!, 1) : 'Inestable';
            }(),
        ]
    ];
  }

  static List<String> equations(QueueModelType m) => m == QueueModelType.mm1
      ? const [
          'rho = lambda / mu        (estable si rho < 1)',
          'P0 = 1 - rho',
          'Lq = rho^2 / (1 - rho)',
          'Wq = rho / (mu - lambda)',
          'W = 1 / (mu - lambda)',
          'L = rho / (1 - rho)',
        ]
      : const [
          'a = lambda / mu',
          'rho = lambda / (s * mu)        (estable si rho < 1)',
          'P0 = [ SUM(k=0..s-1) a^k/k!  +  a^s / (s! (1 - rho)) ]^-1',
          'Pw = a^s / (s! (1 - rho)) * P0        (Erlang C)',
          'Lq = Pw * rho / (1 - rho)',
          'Wq = Lq / lambda',
          'W = Wq + 1 / mu',
          'L = Lq + a',
        ];

  static const scenarioArrivals = <double>[60, 40, 30, 20, 15, 10];
}
