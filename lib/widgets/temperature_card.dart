import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_themes.dart';

/// Temperature card with a segmented 20–50 °C semicircular gauge.
/// When no valid reading is available, the value is shown as '?' and the
/// needle is hidden rather than displaying a stale or fabricated temperature.
class TemperatureCard extends StatelessWidget {
  final String temperature;
  final AppThemeData theme;

  const TemperatureCard({
    super.key,
    required this.temperature,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final parsed = double.tryParse(temperature.trim().replaceAll(',', '.'));
    final valid = parsed != null && parsed.isFinite;
    final value = valid ? parsed!.clamp(20.0, 50.0).toDouble() : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'دمای محیط',
                  style: TextStyle(
                    color: theme.text.withOpacity(0.75),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  valid ? '${_format(value!)} °C' : '?',
                  style: TextStyle(
                    color: theme.text,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 6,
            child: SizedBox(
              height: 104,
              child: CustomPaint(
                painter: _TemperatureGaugePainter(
                  value: value,
                  textColor: theme.text.withOpacity(0.65),
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _format(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
}

class _TemperatureGaugePainter extends CustomPainter {
  final double? value;
  final Color textColor;

  const _TemperatureGaugePainter({required this.value, required this.textColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.91);
    final radius = math.min(size.width * 0.43, size.height * 0.84);
    final rect = Rect.fromCircle(center: center, radius: radius);
    const start = math.pi;
    const sweep = math.pi;
    const stroke = 15.0;

    final green = Paint()
      ..color = const Color(0xFF20C66B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;
    final yellow = Paint()
      ..color = const Color(0xFFFFC928)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;
    final red = Paint()
      ..color = const Color(0xFFFF4545)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    // Range 20–28 green, 28–32 yellow, 32–50 red.
    canvas.drawArc(rect, start, sweep * (8 / 30), false, green);
    canvas.drawArc(rect, start + sweep * (8 / 30), sweep * (7 / 30), false, yellow);
    canvas.drawArc(rect, start + sweep * (15 / 30), sweep * (15 / 30), false, red);

    // Needle is only shown when a real temperature value has been received.
    if (value != null) {
      final normalized = ((value! - 20) / 30).clamp(0.0, 1.0);
      final angle = start + sweep * normalized;
      final needleLength = radius;
      final tip = Offset(
        center.dx + math.cos(angle) * needleLength,
        center.dy + math.sin(angle) * needleLength,
      );
      final needle = Paint()
        ..color = const Color(0xFF263238)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(center, tip, needle);
      canvas.drawCircle(center, 5, Paint()..color = const Color(0xFF263238));
      canvas.drawCircle(center, 2, Paint()..color = Colors.white);
    }


  }

  @override
  bool shouldRepaint(covariant _TemperatureGaugePainter oldDelegate) =>
      oldDelegate.value != value || oldDelegate.textColor != textColor;
}
