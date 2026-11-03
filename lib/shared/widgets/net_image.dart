import 'dart:convert';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_colors.dart';

/// Shows an image from an http(s) URL or a `data:image/...;base64,` URL
/// (what the mobile app uploads and the web app can also store).
class NetImage extends StatelessWidget {
  const NetImage(
    this.src, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.radius = 0,
    this.placeholderIcon = LucideIcons.image,
  });

  final String? src;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double radius;
  final IconData placeholderIcon;

  static final Map<String, Uint8List> _decoded = {};

  @override
  Widget build(BuildContext context) {
    final s = src?.trim() ?? '';
    Widget child;
    if (s.isEmpty) {
      child = _placeholder();
    } else if (s.startsWith('data:')) {
      final bytes = _decode(s);
      child = bytes == null
          ? _placeholder()
          : Image.memory(bytes, width: width, height: height, fit: fit, gaplessPlayback: true);
    } else {
      child = CachedNetworkImage(
        imageUrl: s,
        width: width,
        height: height,
        fit: fit,
        // No fade: opacity animations glitch on the emulator's Impeller backend.
        fadeInDuration: Duration.zero,
        fadeOutDuration: Duration.zero,
        placeholder: (_, _) => _placeholder(loading: true),
        errorWidget: (_, _, _) => _placeholder(),
      );
    }
    if (radius > 0) child = ClipRRect(borderRadius: BorderRadius.circular(radius), child: child);
    return child;
  }

  Uint8List? _decode(String s) => decodeDataUrl(s);

  /// Decodes (and caches) a `data:...;base64,` URL.
  static Uint8List? decodeDataUrl(String s) {
    final hit = _decoded[s];
    if (hit != null) return hit;
    final comma = s.indexOf(',');
    if (comma < 0) return null;
    try {
      final bytes = base64Decode(s.substring(comma + 1));
      if (_decoded.length > 40) _decoded.clear();
      return _decoded[s] = bytes;
    } catch (_) {
      return null;
    }
  }

  Widget _placeholder({bool loading = false}) => Container(
        width: width,
        height: height,
        color: AppColors.sandA(0.25),
        alignment: Alignment.center,
        child: loading
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.sand))
            : Icon(placeholderIcon, color: AppColors.maroon.withValues(alpha: 0.35), size: 20),
      );
}

/// Single post image sized like Facebook's feed: full width at the photo's
/// own aspect ratio, clamped between 4:5 (tallest portrait) and 1.91:1
/// (widest landscape). Anything outside that range is center-cropped.
class FeedImage extends StatefulWidget {
  const FeedImage(this.src, {super.key, this.radius = 0, this.onTap});

  final String? src;
  final double radius;
  final VoidCallback? onTap;

  static const double tallest = 4 / 5;
  static const double widest = 1.91;

  /// Resolved ratios by URL so cards don't jump when scrolled back into view.
  static final Map<String, double> _ratios = {};

  @override
  State<FeedImage> createState() => _FeedImageState();
}

class _FeedImageState extends State<FeedImage> {
  ImageStream? _stream;
  ImageStreamListener? _listener;
  double? _ratio;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(FeedImage old) {
    super.didUpdateWidget(old);
    if (old.src != widget.src) {
      _detach();
      _ratio = null;
      _resolve();
    }
  }

  void _resolve() {
    final s = widget.src?.trim() ?? '';
    if (s.isEmpty) return;
    final cached = FeedImage._ratios[s];
    if (cached != null) {
      _ratio = cached;
      return;
    }
    ImageProvider provider;
    if (s.startsWith('data:')) {
      final bytes = NetImage.decodeDataUrl(s);
      if (bytes == null) return;
      provider = MemoryImage(bytes);
    } else {
      provider = CachedNetworkImageProvider(s);
    }
    _listener = ImageStreamListener((info, _) {
      final w = info.image.width, h = info.image.height;
      if (w > 0 && h > 0) {
        final r = w / h;
        FeedImage._ratios[s] = r;
        if (mounted) setState(() => _ratio = r);
      }
      _detach();
    }, onError: (_, _) => _detach());
    _stream = provider.resolve(ImageConfiguration.empty)..addListener(_listener!);
  }

  void _detach() {
    if (_stream != null && _listener != null) _stream!.removeListener(_listener!);
    _stream = null;
    _listener = null;
  }

  @override
  void dispose() {
    _detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ratio = (_ratio ?? 1).clamp(FeedImage.tallest, FeedImage.widest).toDouble();
    final img = AspectRatio(
      aspectRatio: ratio,
      child: NetImage(widget.src, width: double.infinity, height: double.infinity, radius: widget.radius),
    );
    return widget.onTap == null ? img : GestureDetector(onTap: widget.onTap, child: img);
  }
}

/// Circular avatar with optional ring.
class AppAvatar extends StatelessWidget {
  const AppAvatar(this.src, {super.key, this.size = 40, this.ring = true, this.onTap});

  final String? src;
  final double size;
  final bool ring;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final img = ClipOval(
      child: NetImage(src, width: size, height: size, placeholderIcon: LucideIcons.user),
    );
    final w = Container(
      width: size,
      height: size,
      decoration: ring
          ? BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.sand, width: 2))
          : null,
      child: img,
    );
    return onTap == null ? w : GestureDetector(onTap: onTap, child: w);
  }
}
