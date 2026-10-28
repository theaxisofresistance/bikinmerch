import 'dart:js_interop';
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

VoidCallback watchUnsavedChanges(bool Function() isDirty) {
  final callback = ((web.BeforeUnloadEvent event) {
    if (!isDirty()) return;
    event.preventDefault();
    event.returnValue = '';
  }).toJS;
  web.window.addEventListener('beforeunload', callback);
  return () => web.window.removeEventListener('beforeunload', callback);
}
