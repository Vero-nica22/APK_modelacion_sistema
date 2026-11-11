import 'dart:math';
import 'package:flutter/material.dart';
import 'theme.dart';

class MetroLinesPainter extends CustomPainter {
  const MetroLinesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height, d = h * 0.18;
    Paint stroke(Color c, double sw) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final pink = Path()
      ..moveTo(-10, h * .84)
      ..lineTo(w * .35, h * .84)
      ..lineTo(w * .35 + d, h * .84 - d)
      ..lineTo(w + 10, h * .84 - d);
    final yellow = Path()
      ..moveTo(-10, h * .62)
      ..lineTo(w * .5, h * .62)
      ..lineTo(w * .5 + d, h * .62 + d)
      ..lineTo(w + 10, h * .62 + d);
    final lilac = Path()
      ..moveTo(-10, h * .95)
      ..lineTo(w + 10, h * .95);

    canvas.drawPath(lilac, stroke(AppColors.lilac.withAlpha(90), 4));
    canvas.drawPath(pink, stroke(AppColors.pink, 8));
    canvas.drawPath(yellow, stroke(AppColors.yellow, 8));

    void station(Offset o, {double r = 6.5}) {
      canvas.drawCircle(o, r, Paint()..color = Colors.white);
      canvas.drawCircle(o, r, stroke(AppColors.deepPurple, 3));
    }

    station(Offset(w * .12, h * .84));
    station(Offset(w * .72, h * .84 - d));
    station(Offset(w * .92, h * .84 - d));
    station(Offset(w * .15, h * .62));
    station(Offset(w * .32, h * .62));
    station(Offset(w * .85, h * .62 + d));
    station(Offset(w * .5 + h * .04, h * .66), r: 10); 
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MetroHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final double height;
  const MetroHeader(
      {super.key, required this.title, required this.subtitle, this.height = 190});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.deepPurple, AppColors.purple],
        ),
      ),
      child: Stack(children: [
        const Positioned.fill(child: CustomPaint(painter: MetroLinesPainter())),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.lilac, fontSize: 14)),
          ]),
        ),
      ]),
    );
  }
}

AppBar metroAppBar(BuildContext context, String title, {List<Widget>? actions}) {
  final cs = Theme.of(context).colorScheme;
  final dark = cs.brightness == Brightness.dark;
  return AppBar(
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
    backgroundColor: dark ? cs.surface : cs.primary,
    foregroundColor: dark ? cs.onSurface : cs.onPrimary,
    elevation: 0,
    scrolledUnderElevation: 0,
    actions: actions,
    bottom: const PreferredSize(
      preferredSize: Size.fromHeight(5),
      child: Row(children: [
        Expanded(flex: 3, child: ColoredBox(color: AppColors.pink, child: SizedBox(height: 5))),
        Expanded(flex: 2, child: ColoredBox(color: AppColors.yellow, child: SizedBox(height: 5))),
        Expanded(flex: 1, child: ColoredBox(color: AppColors.lilac, child: SizedBox(height: 5))),
      ]),
    ),
  );
}

/// Titulo de seccion con "estacion" y tramo de linea.
class SectionTitle extends StatelessWidget {
  final String text;
  final Color? color;
  const SectionTitle(this.text, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final c = color ?? cs.secondary;
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Row(children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
              shape: BoxShape.circle, color: cs.surface, border: Border.all(color: c, width: 4)),
        ),
        const SizedBox(width: 10),
        Text(text, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        const SizedBox(width: 10),
        Expanded(
            child: Container(
                height: 4,
                decoration: BoxDecoration(
                    color: c.withAlpha(110), borderRadius: BorderRadius.circular(2)))),
      ]),
    );
  }
}

class AppCard extends StatelessWidget {
  final Widget child;
  final Color? color;
  final EdgeInsets padding;
  const AppCard(
      {super.key, required this.child, this.color, this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color == null ? cs.outlineVariant : Colors.transparent),
      ),
      child: child,
    );
  }
}

InputDecoration metroInput(BuildContext context,
    {required String label, String? hint, String? helper, IconData? icon}) {
  final cs = Theme.of(context).colorScheme;
  OutlineInputBorder b(Color c, double w) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: c, width: w));
  return InputDecoration(
    labelText: label,
    hintText: hint,
    helperText: helper,
    prefixIcon: icon == null ? null : Icon(icon),
    filled: true,
    fillColor: cs.surface,
    border: b(cs.outlineVariant, 1),
    enabledBorder: b(cs.outlineVariant, 1),
    focusedBorder: b(cs.secondary, 2),
  );
}

/// Utilizacion como una linea de metro con un tren que avanza.
class MetroUtilization extends StatelessWidget {
  final double rho;
  const MetroUtilization({super.key, required this.rho});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final level = rho < 0.6
        ? ('Holgado', cs.tertiary)
        : rho < 0.85
            ? ('Moderado', cs.secondary)
            : rho < 1
                ? ('Casi saturado', cs.error)
                : ('Inestable', cs.error);
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('Utilización de las taquillas',
              style: const TextStyle(fontWeight: FontWeight.w700)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: level.$2.withAlpha(60), borderRadius: BorderRadius.circular(12)),
            child: Text(level.$1, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
          ),
        ]),
        const SizedBox(height: 6),
        TweenAnimationBuilder<double>(
          tween: Tween(end: min(rho, 1.0)),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          builder: (_, v, __) => SizedBox(
            height: 64,
            width: double.infinity,
            child: CustomPaint(
              painter: _UtilPainter(
                progress: v,
                fill: level.$2,
                track: cs.outlineVariant,
                station: cs.surface,
                border: cs.brightness == Brightness.dark ? cs.onSurface : AppColors.deepPurple,
                label: cs.onSurfaceVariant,
                train: AppColors.yellow,
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _UtilPainter extends CustomPainter {
  final double progress;
  final Color fill, track, station, border, label, train;
  _UtilPainter({
    required this.progress,
    required this.fill,
    required this.track,
    required this.station,
    required this.border,
    required this.label,
    required this.train,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const pad = 22.0;
    final y = size.height * 0.38;
    final len = size.width - 2 * pad;
    final x = pad + len * progress;

    Paint line(Color c, double w) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(pad, y), Offset(pad + len, y), line(track, 10));
    if (progress > 0) canvas.drawLine(Offset(pad, y), Offset(x, y), line(fill, 10));

    for (var i = 0; i <= 4; i++) {
      final sx = pad + len * i / 4;
      final o = Offset(sx, y);
      canvas.drawCircle(o, 9, Paint()..color = station);
      canvas.drawCircle(o, 9, line(sx <= x + 0.5 ? border : track, 3.5));
    }
    for (final e in {0.0: '0 %', 0.5: '50 %', 1.0: '100 %'}.entries) {
      final tp = TextPainter(
        text: TextSpan(text: e.value, style: TextStyle(color: label, fontSize: 11)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(pad + len * e.key - tp.width / 2, y + 18));
    }

    // Tren
    final r = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x, y), width: 38, height: 22), const Radius.circular(8));
    canvas.drawRRect(r, Paint()..color = train);
    canvas.drawRRect(r, line(border, 2.5));
    for (final dx in [-9.0, 3.0]) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(x + dx, y - 6, 8, 8), const Radius.circular(2)),
          Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant _UtilPainter old) =>
      old.progress != progress || old.fill != fill || old.track != track || old.border != border;
}
