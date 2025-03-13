import 'dart:js_interop';


@JS('setupMadari')
external set _setupMadari(JSFunction f);

void setupMadari(JSString baseURL) {
}

void main() {
  _setupMadari = setupMadari.toJS;
}
