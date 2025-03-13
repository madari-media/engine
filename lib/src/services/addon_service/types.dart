import 'package:pocketbase/pocketbase.dart';

class PocketBaseStremioAddon {
  final String? id;
  final String url;
  final String title;
  final String? icon;
  final bool enabled;

  PocketBaseStremioAddon({
    required this.url,
    required this.title,
    required this.icon,
    required this.enabled,
    this.id,
  });

  PocketBaseStremioAddon copyWith({
    String? url,
    String? title,
    String? icon,
    bool? enabled,
    String? id,
  }) {
    return PocketBaseStremioAddon(
      url: url ?? this.url,
      title: title ?? this.title,
      icon: icon ?? this.icon,
      enabled: enabled ?? this.enabled,
      id: id ?? this.id,
    );
  }

  Map<String, dynamic> toJson(PocketBase pb) {
    return {
      if (id != null) 'id': id,
      'url': url,
      'title': title,
      'icon': icon,
      'enabled': enabled,
      'user': pb.authStore.record!.id,
    };
  }
}
