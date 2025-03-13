import 'package:json_annotation/json_annotation.dart';

part 'types.g.dart';

class HomeLayout {
  final String id;
  final String title;
  final dynamic config;
  final int order;
  final String pluginId;
  final String type;

  HomeLayout({
    required this.id,
    required this.title,
    required this.config,
    required this.order,
    required this.pluginId,
    required this.type,
  });

  StremioAddonConfig? get stremioConfig {
    if (pluginId == 'stremio_catalog' &&
        type == 'catalog_grid' &&
        config is Map<String, dynamic>) {
      return StremioAddonConfig.fromJson(config as Map<String, dynamic>);
    }

    return null;
  }
}

@JsonSerializable()
class StremioAddonConfig {
  @JsonKey(name: "addon")
  final String addon;
  @JsonKey(name: "can_search")
  final bool canSearch;
  @JsonKey(name: "description")
  final String? description;
  @JsonKey(name: "extra_required")
  final List<String>? extraRequired;
  @JsonKey(name: "extra_supported")
  final List<String>? extraSupport;
  @JsonKey(name: "id")
  final String id;
  @JsonKey(name: "name")
  final String name;
  @JsonKey(name: "type")
  final String type;
  @JsonKey(name: "addon_id")
  final String addonId;

  StremioAddonConfig({
    required this.addon,
    required this.canSearch,
    this.description,
    this.extraRequired,
    this.extraSupport,
    required this.id,
    required this.name,
    required this.type,
    required this.addonId,
  });

  factory StremioAddonConfig.fromJson(Map<String, dynamic> json) =>
      _$StremioAddonConfigFromJson(json);

  Map<String, dynamic> toJson() => _$StremioAddonConfigToJson(this);
}
