import 'dart:async';
import 'dart:js_interop';

import 'package:madari_engine/src/models/stremio_addons_types.dart';
import 'package:madari_engine/src/services/addon_service.dart';
import 'package:madari_engine/src/types/madari_service.dart';

@JSExport()
class ExploreService extends MadariService {
  final AddonService addonService;
  ExploreService({
    required super.pb,
    required this.addonService,
  });

  @override
  dispose() {}

  @override
  FutureOr<void> setup() {}

  Future<List<String>> getTypes() async {
    final addons = await addonService.getAddonManifest();

    final List<String> returnValue = [];

    for (final addon in addons) {
      for (final items in addon.catalogs!) {
        if (!returnValue.contains(items.type)) {
          returnValue.add(items.type);
        }
      }
    }

    return returnValue;
  }

  Future<List<ExploreCatalog>> getCatalogs(String type) async {
    final addons = await addonService.getAddonManifest();
    final List<ExploreCatalog> returnValue = [];

    for (final addon in addons) {
      if (addon.catalogs == null) {
        continue;
      }

      for (final catalog in addon.catalogs!) {
        if (catalog.type == type) {
          returnValue.add(
            ExploreCatalog(
              catalog: catalog,
              addon: addon,
            ),
          );
        }
      }
    }

    return returnValue;
  }
}

class ExploreCatalog {
  final StremioManifestCatalog catalog;
  final StremioManifest addon;

  ExploreCatalog({
    required this.catalog,
    required this.addon,
  });
}
