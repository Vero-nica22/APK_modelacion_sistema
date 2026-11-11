import 'package:flutter_test/flutter_test.dart';
import 'package:colas_metro/queue_model.dart';

void main() {
  const meanService = 21.5311428571429; // promedio de los 35 datos de Estadio

  test('M/M/2 Estadio coincide con el Excel', () {
    final r = QueueModel.solve(meanArrivalSec: 40, meanServiceSec: meanService, servers: 2);
    expect(r.stable, isTrue);
    expect(r.rho, closeTo(0.26914, 1e-4));
    expect(r.p0!, closeTo(0.57587, 1e-4));
    expect(r.pw!, closeTo(0.11415, 1e-4));
    expect(r.lq!, closeTo(0.04204, 1e-4));
    expect(r.wqSec!, closeTo(1.6814, 1e-3));
    expect(r.wSec!, closeTo(23.2126, 1e-3));
    expect(r.l!, closeTo(0.58031, 1e-4));
  });

  test('M/M/1: P0 = 1 - rho y Wq = rho/(mu - lambda)', () {
    final r = QueueModel.solve(meanArrivalSec: 40, meanServiceSec: meanService, servers: 1);
    expect(r.p0!, closeTo(1 - r.rho, 1e-12));
    final lam = r.lambdaPerMin / 60, mu = r.muPerMin / 60;
    expect(r.wqSec!, closeTo(r.rho / (mu - lam), 1e-9));
    expect(r.wqSec!, closeTo(25.10, 1e-2));
  });

  test('Sistema inestable cuando rho >= 1', () {
    final r = QueueModel.solve(meanArrivalSec: 10, meanServiceSec: meanService, servers: 2);
    expect(r.stable, isFalse);
    expect(r.rho, closeTo(1.0766, 1e-3));
    expect(r.wqSec, isNull);
  });

  test('Ley de Little: L = lambda*W', () {
    final r = QueueModel.solve(meanArrivalSec: 20, meanServiceSec: meanService, servers: 3);
    expect(r.l!, closeTo(r.lambdaPerMin / 60 * r.wSec!, 1e-9));
  });

  test('parseNumbers acepta coma decimal y rechaza basura', () {
    expect(parseNumbers('20,5 11.8\n7'), [20.5, 11.8, 7.0]);
    expect(() => parseNumbers('12 abc'), throwsFormatException);
    expect(() => parseNumbers('-3'), throwsFormatException);
  });

  test('Stats: media, desviacion muestral y CV', () {
    final s = Stats.of([10, 20, 30]);
    expect(s.mean, 20);
    expect(s.std, closeTo(10, 1e-12));
    expect(s.cv, closeTo(0.5, 1e-12));
  });
}
