import 'dart:js_interop';

import 'package:pocketbase/pocketbase.dart';

@JS('setupMadari')
external set _setupMadari(JSFunction f);

void setupMadari(JSString baseURL) {
  final pb = PocketBase(baseURL.toDart);
}

void main() {
  _setupMadari = setupMadari.toJS;
}
