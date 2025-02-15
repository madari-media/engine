import 'dart:js_interop';

import 'package:madari_engine/src/services/addon_service.dart';
import 'package:madari_engine/src/services/auth_service.dart';
import 'package:madari_engine/src/services/catalog_service.dart';
import 'package:madari_engine/src/services/explore_service.dart';
import 'package:madari_engine/src/services/list_service.dart';
import 'package:madari_engine/src/services/profile_service.dart';
import 'package:pocketbase/pocketbase.dart';

@JS('MadariEngine')
class MadariEngine {
  final PocketBase pb;
  late final AuthService authService;
  late final AddonService addonService;
  late final CatalogService catalogService;
  late final ExploreService exploreService;
  late final ProfileService profileService;
  late final ListService listService;

  MadariEngine({
    required this.pb,
  }) {
    authService = AuthService(pb: pb);
    addonService = AddonService(pb: pb);
    catalogService = CatalogService(
      pb: pb,
      addonService: addonService,
      authService: authService,
    );
    exploreService = ExploreService(
      pb: pb,
      addonService: addonService,
    );
    profileService = ProfileService(pb: pb);
    listService = ListService(pb: pb, profileService: profileService);
  }
}
