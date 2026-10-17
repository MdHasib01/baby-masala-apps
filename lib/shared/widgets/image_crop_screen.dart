import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/image_data_url.dart';
import 'common.dart';

/// Picks a photo, lets the user zoom / drag it inside a frame (Facebook-style),
/// and returns the cropped result as a compressed data URL. Null if cancelled.
///
/// [circle] shows a round frame (profile picture; output is still square).
/// [aspectRatio] is width / height of the frame (1 for avatars, ~2.6 for covers).
Future<String?> pickAndCropImage(
  BuildContext context, {
  double aspectRatio = 1,
  bool circle = false,
  int outputWidth = 600,
  String title = 'ছবি ঠিক করুন',
}) async {
  final raw = await pickImageBytes(context, maxSide: math.max(outputWidth * 2, 1600));
  if (raw == null || !context.mounted) return null;
  final cropped = await Navigator.of(context).push<Uint8List>(MaterialPageRoute(
    fullscreenDialog: true,
    builder: (_) => ImageCropScreen(bytes: raw, aspectRatio: aspectRatio, circle: circle, outputWidth: outputWidth, title: title),
  ));
  if (cropped == null) return null;
  return compressToDataUrl(cropped, maxSide: outputWidth);
}

class ImageCropScreen extends StatefulWidget {
  const ImageCropScreen({
    super.key,
    required this.bytes,
    required this.aspectRatio,
    required this.circle,
    required this.outputWidth,
    required this.title,
  });

  final Uint8List bytes;
  final double aspectRatio;
  final bool circle;
  final int outputWidth;
  final String title;

  @override
  State<ImageCropScreen> createState() => _ImageCropScreenState();
}

class _ImageCropScreenState extends State<ImageCropScreen> {
  static const _maxZoom = 4.0;

  ui.Image? _image;
  Object? _error;
  bool _saving = false;

  // Zoom is relative to "cover" fit (1 = image just fills the frame).
  // Offset is the image centre relative to the frame centre, in screen px.
  double _zoom = 1;
  Offset _offset = Offset.zero;
  Size _frame = Size.zero;

  double _gestureZoom = 1;
  Offset _gestureOffset = Offset.zero;
  Offset _gestureFocal = Offset.zero;

  @override
  void initState() {
    super.initState();
    _decode();
  }

  Future<void> _decode() async {
    try {
      final codec = await ui.instantiateImageCodec(widget.bytes);
      final frame = await codec.getNextFrame();
      if (mounted) setState(() => _image = frame.image);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  double get _baseScale {
    final img = _image!;
    return math.max(_frame.width / img.width, _frame.height / img.height);
  }

  double get _scale => _baseScale * _zoom;

  /// Keeps the frame fully covered by the image.
  Offset _clamp(Offset o, double zoom) {
    final img = _image!;
    final s = _baseScale * zoom;
    final maxX = math.max(0.0, (img.width * s - _frame.width) / 2);
    final maxY = math.max(0.0, (img.height * s - _frame.height) / 2);
    return Offset(o.dx.clamp(-maxX, maxX), o.dy.clamp(-maxY, maxY));
  }

  void _setZoom(double zoom, {Offset? offset}) {
    final z = zoom.clamp(1.0, _maxZoom);
    // Zoom around the frame centre so the visible point stays put.
    final o = offset ?? _offset * (z / _zoom);
    setState(() {
      _zoom = z;
      _offset = _clamp(o, z);
    });
  }

  Future<void> _done() async {
    final img = _image;
    if (img == null || _saving) return;
    setState(() => _saving = true);
    try {
      final s = _scale;
      final src = Rect.fromLTWH(
        img.width / 2 - (_frame.width / 2 + _offset.dx) / s,
        img.height / 2 - (_frame.height / 2 + _offset.dy) / s,
        _frame.width / s,
        _frame.height / s,
      );
      // Never upscale beyond the source pixels.
      final outW = math.min(widget.outputWidth.toDouble(), src.width).round().clamp(1, 1 << 14);
      final outH = (outW / widget.aspectRatio).round().clamp(1, 1 << 14);

      final recorder = ui.PictureRecorder();
      Canvas(recorder).drawImageRect(
        img,
        src,
        Rect.fromLTWH(0, 0, outW.toDouble(), outH.toDouble()),
        Paint()..filterQuality = FilterQuality.high,
      );
      final out = await recorder.endRecording().toImage(outW, outH);
      final data = await out.toByteData(format: ui.ImageByteFormat.png);
      out.dispose();
      if (mounted && data != null) Navigator.of(context).pop(data.buffer.asUint8List());
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        toastError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.title, style: ts(16, weight: bold, color: Colors.white)),
        actions: [
          TextButton(
            onPressed: _image == null || _saving ? null : _done,
            child: _saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text('সম্পন্ন', style: ts(14, weight: bold, color: AppColors.sand)),
          ),
        ],
      ),
      body: _error != null
          ? Center(child: Text('ছবিটি খোলা যাচ্ছে না। অন্য একটি ছবি নির্বাচন করুন।', style: ts(13, color: Colors.white)))
          : _image == null
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : Column(children: [
                  Expanded(child: LayoutBuilder(builder: _cropArea)),
                  _controls(),
                ]),
    );
  }

