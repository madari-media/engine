import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:madari_engine/src/services/addon_service.dart';
import 'package:madari_engine/src/services/auth_service.dart';
import 'package:madari_engine/src/types/madari_service.dart';
import 'package:madari_engine/src/utils/first_or_where.dart';

import '../models/stremio_addons_types.dart';
import '../types/cast_info.dart';
import 'catalog_service/types.dart';

class CatalogService extends MadariService {
  final Logger _logger = Logger('CatalogService');
  final AddonService addonService;
  final AuthService authService;

  CatalogService({
    required super.pb,
    required this.addonService,
    required this.authService,
  });

  @override
  dispose() {}

  @override
  FutureOr<void> setup() {}

  StremioManifestCatalog? getStremioManifestCatalog({
    required StremioManifest manifest,
    required String type,
    required String id,
  }) {
    return manifest.catalogs?.firstWhereOrNull((item) {
      return item.type == type && item.id == id;
    });
  }

  Future<CatalogResponse> getCatalog(
    String addonId,
    String type,
    String id, {
    int page = 1,
    String? search,
    String? genre,
  }) async {
    final addonData = await addonService.getAddonById(
      addonId,
    );
    final manifest = await addonService.validateAddon(addonData.url);
    final catalog = getStremioManifestCatalog(
      manifest: manifest,
      type: type,
      id: id,
    );

    if (catalog == null) {
      _logger.info("Catalog not found $type $id");
      return CatalogResponse(
        metas: [],
        hasNextPage: false,
        error: "Catalog not found",
        shouldRender: false,
      );
    }

    String url =
        "${addonService.getAddonBaseURL(addonData.url)}/catalog/$type/$id";

    final items = _buildItems(
      catalog: catalog,
      manifest: manifest,
      genre: genre,
      page: page,
      search: search,
    );

    if (!catalog.hasSupport("search") && search != null) {
      return CatalogResponse(
        hasNextPage: false,
        shouldRender: false,
        error: "Search is not supported for this catalog",
      );
    }

    for (final requiredItem in (catalog.extraRequired!)) {
      bool found = requiredItem ==
          "featured"; // Features is not actually required need some different logic for sure

      for (final item in items) {
        if (item.title == requiredItem) {
          found = true;
          break;
        }
      }

      if (found) {
        continue;
      }

      return CatalogResponse(
        hasNextPage: false,
        shouldRender: true,
        error: "Required item $requiredItem not found",
      );
    }

    final resultUrl = _buildUrl(
      catalog: catalog,
      manifest: manifest,
      url: url,
      items: items,
    );

    final body = await http.get(
      Uri.parse(resultUrl),
      headers: {},
    );

    if (!(body.statusCode >= 200 && body.statusCode <= 299)) {
      return CatalogResponse(
        hasNextPage: false,
        shouldRender: true,
        url: resultUrl,
        error: "Invalid status from addon ${body.statusCode}",
      );
    }

    try {
      final bodyParsed = utf8.decode(body.bodyBytes);

      final meta = StrmioMeta.fromJson(
        jsonDecode(bodyParsed),
      );

      return CatalogResponse(
        metas: meta.metas,
        hasNextPage: (meta.metas ?? []).isNotEmpty,
        shouldRender: true,
        url: resultUrl,
      );
    } catch (e, stack) {
      _logger.warning("failed to load the catalog", e, stack);
      return CatalogResponse(
        hasNextPage: false,
        shouldRender: true,
        error: "Unable to parse response $e",
      );
    }
  }

  String _buildUrl({
    required List<ConnectionFilterItem> items,
    required String url,
    required StremioManifestCatalog catalog,
    required StremioManifest manifest,
  }) {
    if (manifest.manifestVersion == "v2") {
      if (items.isNotEmpty) {
        String filterPath = items
            .map((filter) {
              final value = catalog.extraSupported?.contains(filter.title);

              if (value == null) {
                return null;
              }

              return "${filter.title}=${Uri.encodeComponent(filter.value.toString())}";
            })
            .whereType<String>()
            .join('&');

        if (filterPath.isNotEmpty) {
          url += "?$filterPath";
        }
      }

      return url;
    }

    if (items.isNotEmpty) {
      String filterPath = items
          .map((filter) {
            final value = catalog.extraSupported?.contains(filter.title);

            if (value == null) {
              return null;
            }

            return "${filter.title}=${Uri.encodeComponent(filter.value.toString())}";
          })
          .whereType<String>()
          .join('/');

      if (filterPath.isNotEmpty) {
        url += "/$filterPath";
      }
    }

    url += ".json";

    return url;
  }

  List<ConnectionFilterItem> _buildItems({
    required StremioManifestCatalog catalog,
    required StremioManifest manifest,
    String? search,
    int page = 1,
    String? genre,
  }) {
    final List<ConnectionFilterItem> items = [];

    if (catalog.hasSupport("search") && search != null) {
      items.add(
        ConnectionFilterItem(title: "search", value: search),
      );
    }

    if (catalog.hasSupport("region") == true && authService.region != null) {
      items.add(
        ConnectionFilterItem(
          title: "region",
          value: authService.region,
        ),
      );
    }

    if (catalog.hasSupport("language") == true && authService.region != null) {
      items.add(
        ConnectionFilterItem(
          title: "language",
          value: authService.region,
        ),
      );
    }

    final pageSize = manifest.manifestVersion == "v2"
        ? catalog.itemCount
        : (catalog.pageSize ?? 50);

    if (catalog.hasSupport("skip") && search == null) {
      items.add(
        ConnectionFilterItem(
          title: "skip",
          value: (page - 1) * pageSize,
        ),
      );
    }

    if (catalog.hasSupport("genre") && genre != null && search == null) {
      items.add(
        ConnectionFilterItem(title: "genre", value: genre),
      );
    }

    return items;
  }

  Future<Meta?> getMeta() async {
    return null;
  }

  Future<CastMember?> getPerson(String id) async {
    final getInstalledAddon = await addonService.getAddonManifest();

    for (final value in getInstalledAddon) {
      final resource = value.resources?.firstWhereOrNull((item) {
        return item.name == "person";
      });

      if (resource == null) {
        continue;
      }

      String url =
          "${addonService.getAddonBaseURL(value.manifestUrl!)}/person/tmdb:$id.json";

      final result = await http.get(Uri.parse(url));

      if (result.statusCode != 200) {
        _logger.warning("failed with status ${result.statusCode}");
        continue;
      }

      final person = utf8.decode(result.bodyBytes);
      final personData = jsonDecode(person);

      return CastMember.fromJson(personData['person']);
    }

    return null;
  }
}
