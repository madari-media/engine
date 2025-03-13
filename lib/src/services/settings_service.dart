import 'package:madari_engine/src/services/settings_service/types.dart';
import 'package:madari_engine/src/types/madari_service.dart';

class SettingsService extends MadariService {
  SettingsService({required super.pb});

  PlaybackSettings getPlaybackSettings() {
    if (!pb.authStore.isValid) throw Exception("User is not authenticated");

    final config = pb.authStore.record!.get("config");

    return PlaybackSettings.fromJson(config);
  }

  Future<void> savePlaybackSettings(PlaybackSettings settings) async {
    if (!pb.authStore.isValid) throw Exception("User is not authenticated");

    final record = pb.authStore.record!;

    await pb.collection("users").update(record.id, body: {
      "config": settings.toJson(),
    });
  }
}