  Widget _cropArea(BuildContext context, BoxConstraints c) {
    const pad = 20.0;
    var w = c.maxWidth - pad * 2;
    var h = w / widget.aspectRatio;
    if (h > c.maxHeight - pad * 2) {
      h = c.maxHeight - pad * 2;
      w = h * widget.aspectRatio;
    }
    final frame = Size(w, h);
    if (frame != _frame) {
      // First layout (or rotation): keep the current view valid for the new frame.
      _frame = frame;
      _offset = _clamp(_offset, _zoom);
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onScaleStart: (d) {
        _gestureZoom = _zoom;
        _gestureOffset = _offset;
        _gestureFocal = d.focalPoint;
      },
      onScaleUpdate: (d) {
        final z = (_gestureZoom * d.scale).clamp(1.0, _maxZoom);
        _setZoom(z, offset: _gestureOffset * (z / _gestureZoom) + (d.focalPoint - _gestureFocal));
      },
      onDoubleTap: () => _setZoom(_zoom > 1.5 ? 1 : 2),
      child: CustomPaint(
        size: Size(c.maxWidth, c.maxHeight),
        painter: _CropPainter(image: _image!, frame: frame, scale: _scale, offset: _offset, circle: widget.circle),
      ),
    );
  }

  Widget _controls() => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('আঙুল দিয়ে টেনে সরান, জুম করে সাইজ ঠিক করুন', style: ts(12, color: Colors.white70)),
            Row(children: [
              IconButton(
                onPressed: () => _setZoom(_zoom - 0.25),
                icon: const Icon(LucideIcons.zoomOut, color: Colors.white70, size: 20),
              ),
              Expanded(
                child: Slider(
                  value: _zoom,
                  min: 1,
                  max: _maxZoom,
                  activeColor: AppColors.sand,
                  inactiveColor: Colors.white24,
                  onChanged: _setZoom,
                ),
              ),
              IconButton(
                onPressed: () => _setZoom(_zoom + 0.25),
                icon: const Icon(LucideIcons.zoomIn, color: Colors.white70, size: 20),
              ),
            ]),
            TextButton.icon(
              onPressed: () => _setZoom(1, offset: Offset.zero),
              icon: const Icon(LucideIcons.rotateCcw, size: 15, color: Colors.white70),
              label: Text('রিসেট', style: ts(12, color: Colors.white70)),
            ),
          ]),
        ),
      );
}

class _CropPainter extends CustomPainter {
  _CropPainter({required this.image, required this.frame, required this.scale, required this.offset, required this.circle});

  final ui.Image image;
  final Size frame;
  final double scale;
  final Offset offset;
  final bool circle;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero) + offset;
    final dst = Rect.fromCenter(center: center, width: image.width * scale, height: image.height * scale);
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      dst,
      Paint()..filterQuality = FilterQuality.medium,
    );

    final hole = Rect.fromCenter(center: size.center(Offset.zero), width: frame.width, height: frame.height);
    final holePath = circle ? (Path()..addOval(hole)) : (Path()..addRRect(RRect.fromRectAndRadius(hole, const Radius.circular(8))));
    final shade = Path.combine(PathOperation.difference, Path()..addRect(Offset.zero & size), holePath);
    canvas.drawPath(shade, Paint()..color = Colors.black.withValues(alpha: 0.62));
    canvas.drawPath(
      holePath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withValues(alpha: 0.9),
    );
  }

  @override
  bool shouldRepaint(_CropPainter old) =>
      old.image != image || old.frame != frame || old.scale != scale || old.offset != offset || old.circle != circle;
}
