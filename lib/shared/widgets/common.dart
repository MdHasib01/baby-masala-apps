import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/bn_digits.dart';

// ---------------------------------------------------------------- Text --

TextStyle ts(double size, {FontWeight weight = FontWeight.w400, Color? color, double? height}) =>
    TextStyle(fontSize: size, fontWeight: weight, color: color ?? AppColors.ink, height: height);

const bold = FontWeight.w700;
const semi = FontWeight.w600;

// ------------------------------------------------------------ Feedback --

void toast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));
}

void toastError(BuildContext context, Object err) =>
    toast(context, err is ApiException ? err.message : (err is Exception ? err.toString() : errorMessage(err)));

Future<bool> confirmDialog(
  BuildContext context,
  String message, {
  String confirm = 'হ্যাঁ',
  String cancel = 'বাতিল',
  bool danger = false,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      content: Text(message, style: ts(14, weight: semi)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(cancel)),
        ElevatedButton(
          style: danger ? ElevatedButton.styleFrom(backgroundColor: AppColors.red600) : null,
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirm),
        ),
      ],
    ),
  );
  return ok ?? false;
}

Future<void> alertDialog(BuildContext context, String message) => showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(message, style: ts(14, weight: semi)),
        actions: [ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('ঠিক আছে'))],
      ),
    );

// ------------------------------------------------------------- Pieces --

class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.onTap, this.color});

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color ?? Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.sandA(0.55)),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Rounded pill used for filters (topic chips, categories, age groups…).
class PillChip extends StatelessWidget {
  const PillChip({super.key, required this.label, required this.selected, required this.onTap, this.icon});

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? AppColors.maroon : Colors.white,
        shape: StadiumBorder(side: BorderSide(color: selected ? AppColors.maroon : AppColors.sand)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (icon != null) ...[
                Icon(icon, size: 13, color: selected ? Colors.white : AppColors.maroon),
                const SizedBox(width: 5),
              ],
              Text(label,
                  style: ts(12, weight: semi, color: selected ? Colors.white : AppColors.ink.withValues(alpha: 0.8))),
            ]),
          ),
        ),
      ),
    );
  }
}

class ChipRow extends StatelessWidget {
  const ChipRow({super.key, required this.children, this.padding = const EdgeInsets.symmetric(horizontal: 16)});
  final List<Widget> children;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) =>
      SingleChildScrollView(scrollDirection: Axis.horizontal, padding: padding, child: Row(children: children));
}

class Tag extends StatelessWidget {
  const Tag(this.text, {super.key, this.bg = AppColors.sand, this.fg = AppColors.maroon, this.icon});
  final String text;
  final Color bg;
  final Color fg;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Icon(icon, size: 11, color: fg), const SizedBox(width: 3)],
          Text(text, style: ts(10, weight: bold, color: fg)),
        ]),
      );
}

/// Red count bubble used on header icons and the Shop tab.
class CountBadge extends StatelessWidget {
  const CountBadge({super.key, required this.count, required this.child, this.color = AppColors.red600});
  final int count;
  final Widget child;
  final Color color;

  @override
  Widget build(BuildContext context) => Stack(clipBehavior: Clip.none, children: [
        child,
        if (count > 0)
          Positioned(
            right: -6,
            top: -6,
            child: Container(
              constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white, width: 1.5)),
              alignment: Alignment.center,
              child: Text(toBnDigits(count > 99 ? '99+' : count), style: ts(9, weight: bold, color: Colors.white)),
            ),
          ),
      ]);
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.icon, this.trailing});
  final String text;
  final IconData? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(children: [
        if (icon != null) ...[Icon(icon, size: 16, color: AppColors.maroon), const SizedBox(width: 6)],
        Expanded(child: Text(text, style: ts(14, weight: bold, color: AppColors.maroon))),
        ?trailing,
      ]);
}

class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6, top: 4),
        child: Text(text, style: ts(12, weight: bold, color: AppColors.ink.withValues(alpha: 0.85))),
      );
}

class ErrorBox extends StatelessWidget {
  const ErrorBox(this.message, {super.key});
  final String message;
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.red50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.red600.withValues(alpha: 0.3)),
        ),
        child: Text(message, style: ts(12, weight: semi, color: AppColors.red600)),
      );
}

class InfoBox extends StatelessWidget {
  const InfoBox(this.message, {super.key, this.icon = LucideIcons.circleAlert, this.bg = AppColors.amber50, this.fg = AppColors.amber800});
  final String message;
  final IconData icon;
  final Color bg;
  final Color fg;
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: fg.withValues(alpha: 0.2))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 15, color: fg),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: ts(11, color: fg, height: 1.5))),
        ]),
      );
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, this.message, this.action});
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: AppColors.sandA(0.4), shape: BoxShape.circle),
            child: Icon(icon, color: AppColors.maroon, size: 30),
          ),
          const SizedBox(height: 14),
          Text(title, textAlign: TextAlign.center, style: ts(14, weight: bold, color: AppColors.maroon)),
          if (message != null) ...[
            const SizedBox(height: 6),
            Text(message!, textAlign: TextAlign.center, style: ts(12, color: AppColors.grey600, height: 1.5)),
          ],
          if (action != null) ...[const SizedBox(height: 16), action!],
        ]),
      );
}

