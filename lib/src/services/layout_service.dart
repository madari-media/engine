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
    _logger.info('Getting home layout');
    final profileId = (await profileService.getCurrentProfile())?.id;
    if (profileId == null) {
      _logger.severe('No profile selected');
      throw Exception("No profile selected");
    }

    if (_cache.containsKey(profileId)) {
      _logger.fine('Returning cached home layout for profile: $profileId');
      return _cache[profileId]!;
    }

    _logger.info('Fetching home layout from database for profile: $profileId');
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
            _logger.warning('Invalid config format for item: ${item.id}');
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
              _logger.warning('No matching addon found for item: ${item.id}');
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
    _logger.info('Cached ${result.length} home layout items for profile: $profileId');

    return result;
  }

  Future<HomeLayout> createHomeLayoutItem({
    required String pluginId,
    required String type,
    required String title,
    required Map<String, dynamic> config,
    required int order,
  }) async {
    _logger.info('Creating new home layout item: $title');
    final profileId = (await profileService.getCurrentProfile())?.id;
    if (profileId == null) {
      _logger.severe('No profile selected');
      throw Exception("No profile selected");
    }

    final record = await profileService.pb.collection("home_layout").create(
      body: {
        "profiles": profileId,
        "plugin_id": pluginId,
        "type": type,
        "title": title,
        "config": config,
        "order": order,
      },
    );

    final newItem = HomeLayout(
      id: record.id,
      config: record.get("config"),
      order: record.getIntValue("order"),
      pluginId: record.getStringValue("plugin_id"),
      title: record.getStringValue("title"),
      type: record.getStringValue("type"),
    );

    // Update cache
    if (_cache.containsKey(profileId)) {
      _cache[profileId]!.add(newItem);
      _cache[profileId]!.sort((a, b) => a.order.compareTo(b.order));
      _logger.fine('Updated cache with new home layout item: ${newItem.id}');
    }

    _logger.info('Successfully created home layout item: ${newItem.id}');
    return newItem;
  }

  Future<void> updateHomeLayoutItem({
    required String id,
    String? pluginId,
    String? type,
    String? title,
    Map<String, dynamic>? config,
    int? order,
  }) async {
    _logger.info('Updating home layout item: $id');
    final profileId = (await profileService.getCurrentProfile())?.id;
    if (profileId == null) {
      _logger.severe('No profile selected');
      throw Exception("No profile selected");
    }

    final updates = <String, dynamic>{};
    if (pluginId != null) updates["plugin_id"] = pluginId;
    if (type != null) updates["type"] = type;
    if (title != null) updates["title"] = title;
    if (config != null) updates["config"] = config;
    if (order != null) updates["order"] = order;

    await profileService.pb.collection("home_layout").update(
      id,
      body: updates,
    );

    // Update cache
    if (_cache.containsKey(profileId)) {
      final index = _cache[profileId]!.indexWhere((item) => item.id == id);
      if (index != -1) {
        final updatedItem = HomeLayout(
          id: id,
          config: config ?? _cache[profileId]![index].config,
          order: order ?? _cache[profileId]![index].order,
          pluginId: pluginId ?? _cache[profileId]![index].pluginId,
          title: title ?? _cache[profileId]![index].title,
          type: type ?? _cache[profileId]![index].type,
        );
        _cache[profileId]![index] = updatedItem;
        _cache[profileId]!.sort((a, b) => a.order.compareTo(b.order));
        _logger.fine('Updated cache for home layout item: $id');
      }
    }

    _logger.info('Successfully updated home layout item: $id');
  }

  Future<void> deleteHomeLayoutItem(String id) async {
    _logger.info('Deleting home layout item: $id');
    final profileId = (await profileService.getCurrentProfile())?.id;
    if (profileId == null) {
      _logger.severe('No profile selected');
      throw Exception("No profile selected");
    }

    await profileService.pb.collection("home_layout").delete(id);

    // Update cache
    if (_cache.containsKey(profileId)) {
      _cache[profileId]!.removeWhere((item) => item.id == id);
      _logger.fine('Removed item from cache: $id');
    }

    _logger.info('Successfully deleted home layout item: $id');
  }

  Future<void> reorderHomeLayoutItems(List<String> orderedIds) async {
    _logger.info('Reordering home layout items');
    final profileId = (await profileService.getCurrentProfile())?.id;
    if (profileId == null) {
      _logger.severe('No profile selected');
      throw Exception("No profile selected");
    }

    // Update each item's order in the database
    for (var i = 0; i < orderedIds.length; i++) {
      await profileService.pb.collection("home_layout").update(
        orderedIds[i],
        body: {"order": i},
      );
    }

    // Update cache
    if (_cache.containsKey(profileId)) {
      final items = Map.fromEntries(
        _cache[profileId]!.map((item) => MapEntry(item.id, item)),
      );
      
      _cache[profileId] = orderedIds
          .map((id) => items[id]!.copyWith(order: orderedIds.indexOf(id)))
          .toList();
      _logger.fine('Updated cache with new order for ${orderedIds.length} items');
    }

    _logger.info('Successfully reordered home layout items');
  }

  @override
  dispose() {
    _logger.info('Disposing LayoutService');
  }

  @override
  FutureOr<void> setup() {
    _logger.info('Setting up LayoutService');
  }
}
