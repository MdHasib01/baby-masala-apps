import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/bn_digits.dart';
import 'common.dart';

/// Reaction type → (emoji, Bengali label, accent colour). Order = picker order.
const reactionInfo = <String, (String, String, Color)>{
  'like': ('👍', 'লাইক', Color(0xFF2563EB)),
  'love': ('❤️', 'লাভ', Color(0xFFE11D48)),
  'haha': ('😆', 'হাহা', Color(0xFFD97706)),
  'care': ('🤗', 'কেয়ার', Color(0xFFD97706)),
};

/// Facebook-style react button: tap = like (or remove your reaction),
/// long-press = picker bar; slide over an emoji and release to pick.
class ReactionButton extends StatefulWidget {
  const ReactionButton({super.key, required this.current, required this.onReact});

  /// The viewer's reaction type, or null.
  final String? current;
  final ValueChanged<String> onReact;

  @override
  State<ReactionButton> createState() => _ReactionButtonState();
}

class _ReactionButtonState extends State<ReactionButton> with SingleTickerProviderStateMixin {
  late final _pop = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
  final _key = GlobalKey();
  OverlayEntry? _overlay;
  final _hovered = ValueNotifier<String?>(null);
  Rect _barRect = Rect.zero;

  static const _itemSize = 44.0;
  static const _barPad = 6.0;

  @override
  void dispose() {
    _removeOverlay();
    _pop.dispose();
    _hovered.dispose();
    super.dispose();
  }

  void _pick(String type) {
    _removeOverlay();
    HapticFeedback.lightImpact();
    final adding = widget.current != type;
    widget.onReact(type);
    if (adding) {
      _pop.forward(from: 0);
      _burst(type);
    }
  }

  // ---- picker overlay
  void _showPicker() {
    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    HapticFeedback.mediumImpact();
    final origin = box.localToGlobal(Offset.zero);
    final screen = MediaQuery.of(context).size;
    final width = reactionInfo.length * _itemSize + _barPad * 2;
    final left = (origin.dx).clamp(8.0, screen.width - width - 8);
    final top = math.max(8.0, origin.dy - _itemSize - 26);
    _barRect = Rect.fromLTWH(left, top, width, _itemSize + _barPad * 2);

    _overlay = OverlayEntry(
      builder: (_) => Stack(children: [
        Positioned.fill(child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: _removeOverlay)),
        Positioned.fromRect(rect: _barRect, child: _PickerBar(hovered: _hovered, onPick: _pick, itemSize: _itemSize, pad: _barPad)),
      ]),
    );
    Overlay.of(context).insert(_overlay!);
  }

  void _removeOverlay() {
    _overlay?.remove();
    _overlay = null;
    _hovered.value = null;
  }

  String? _typeAt(Offset global) {
    final r = _barRect.inflate(24);
    if (!r.contains(global)) return null;
    final i = ((global.dx - _barRect.left - _barPad) / _itemSize).floor();
    if (i < 0 || i >= reactionInfo.length) return null;
    return reactionInfo.keys.elementAt(i);
  }

  // ---- floating emoji burst (small "effect" on react)
  void _burst(String type) {
    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final start = box.localToGlobal(Offset(28, box.size.height / 2));
    late OverlayEntry entry;
    entry = OverlayEntry(builder: (_) => _EmojiBurst(emoji: reactionInfo[type]!.$1, origin: start, onDone: () => entry.remove()));
    Overlay.of(context).insert(entry);
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.current == null ? null : reactionInfo[widget.current];
    final color = info?.$3 ?? AppColors.grey600;

    return GestureDetector(
      key: _key,
      behavior: HitTestBehavior.opaque,
      onTap: () => _pick(widget.current ?? 'like'),
      onLongPressStart: (_) => _showPicker(),
      onLongPressMoveUpdate: (d) => _hovered.value = _typeAt(d.globalPosition),
      onLongPressEnd: (d) {
        final t = _typeAt(d.globalPosition);
        // Released over an emoji → pick it; otherwise leave the bar open for a tap.
        if (t != null) _pick(t);
        _hovered.value = null;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: info?.$3.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          ScaleTransition(
            scale: TweenSequence<double>([
              TweenSequenceItem(tween: Tween(begin: 1, end: 1.6), weight: 35),
              TweenSequenceItem(tween: Tween(begin: 1.6, end: 0.9), weight: 30),
              TweenSequenceItem(tween: Tween(begin: 0.9, end: 1), weight: 35),
            ]).animate(CurvedAnimation(parent: _pop, curve: Curves.easeOut)),
            child: info == null
                ? const Icon(LucideIcons.thumbsUp, size: 16, color: AppColors.grey600)
                : Text(info.$1, style: const TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 6),
          Text(info?.$2 ?? 'লাইক', style: ts(12, weight: info != null ? bold : semi, color: color)),
        ]),
      ),
    );
  }
}

