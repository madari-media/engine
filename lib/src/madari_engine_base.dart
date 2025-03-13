import 'package:madari_engine/src/services/addon_service.dart';
import 'package:madari_engine/src/services/auth_service.dart';
import 'package:madari_engine/src/services/catalog_service.dart';
import 'package:madari_engine/src/services/explore_service.dart';
import 'package:madari_engine/src/services/list_service.dart';
import 'package:madari_engine/src/services/profile_service.dart';
import 'package:pocketbase/pocketbase.dart';

export './services/addon_service/types.dart';
export './services/catalog_service/types.dart';
export './services/list_service/index.dart';
export './services/profile_service/types.dart';

class MadariEngine {
  late final PocketBase _pb;
  late final AuthService authService;
  late final AddonService addonService;
  late final CatalogService catalogService;
  late final ExploreService exploreService;
  late final ProfileService profileService;
  late final ListService listService;

  MadariEngine({
    required PocketBase pb,
  }) {
    _pb = pb;
    authService = AuthService(pb: pb);
    authService.setup();
    addonService = AddonService(pb: pb);
    addonService.setup();
    catalogService = CatalogService(
      pb: pb,
      addonService: addonService,
      authService: authService,
    );
    catalogService.setup();
    exploreService = ExploreService(
      pb: pb,
      addonService: addonService,
    );
    exploreService.setup();
    profileService = ProfileService(pb: pb);
    profileService.setup();
    listService = ListService(pb: pb, profileService: profileService);
    listService.setup();
  }

  dispose() {
    authService.dispose();
    addonService.dispose();
    catalogService.dispose();
    exploreService.dispose();
    profileService.dispose();
    listService.dispose();
  }
}
