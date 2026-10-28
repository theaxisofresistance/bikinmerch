import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

Future<void> exportPng(
  BuildContext context,
  Uint8List bytes,
  String name,
) async {
  final mobile =
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
  if (kIsWeb || mobile) {
    final box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(bytes, mimeType: 'image/png')],
        fileNameOverrides: [name],
        sharePositionOrigin: box == null
            ? const Rect.fromLTWH(0, 0, 1, 1)
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  } else {
    final location = await getSaveLocation(
      suggestedName: name,
      acceptedTypeGroups: const [
        XTypeGroup(
          label: 'PNG',
          extensions: ['png'],
          uniformTypeIdentifiers: ['public.png'],
        ),
      ],
    );
    if (location != null) {
      await XFile.fromData(bytes, mimeType: 'image/png').saveTo(location.path);
    }
  }
}
