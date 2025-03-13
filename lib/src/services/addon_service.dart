import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:madari_engine/src/types/madari_service.dart';
import 'package:pocketbase/pocketbase.dart';

import '../models/stremio_addons_types.dart';
import 'addon_service/types.dart';

class AddonService extends MadariService {
  final Logger _logger = Logger('AuthService');
  final _addonsCache = <PocketBaseStremioAddon>[];
  late StreamSubscription<AuthStoreEvent> _onChange;
  final Map<String, StremioManifest> _addons = {};

  AddonService({
    required super.pb,
  });

  Future<StremioManifest> validateAddon(String addonUrl) async {
    addonUrl = addonUrl.replaceFirst("stremio://", "https://");

    if (_addons.containsKey(addonUrl)) {
      return _addons[addonUrl]!;
    }

    try {
      final response = await http
          .get(Uri.parse(addonUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('Failed to load manifest: ${response.statusCode}');
      }

      final manifest =
          StremioManifest.fromJson(jsonDecode(response.body), addonUrl);

      final hasRequiredResources = manifest.resources?.any((r) {
            final name = r is String ? r : r.name;
            return ['catalog', 'meta', 'stream', 'subtitles'].contains(name);
          }) ??
          false;

      if (!hasRequiredResources) {
        throw Exception(
            'Manifest must include catalog, meta, stream or subtitles resources');
      }

      _addons[addonUrl] = manifest;
      return manifest;
    } catch (e) {
      _logger.warning('Error validating addon', e);
      rethrow;
    }
  }

  Future<PocketBaseStremioAddon> saveAddon(StremioManifest manifest) async {
    try {
      final addon = PocketBaseStremioAddon(
        url: manifest.manifestUrl!,
        title: manifest.name,
        icon: manifest.icon ?? manifest.logo,
        enabled: true,
      );

      final record = await pb.collection('stremio_addons').create(
            body: addon.toJson(pb),
          );

      _addonsCache.add(addon.copyWith(
        id: record.id,
      ));

      return addon.copyWith(
        id: record.id,
      );
    } catch (e, stack) {
      _logger.warning("Error saving addon", e, stack);

      if (e is ClientException) {
        final error = e.response.values.first;
        if (error is Map && error["url"]?["code"] == "validation_not_unique") {
          throw Exception("Addon already installed. Check disabled addons.");
        }
      }
      throw Exception('Failed to save addon: $e');
    }
  }

  Future<void> _fetchAddons() async {
    try {
      if (!pb.authStore.isValid) {
        _addonsCache.clear();
        return;
      }

      final records = await pb.collection('stremio_addons').getFullList(
            filter: 'user = "${pb.authStore.record!.id}"',
            sort: "created",
          );

      _addonsCache.clear();
      _addonsCache.addAll(records.map(
        (record) => PocketBaseStremioAddon(
          id: record.id,
          url: record.data['url'],
          title: record.data['title'],
          icon: record.data['icon'],
          enabled: record.data['enabled'],
        ),
      ));
    } catch (e, stack) {
      _logger.severe("Error fetching addons", e, stack);
      throw Exception('Failed to fetch addons: $e');
    }
  }

  Future<void> uninstallAddon(String id) async {
    try {
      await pb.collection('stremio_addons').delete(id);
      _addonsCache.removeWhere((addon) => addon.id == id);
    } catch (e, stack) {
      _logger.warning("Error uninstalling addon", e, stack);
      throw Exception('Failed to uninstall addon: $e');
    }
  }

  Future<void> disableAddon(String id) async {
    try {
      await pb
          .collection('stremio_addons')
          .update(id, body: {'enabled': false});

      final index = _addonsCache.indexWhere((addon) => addon.id == id);
      if (index != -1) {
        final addon = _addonsCache[index];
        _addonsCache[index] = PocketBaseStremioAddon(
          id: addon.id,
          url: addon.url,
          title: addon.title,
          icon: addon.icon,
          enabled: false,
        );
      }
    } catch (e, stack) {
      _logger.warning("Error disabling addon", e, stack);
      throw Exception('Failed to disable addon: $e');
    }
  }

  Future<void> enableAddon(String id) async {
    try {
      await pb.collection('stremio_addons').update(id, body: {'enabled': true});

      final index = _addonsCache.indexWhere((addon) => addon.id == id);
      if (index != -1) {
        final addon = _addonsCache[index];
        _addonsCache[index] = PocketBaseStremioAddon(
          id: addon.id,
          url: addon.url,
          title: addon.title,
          icon: addon.icon,
          enabled: true,
        );
      }
    } catch (e, stack) {
      _logger.warning("Error enabling addon", e, stack);
      throw Exception('Failed to enable addon: $e');
    }
  }

  Future<List<StremioManifest>> getAddonManifest() async {
    final addons = await getAddons(onlyEnabled: true);

    return Future.wait(
      addons.map(
        (item) {
          return validateAddon(item.url);
        },
      ).toList(),
    );
  }

  Future<List<PocketBaseStremioAddon>> getAddons({
    bool onlyEnabled = true,
  }) async {
    if (_addonsCache.isEmpty) {
      await _fetchAddons();
    }
    return List.unmodifiable(
      _addonsCache.where(
        (item) {
          if (onlyEnabled) {
            return item.enabled == true;
          }

          return true;
        },
      ),
    );
  }

  Future<PocketBaseStremioAddon> getAddonById(
    String id,
  ) async {
    if (_addonsCache.isEmpty) {
      await _fetchAddons();
    }

    return _addonsCache.firstWhere((item) => item.id == id);
  }

  @override
  dispose() {
    _onChange.cancel();
    _addonsCache.clear();
  }

  @override
  FutureOr<void> setup() async {
    _onChange = pb.authStore.onChange.listen((event) async {
      await _fetchAddons();
    });

    if (pb.authStore.isValid) {
      await _fetchAddons();
    }
  }

  String getAddonBaseURL(String input) {
    return input.endsWith("/manifest.json")
        ? input.replaceAll("/manifest.json", "")
        : input;
  }
}