class _PickerBar extends StatefulWidget {
  const _PickerBar({required this.hovered, required this.onPick, required this.itemSize, required this.pad});

  final ValueNotifier<String?> hovered;
  final ValueChanged<String> onPick;
  final double itemSize;
  final double pad;

  @override
  State<_PickerBar> createState() => _PickerBarState();
}

class _PickerBarState extends State<_PickerBar> with SingleTickerProviderStateMixin {
  late final _in = AnimationController(vsync: this, duration: const Duration(milliseconds: 260))..forward();

  @override
  void dispose() {
    _in.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final types = reactionInfo.keys.toList();
    return Material(
      color: Colors.transparent,
      child: ScaleTransition(
        alignment: Alignment.bottomLeft,
        scale: CurvedAnimation(parent: _in, curve: Curves.easeOutBack),
        child: Container(
          padding: EdgeInsets.all(widget.pad),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: AppColors.sandA(0.8)),
            boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 14, offset: Offset(0, 4))],
          ),
          child: ValueListenableBuilder<String?>(
            valueListenable: widget.hovered,
            builder: (_, hovered, _) => Row(mainAxisSize: MainAxisSize.min, children: [
              for (var i = 0; i < types.length; i++)
                GestureDetector(
                  onTap: () => widget.onPick(types[i]),
                  child: SizedBox(
                    width: widget.itemSize,
                    height: widget.itemSize,
                    child: Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
                      // Staggered entrance, then grow when hovered.
                      AnimatedScale(
                        scale: hovered == types[i] ? 1.45 : 1,
                        duration: const Duration(milliseconds: 140),
                        child: FadeTransition(
                          opacity: CurvedAnimation(parent: _in, curve: Interval(i * 0.12, 0.6 + i * 0.1)),
                          child: Text(reactionInfo[types[i]]!.$1, style: const TextStyle(fontSize: 30)),
                        ),
                      ),
                      if (hovered == types[i])
                        Positioned(
                          top: -30,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(10)),
                            child: Text(reactionInfo[types[i]]!.$2, style: ts(10.5, weight: bold, color: Colors.white)),
                          ),
                        ),
                    ]),
                  ),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// A few copies of the emoji float up and fade out from the button.
class _EmojiBurst extends StatefulWidget {
  const _EmojiBurst({required this.emoji, required this.origin, required this.onDone});

  final String emoji;
  final Offset origin;
  final VoidCallback onDone;

  @override
  State<_EmojiBurst> createState() => _EmojiBurstState();
}

class _EmojiBurstState extends State<_EmojiBurst> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
    ..forward().whenComplete(widget.onDone);
  final _rand = math.Random();
  late final _drift = List.generate(5, (_) => (_rand.nextDouble() - 0.5) * 70);
  late final _delay = List.generate(5, (i) => i * 0.08);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, _) => Stack(children: [
            for (var i = 0; i < _drift.length; i++)
              () {
                final t = ((_c.value - _delay[i]) / (1 - _delay[i])).clamp(0.0, 1.0);
                return Positioned(
                  left: widget.origin.dx + _drift[i] * t - 10,
                  top: widget.origin.dy - 90 * Curves.easeOut.transform(t) - 10,
                  child: Opacity(
                    opacity: t == 0 ? 0 : (1 - t),
                    child: Transform.scale(scale: 0.6 + 0.6 * t, child: Text(widget.emoji, style: const TextStyle(fontSize: 18))),
                  ),
                );
              }(),
          ]),
        ),
      );
}

/// "👍❤️ ১২" — stacked emoji of the reaction types present, plus the total.
class ReactionSummary extends StatelessWidget {
  const ReactionSummary({super.key, required this.types, required this.total});

  final List<String> types;
  final int total;

  @override
  Widget build(BuildContext context) {
    if (total <= 0) return const SizedBox.shrink();
    final shown = types.take(3).toList();
    return Row(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(
        width: 18.0 + (shown.length - 1) * 13,
        height: 20,
        child: Stack(children: [
          for (var i = 0; i < shown.length; i++)
            Positioned(
              left: i * 13.0,
              child: Container(
                width: 20,
                height: 20,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
                child: Text(reactionInfo[shown[i]]?.$1 ?? '👍', style: const TextStyle(fontSize: 12)),
              ),
            ),
        ]),
      ),
      const SizedBox(width: 4),
      Text(toBnDigits(total), style: ts(11.5, color: AppColors.grey500)),
    ]);
  }
}
