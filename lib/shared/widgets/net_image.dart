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
        placeholder: (_, _) => _placeholder(loading: true),
        errorWidget: (_, _, _) => _placeholder(),
      );
    }
    if (radius > 0) child = ClipRRect(borderRadius: BorderRadius.circular(radius), child: child);
    return child;
  }

  Uint8List? _decode(String s) {
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
