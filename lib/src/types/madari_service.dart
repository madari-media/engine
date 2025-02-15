import 'dart:async';

import 'package:pocketbase/pocketbase.dart';

abstract class MadariService {
  final PocketBase pb;

  MadariService({
    required this.pb,
  });

  FutureOr<void> setup();
  dispose();
}
