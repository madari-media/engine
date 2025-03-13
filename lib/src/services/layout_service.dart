import 'dart:async';

import 'package:logging/logging.dart';
import 'package:madari_engine/madari_engine.dart';
import 'package:madari_engine/src/services/addon_service.dart';
import 'package:madari_engine/src/services/profile_service.dart';
import 'package:madari_engine/src/types/madari_service.dart';
import 'package:pocketbase/pocketbase.dart';

import 'layout_service/types.dart';

class LayoutService extends MadariService {
  final _logger = Logger('ListService');
  final ProfileService profileService;
  final AddonService addonService;

  final Map<String, List<HomeLayout>> _cache = {};

  LayoutService({
    required super.pb,
    required this.profileService,
    required this.addonService,
  });

  Future<List<HomeLayout>> getHomeLayout() async {
    final profileId = (await profileService.getCurrentProfile())?.id;
    if (profileId == null) {
      throw Exception("No profile selected");
    }

    if (_cache.containsKey(profileId)) {
      return _cache[profileId]!;
    }

    final [list, addons] = await Future.wait([
      profileService.pb.collection("home_layout").getFullList(
            filter:
                "profiles = '${(await profileService.getCurrentProfile())!.id}'",
            sort: "order",
          ),
      addonService.getAddons(onlyEnabled: true),
    ]);

    final result = (list as List<RecordModel>)
        .map((item) {
          final config = item.get("config");

          if (item.getStringValue("pluginId") != "stremio_catalog" ||
              item.getStringValue("type") != "catalog_grid") {
            return HomeLayout(
              id: item.id,
              config: config,
              order: item.getIntValue("order"),
              pluginId: item.getStringValue("plugin_id"),
              title: item.getStringValue("title"),
              type: item.getStringValue("type"),
            );
          }

          if (config is! Map<String, dynamic>) {
            return null;
          }

          if (config.containsKey("addon_id")) {
            // Backward compatibility
            final addon =
                (addons as List<PocketBaseStremioAddon>).where((item) {
              if (config.containsKey("addon")) {
                return item.url == config["addon"];
              }
              return false;
            });

            if (addon.isEmpty) {
              return null;
            }

            config["addon_id"] = addon.first.id;
          }

          return HomeLayout(
            id: item.id,
            config: config,
            order: item.getIntValue("order"),
            pluginId: item.getStringValue("plugin_id"),
            title: item.getStringValue("title"),
            type: item.getStringValue("type"),
          );
        })
        .whereType<HomeLayout>()
        .toList();

    _cache[profileId] = result;

    return result;
  }

  @override
  dispose() {}

  @override
  FutureOr<void> setup() {}
}