/// Button that shows a spinner while [onPressed] runs and disables itself.
class BusyButton extends StatefulWidget {
  const BusyButton({super.key, required this.label, required this.onPressed, this.busyLabel, this.icon, this.color, this.expand = true});

  final String label;
  final String? busyLabel;
  final Future<void> Function()? onPressed;
  final IconData? icon;
  final Color? color;
  final bool expand;

  @override
  State<BusyButton> createState() => _BusyButtonState();
}

class _BusyButtonState extends State<BusyButton> {
  bool _busy = false;

  Future<void> _run() async {
    if (_busy || widget.onPressed == null) return;
    setState(() => _busy = true);
    try {
      await widget.onPressed!();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final btn = ElevatedButton(
      style: widget.color != null ? ElevatedButton.styleFrom(backgroundColor: widget.color) : null,
      onPressed: widget.onPressed == null || _busy ? null : _run,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (_busy)
          const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
        else if (widget.icon != null)
          Icon(widget.icon, size: 16),
        if (_busy || widget.icon != null) const SizedBox(width: 8),
        Flexible(child: Text(_busy ? (widget.busyLabel ?? widget.label) : widget.label, overflow: TextOverflow.ellipsis)),
      ]),
    );
    return widget.expand ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}

/// Brand logo icon.
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 36,
    this.border = true,
  });

  final double size;
  final bool border;

  @override
  Widget build(BuildContext context) {
    final img = Image.asset(
      'assets/images/logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
    if (!border) return img;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.sandA(0.6), width: 1.5),
      ),
      child: ClipOval(child: img),
    );
  }
}

/// Brand wordmark: "Baby Care" + "by Baby Masala", optionally accompanied by the logo icon.
class Wordmark extends StatelessWidget {
  const Wordmark({
    super.key,
    this.size = 18,
    this.light = false,
    this.center = false,
    this.withLogo = false,
    this.logoSize,
  });

  final double size;
  final bool light;
  final bool center;
  final bool withLogo;
  final double? logoSize;

  @override
  Widget build(BuildContext context) {
    final textColumn = Column(
      crossAxisAlignment: center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Baby Care', style: ts(size, weight: FontWeight.w800, color: light ? Colors.white : AppColors.maroon, height: 1.1)),
        Text('BY BABY MASALA',
            style: TextStyle(
              fontSize: size * 0.48,
              fontWeight: bold,
              letterSpacing: 1.4,
              color: light ? AppColors.sand : AppColors.olive,
            )),
      ],
    );

    if (!withLogo) return textColumn;

    final effectiveLogoSize = logoSize ?? (size * 1.6);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AppLogo(size: effectiveLogoSize),
        const SizedBox(width: 8),
        textColumn,
      ],
    );
  }
}

/// Small rounded grab handle for sheets that set `showDragHandle: false`.
class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});
  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          margin: const EdgeInsets.only(top: 10, bottom: 6),
          width: 40,
          height: 4,
          decoration: BoxDecoration(color: AppColors.sand, borderRadius: BorderRadius.circular(4)),
        ),
      );
}

/// Round tonal icon button used in the top bar (messenger, bell, …).
class TonalIconButton extends StatelessWidget {
  const TonalIconButton({super.key, required this.icon, required this.onPressed, this.badge = 0, this.tooltip});
  final IconData icon;
  final VoidCallback onPressed;
  final int badge;
  final String? tooltip;

  @override
  Widget build(BuildContext context) => CountBadge(
        count: badge,
        child: IconButton.filledTonal(
          tooltip: tooltip,
          style: IconButton.styleFrom(backgroundColor: Colors.white, side: BorderSide(color: AppColors.sandA(0.7))),
          onPressed: onPressed,
          icon: Icon(icon, size: 20, color: AppColors.maroon),
        ),
      );
}

/// Sheet with a title row and a close button; used for every modal.
Future<T?> showAppSheet<T>(BuildContext context, {required String title, required WidgetBuilder builder, bool scroll = true}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: false,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.92),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SheetHandle(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 8, 4),
            child: Row(children: [
              Expanded(child: Text(title, style: ts(17, weight: bold, color: AppColors.maroon))),
              IconButton.filledTonal(
                style: IconButton.styleFrom(backgroundColor: AppColors.sandA(0.35)),
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(LucideIcons.x, size: 18, color: AppColors.maroon),
              ),
            ]),
          ),
          Flexible(
            child: scroll
                ? SingleChildScrollView(padding: const EdgeInsets.fromLTRB(20, 14, 20, 24), child: builder(ctx))
                : builder(ctx),
          ),
        ]),
      ),
    ),
  );
}
