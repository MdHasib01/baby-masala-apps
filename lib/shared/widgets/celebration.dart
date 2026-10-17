import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import 'common.dart';

/// Confetti burst + a short message, drawn on the root overlay so it survives
/// the sheet that triggered it closing (used after publishing a post).
void showCelebration(BuildContext context, {String message = 'পোস্ট সফল হয়েছে! 🎉'}) {
  HapticFeedback.mediumImpact();
  late OverlayEntry entry;
  entry = OverlayEntry(builder: (_) => _Celebration(message: message, onDone: () => entry.remove()));
  Overlay.of(context, rootOverlay: true).insert(entry);
}

class _Celebration extends StatefulWidget {
  const _Celebration({required this.message, required this.onDone});
  final String message;
  final VoidCallback onDone;

  @override
  State<_Celebration> createState() => _CelebrationState();
}

class _CelebrationState extends State<_Celebration> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))
    ..forward().whenComplete(widget.onDone);
  late final List<_Piece> _pieces;

  static const _colors = [AppColors.maroon, AppColors.gold, AppColors.sand, AppColors.olive, Color(0xFFE11D48), Color(0xFF2563EB)];

  @override
  void initState() {
    super.initState();
    final r = math.Random();
    _pieces = List.generate(90, (i) {
      // Two cannons from the lower corners, aimed up and inward.
      final left = i.isEven;
      final angle = (left ? -math.pi / 3 : -2 * math.pi / 3) + (r.nextDouble() - 0.5) * 0.9;
      final speed = 0.9 + r.nextDouble() * 0.8;
      return _Piece(
        left: left,
        vx: math.cos(angle) * speed,
        vy: math.sin(angle) * speed,
        spin: (r.nextDouble() - 0.5) * 14,
        size: 5 + r.nextDouble() * 6,
        color: _colors[r.nextInt(_colors.length)],
        circle: r.nextDouble() < 0.3,
        delay: r.nextDouble() * 0.12,
      );
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) {
          final t = _c.value;
          // Badge: pop in, hold, fade out.
          final badgeIn = Curves.elasticOut.transform((t / 0.35).clamp(0.0, 1.0));
          final badgeOut = 1 - ((t - 0.75) / 0.25).clamp(0.0, 1.0);
          return Stack(children: [
            Positioned.fill(child: CustomPaint(painter: _ConfettiPainter(_pieces, t))),
            Center(
              child: Opacity(
                opacity: badgeOut,
                child: Transform.scale(
                  scale: 0.4 + 0.6 * badgeIn,
                  child: Material(
                    color: Colors.white,
                    elevation: 8,
                    shadowColor: Colors.black26,
                    borderRadius: BorderRadius.circular(24),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                      child: Text(widget.message, style: ts(16, weight: bold, color: AppColors.maroon)),
                    ),
                  ),
                ),
              ),
            ),
          ]);
        },
      ),
    );
  }
}

class _Piece {
  _Piece({
    required this.left,
    required this.vx,
    required this.vy,
    required this.spin,
    required this.size,
    required this.color,
    required this.circle,
    required this.delay,
  });
  final bool left;
  final double vx, vy, spin, size, delay;
  final Color color;
  final bool circle;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.pieces, this.t);
  final List<_Piece> pieces;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final p in pieces) {
      final lt = ((t - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
      if (lt == 0) continue;
      // Simple ballistic path in units of screen height, with gravity.
      final scale = size.height;
      final x = (p.left ? 0.0 : size.width) + p.vx * lt * scale * 0.9;
      final y = size.height + (p.vy * lt + 1.6 * lt * lt) * scale * 0.9;
      paint.color = p.color.withValues(alpha: (1 - lt * lt).clamp(0.0, 1.0));
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.spin * lt);
      if (p.circle) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.5), paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
