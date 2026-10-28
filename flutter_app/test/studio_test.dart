import 'dart:convert';
import 'dart:ui' as ui;
import 'package:bikinmerch/core/models.dart';
import 'package:bikinmerch/studio/project.dart';
import 'package:bikinmerch/studio/renderer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'web project JSON round-trips both sides without changing the schema',
    () {
      final original = {
        'fit': 'regular',
        'shirt': '#252525',
        'activeSide': 'back',
        'sides': {
          'front': {
            'enabled': true,
            'template': 'bloom',
            'title': 'BLOOM',
            'subtitle': 'IN YOUR OWN TIME',
            'detail': 'NO RUSH. JUST GROW.',
            'ink': '#913e41',
            'accent': '#ed9584',
            'font': 'serif',
            'position': 'chest',
            'scale': 75,
            'logo': null,
          },
          'back': {
            'enabled': true,
            'template': 'running',
            'title': 'SUNDAY',
            'subtitle': 'RUN CLUB',
            'detail': 'YOUR PACE. YOUR PEOPLE.',
            'ink': '#293829',
            'accent': '#81a82c',
            'font': 'sans',
            'position': 'large',
            'scale': 120,
            'logo': null,
          },
        },
      };
      final restored = DesignProject.fromJson(
        object(jsonDecode(jsonEncode(original))),
      );
      expect(restored.toJson(), original);
      expect(restored.copy().toJson(), original);
      expect(
        () => DesignProject.fromJson({'objects': []}),
        throwsFormatException,
      );
    },
  );
  test(
    'undo/redo isolate side changes and invalidate redo after a new edit',
    () {
      final editor = StudioController();
      editor.mutate((p) => p.front.title = 'FIRST');
      editor.selectSide('back');
      editor.mutate((p) => p.back.apply(templates.last));
      editor.undo();
      expect(editor.project.back.enabled, false);
      expect(editor.project.front.title, 'FIRST');
      editor.redo();
      expect(editor.project.back.template, 'good');
      expect(editor.project.back.enabled, true);
      editor.undo();
      editor.mutate((p) => p.shirt = '#000000');
      expect(editor.canRedo, false);
      final revision = editor.revision;
      editor.mutate((p) => p.front.detail = 'NEW');
      editor.markSaved('d1', revision);
      expect(editor.dirty, true);
      editor.markSaved('d1', editor.revision);
      expect(editor.dirty, false);
      editor.dispose();
    },
  );
  test(
    'PNG exports have exact dimensions and transparent artwork background',
    () async {
      final renderer = StudioRenderer();
      final project = DesignProject();
      for (final (type, width, height) in [
        ('artwork', 2400, 3000),
        ('mockup', 1000, 1100),
        ('combined', 2000, 1100),
      ]) {
        final bytes = await renderer.export(
          project,
          'Classic T-shirt',
          type: type,
        );
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        expect(frame.image.width, width);
        expect(frame.image.height, height);
        if (type == 'artwork') {
          final pixels = await frame.image.toByteData();
          expect(pixels!.getUint8(3), 0);
        }
        frame.image.dispose();
        codec.dispose();
      }
      renderer.dispose();
    },
  );
  test('all templates and product mockups render on both sides', () async {
    final renderer = StudioRenderer();
    await renderer.load();
    for (final template in templates) {
      final p = DesignProject()
        ..front.apply(template)
        ..back.apply(template);
      for (final name in [
        'Everyday Hoodie',
        'Canvas Tote Bag',
        'Mug Keramik',
        'Notebook A5',
      ]) {
        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);
        renderer.mockup(canvas, const ui.Size(1000, 1100), p, 'back', name);
        final picture = recorder.endRecording();
        picture.dispose();
      }
    }
    renderer.dispose();
  });
}
