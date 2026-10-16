import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Backend accepts media fields up to 2,000,000 chars (and 8 MB per request).
const maxDataUrlLength = 1900000;

/// Picks an image from camera/gallery, compresses it and returns a
/// `data:image/jpeg;base64,...` string the API accepts in `mediaUrl`,
/// `avatar`, `coverPhoto`, `photo` and `attachmentUrl`.
///
/// Returns null if the user cancels. Throws [ImageTooLargeException] if even
/// the smallest compression is over the limit.
Future<String?> pickImageAsDataUrl(
  BuildContext context, {
  int maxSide = 1280,
}) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(
          leading: const Icon(LucideIcons.camera),
          title: const Text('ক্যামেরা দিয়ে ছবি তুলুন'),
          onTap: () => Navigator.pop(ctx, ImageSource.camera),
        ),
        ListTile(
          leading: const Icon(LucideIcons.image),
          title: const Text('গ্যালারি থেকে নির্বাচন করুন'),
          onTap: () => Navigator.pop(ctx, ImageSource.gallery),
        ),
        const SizedBox(height: 8),
      ]),
    ),
  );
  if (source == null) return null;

  final file = await ImagePicker().pickImage(source: source, maxWidth: maxSide * 2.0, maxHeight: maxSide * 2.0);
  if (file == null) return null;
  final raw = await file.readAsBytes();
  return compressToDataUrl(raw, maxSide: maxSide);
}

Future<String> compressToDataUrl(Uint8List raw, {int maxSide = 1280}) async {
  for (final (side, quality) in [(maxSide, 80), (maxSide, 60), (960, 55), (720, 50), (540, 45)]) {
    final out = await FlutterImageCompress.compressWithList(
      raw,
      minWidth: side,
      minHeight: side,
      quality: quality,
      format: CompressFormat.jpeg,
    );
    final url = 'data:image/jpeg;base64,${base64Encode(out)}';
    if (url.length <= maxDataUrlLength) return url;
  }
  throw ImageTooLargeException();
}

class ImageTooLargeException implements Exception {
  @override
  String toString() => 'ছবিটি অনেক বড়। অন্য একটি ছবি নির্বাচন করুন।';
}
