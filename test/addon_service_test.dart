import 'package:madari_engine/src/services/addon_service.dart';
import 'package:madari_engine/src/services/auth_service.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:test/scaffolding.dart';

void main() {
  late AddonService service;
  late AuthService authService;

  group("Addon service", () {
    setUp(() async {
      authService = AuthService(
        pb: PocketBase(
          "http://100.64.0.1:8090",
        ),
      );

      service = AddonService(
        pb: authService.pb,
      );

      await authService.signInWithEmail(
        email: "success@f22.dev",
        password: "password",
      );
    });

    test("get addons", () async {
      final getAddons = await service.getAddons();
      for (var value in getAddons) {
        await service.uninstallAddon(value.id!);
      }
      final addon = await service.validateAddon(
        "https://catalog.madari.media/manifest.json",
      );
      final addonInfo = await service.saveAddon(addon);
      final addons = await service.getAddons();
      assert(addons.length == 1);
      await service.disableAddon(
        addonInfo.id!,
      );
      final item = await service.getAddons();
      assert(item.first.enabled == false);
      await service.enableAddon(addonInfo.id!);
      final item2 = await service.getAddons();
      assert(item2.first.enabled == true);
      await service.uninstallAddon(addonInfo.id!);
      final noAddons = await service.getAddons();
      assert(noAddons.isEmpty);
    });
  });
}
