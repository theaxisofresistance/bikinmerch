import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../core/models.dart';

class DesignTemplate {
  const DesignTemplate(
    this.id,
    this.name,
    this.category,
    this.title,
    this.subtitle,
    this.detail,
    this.ink,
    this.accent,
    this.background,
  );
  final String id,
      name,
      category,
      title,
      subtitle,
      detail,
      ink,
      accent,
      background;
}

const templates = [
  DesignTemplate(
    'weekend',
    'Weekend Society',
    'Komunitas',
    'WEEKEND',
    'SOCIETY',
    'GOOD PEOPLE. GREAT DAYS.',
    '#294f36',
    '#b1cf6d',
    '#e4ead9',
  ),
  DesignTemplate(
    'afterhours',
    'After Hours',
    'Event',
    'AFTER',
    'HOURS',
    'MUSIC • PEOPLE • MEMORIES',
    '#39216b',
    '#fa724a',
    '#dddcef',
  ),
  DesignTemplate(
    'ordinary',
    'Less, But Better',
    'Brand',
    'ordinary.',
    'STUFF WITH SOUL',
    'EST. 2026 / JAKARTA',
    '#342f2a',
    '#bd744e',
    '#ece5db',
  ),
  DesignTemplate(
    'running',
    'Sunday Run Club',
    'Komunitas',
    'SUNDAY',
    'RUN CLUB',
    'YOUR PACE. YOUR PEOPLE.',
    '#293829',
    '#81a82c',
    '#e6ecc7',
  ),
  DesignTemplate(
    'bloom',
    'In My Own Time',
    'Personal',
    'BLOOM',
    'IN YOUR OWN TIME',
    'NO RUSH. JUST GROW.',
    '#913e41',
    '#ed9584',
    '#f0deda',
  ),
  DesignTemplate(
    'good',
    'Good Things Ahead',
    'Personal',
    'GOOD',
    'THINGS AHEAD',
    'TAKE IT ONE DAY AT A TIME',
    '#1c5068',
    '#e9a640',
    '#dce8ee',
  ),
];
const palettes = [
  ['#294f36', '#b1cf6d'],
  ['#242424', '#f4eee1'],
  ['#39216b', '#fa724a'],
  ['#913e41', '#ed9584'],
  ['#f4eee1', '#c6f34b'],
];
const shirtColors = [
  ['#f5f3ea', 'Putih tulang'],
  ['#27292a', 'Hitam'],
  ['#a5af8e', 'Sage'],
  ['#aab9ca', 'Biru'],
  ['#eee0c9', 'Sand'],
];

class DesignSide {
  DesignSide({
    this.enabled = true,
    this.template = 'weekend',
    this.title = 'WEEKEND',
    this.subtitle = 'SOCIETY',
    this.detail = 'GOOD PEOPLE. GREAT DAYS.',
    this.ink = '#294f36',
    this.accent = '#b1cf6d',
    this.font = 'condensed',
    this.position = 'center',
    this.scale = 100,
    this.logo,
  });
  factory DesignSide.fromJson(Json json) => DesignSide(
    enabled: json['enabled'] == true,
    template: textOf(json['template'], 'weekend'),
    title: textOf(json['title']),
    subtitle: textOf(json['subtitle']),
    detail: textOf(json['detail']),
    ink: textOf(json['ink'], '#294f36'),
    accent: textOf(json['accent'], '#b1cf6d'),
    font: textOf(json['font'], 'condensed'),
    position: textOf(json['position'], 'center'),
    scale: number(json['scale']).clamp(60, 120),
    logo: json['logo'] as String?,
  );
  bool enabled;
  String template, title, subtitle, detail, ink, accent, font, position;
  int scale;
  String? logo;
  Json toJson() => {
    'enabled': enabled,
    'template': template,
    'title': title,
    'subtitle': subtitle,
    'detail': detail,
    'ink': ink,
    'accent': accent,
    'font': font,
    'position': position,
    'scale': scale,
    'logo': logo,
  };
  void apply(DesignTemplate value) {
    enabled = true;
    template = value.id;
    title = value.title;
    subtitle = value.subtitle;
    detail = value.detail;
    ink = value.ink;
    accent = value.accent;
  }
}

class DesignProject {
  DesignProject({
    this.fit = 'oversized',
    this.shirt = '#f4f1eb',
    this.activeSide = 'front',
    DesignSide? front,
    DesignSide? back,
  }) : front = front ?? DesignSide(),
       back = back ?? DesignSide(enabled: false, position: 'large');
  factory DesignProject.fromJson(Json json) {
    final sides = object(json['sides']);
    if (sides['front'] is! Map || sides['back'] is! Map) {
      throw const FormatException('Format desain tidak didukung.');
    }
    return DesignProject(
      fit: textOf(json['fit'], 'oversized'),
      shirt: textOf(json['shirt'], '#f4f1eb'),
      activeSide: json['activeSide'] == 'back' ? 'back' : 'front',
      front: DesignSide.fromJson(object(sides['front'])),
      back: DesignSide.fromJson(object(sides['back'])),
    );
  }
  String fit, shirt, activeSide;
  DesignSide front, back;
  DesignSide get active => side(activeSide);
  DesignSide side(String side) => side == 'back' ? back : front;
  Json toJson() => {
    'fit': fit,
    'shirt': shirt,
    'activeSide': activeSide,
    'sides': {'front': front.toJson(), 'back': back.toJson()},
  };
  DesignProject copy() =>
      DesignProject.fromJson(object(jsonDecode(jsonEncode(toJson()))));
}

class StudioController extends ChangeNotifier {
  DesignProject project = DesignProject();
  String name = 'Desain tanpa judul';
  String? savedId;
  bool dirty = false;
  int revision = 0;
  final List<DesignProject> _history = [], _future = [];
  bool get canUndo => _history.isNotEmpty;
  bool get canRedo => _future.isNotEmpty;
  void mutate(void Function(DesignProject) change) {
    _history.add(project.copy());
    if (_history.length > 50) _history.removeAt(0);
    _future.clear();
    project = project.copy();
    change(project);
    dirty = true;
    revision++;
    notifyListeners();
  }

  void rename(String value) {
    name = value;
    dirty = true;
    revision++;
    notifyListeners();
  }

  void selectSide(String side) {
    project.activeSide = side;
    notifyListeners();
  }

  void undo() {
    if (!canUndo) return;
    _future.add(project.copy());
    project = _history.removeLast();
    dirty = true;
    revision++;
    notifyListeners();
  }

  void redo() {
    if (!canRedo) return;
    _history.add(project.copy());
    project = _future.removeLast();
    dirty = true;
    revision++;
    notifyListeners();
  }

  void load(DesignProject value, {String? id, String? title}) {
    project = value.copy();
    savedId = id;
    if (title != null) name = title;
    dirty = false;
    revision++;
    _history.clear();
    _future.clear();
    notifyListeners();
  }

  void markSaved(String id, int savedRevision) {
    savedId = id;
    if (revision == savedRevision) dirty = false;
    notifyListeners();
  }
}
