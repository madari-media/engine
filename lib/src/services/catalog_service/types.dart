import '../../models/stremio_addons_types.dart';

class CatalogResponse {
  final List<Meta>? metas;
  final bool hasNextPage;
  final String? error;
  final bool shouldRender;
  final String? url;

  CatalogResponse({
    required this.hasNextPage,
    required this.shouldRender,
    this.url,
    this.metas,
    this.error,
  });
}

class ConnectionFilterItem {
  final String title;
  final dynamic value;

  ConnectionFilterItem({
    required this.title,
    required this.value,
  });
}
