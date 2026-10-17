import 'package:flutter/material.dart';

/// Lets a bottom sheet with scrollable content close by dragging down, like
/// the drag handle does. When the inner list is already at the top and the
/// finger keeps pulling down, the sheet follows it; past [threshold] (or on a
/// quick flick) it closes, otherwise it springs back. Tapping outside still works.
class SheetDragToClose extends StatefulWidget {
  const SheetDragToClose({super.key, required this.child, this.onClose, this.threshold = 110});

  final Widget child;

  /// Called instead of `Navigator.pop` (e.g. to confirm discarding a draft).
  final VoidCallback? onClose;
  final double threshold;

  @override
  State<SheetDragToClose> createState() => _SheetDragToCloseState();
}

class _SheetDragToCloseState extends State<SheetDragToClose> with SingleTickerProviderStateMixin {
  late final _back = AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
  double _pull = 0;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _back.addListener(() => setState(() => _pull = _pull * (1 - _back.value)));
  }

  @override
  void dispose() {
    _back.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    if (_closing) return;
    _closing = true;
    if (widget.onClose != null) {
      widget.onClose!();
    } else {
      // Respects PopScope, e.g. the composer's "discard draft?" prompt.
      await Navigator.of(context).maybePop();
    }
    // Still here (the close was declined): spring back.
    if (mounted) {
      _closing = false;
      _springBack();
    }
  }

  void _springBack() {
    if (_pull > 0) _back.forward(from: 0).whenComplete(() => _pull = 0);
  }

  void _release(double velocity) {
    if (_pull > widget.threshold || velocity > 900) {
      _close();
    } else {
      _springBack();
    }
  }

  bool _onScroll(ScrollNotification n) {
    if (n.metrics.axis != Axis.vertical) return false;
    if (n is OverscrollNotification && n.dragDetails != null && n.overscroll < 0) {
      // Android-style clamping: pulling down past the top.
      _back.stop();
      setState(() => _pull += -n.overscroll);
    } else if (n is ScrollUpdateNotification && n.dragDetails != null) {
      if (n.metrics.pixels < n.metrics.minScrollExtent) {
        // iOS-style bouncing: track the overscroll directly.
        _back.stop();
        setState(() => _pull = n.metrics.minScrollExtent - n.metrics.pixels);
      } else if (_pull > 0 && (n.scrollDelta ?? 0) > 0) {
        // Finger moved back up: shrink the pull first.
        setState(() => _pull = (_pull - n.scrollDelta!).clamp(0, double.infinity));
      }
    } else if (n is ScrollEndNotification) {
      _release(n.dragDetails?.velocity.pixelsPerSecond.dy ?? 0);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: GestureDetector(
        // Non-scrolling parts (headers, short sheets) drag the sheet directly.
        onVerticalDragUpdate: (d) {
          if (d.delta.dy > 0 || _pull > 0) setState(() => _pull = (_pull + d.delta.dy).clamp(0, double.infinity));
        },
        onVerticalDragEnd: (d) => _release(d.velocity.pixelsPerSecond.dy),
        child: Transform.translate(offset: Offset(0, _pull), child: widget.child),
      ),
    );
  }
}
