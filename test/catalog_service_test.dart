import 'package:madari_engine/src/services/addon_service.dart';
import 'package:madari_engine/src/services/auth_service.dart';
import 'package:madari_engine/src/services/catalog_service.dart';
import 'package:madari_engine/src/services/explore_service.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:test/scaffolding.dart';

void main() {
  late CatalogService service;
  late ExploreService explore;

  group("catalog service", () {
    setUp(() async {
      final pb = PocketBase(
        "http://100.64.0.1:8090",
      );

      service = CatalogService(
        pb: pb,
        addonService: AddonService(pb: pb),
        authService: AuthService(pb: pb),
      );

      await service.authService.signInWithEmail(
        email: "success@f22.dev",
        password: "password",
      );

      final installedAddons =
          await service.addonService.getAddons(onlyEnabled: false);

      for (final addon in installedAddons) {
        await service.addonService.uninstallAddon(addon.id!);
      }

      final addons = await Future.wait([
        service.addonService.validateAddon(
          "https://catalog.madari.media/manifest.json",
        ),
        service.addonService.validateAddon(
          "https://v3-cinemeta.strem.io/manifest.json",
        ),
        service.addonService.validateAddon(
          "https://94c8cb9f702d-tmdb-addon.baby-beamup.club/%7B%22language%22%3A%22en-US%22%2C%22catalogs%22%3A%5B%7B%22id%22%3A%22tmdb.top%22%2C%22type%22%3A%22movie%22%2C%22showInHome%22%3Atrue%7D%2C%7B%22id%22%3A%22tmdb.top%22%2C%22type%22%3A%22series%22%2C%22showInHome%22%3Atrue%7D%2C%7B%22id%22%3A%22tmdb.year%22%2C%22type%22%3A%22movie%22%2C%22showInHome%22%3Atrue%7D%2C%7B%22id%22%3A%22tmdb.year%22%2C%22type%22%3A%22series%22%2C%22showInHome%22%3Atrue%7D%2C%7B%22id%22%3A%22tmdb.language%22%2C%22type%22%3A%22movie%22%2C%22showInHome%22%3Atrue%7D%2C%7B%22id%22%3A%22tmdb.language%22%2C%22type%22%3A%22series%22%2C%22showInHome%22%3Atrue%7D%2C%7B%22id%22%3A%22tmdb.trending%22%2C%22type%22%3A%22movie%22%2C%22showInHome%22%3Atrue%7D%2C%7B%22id%22%3A%22tmdb.trending%22%2C%22type%22%3A%22series%22%2C%22showInHome%22%3Atrue%7D%5D%7D/manifest.json",
        ),
      ]);

      for (final addon in addons) {
        await service.addonService.saveAddon(addon);
      }

      explore = ExploreService(
        pb: pb,
        addonService: service.addonService,
      );
    });

    test(
      "should build the query for the cinemeta catalog",
      () async {
        final addonByIds = await service.addonService.getAddons(
          onlyEnabled: true,
        );

        int index = 0;

        for (final addon in await service.addonService.getAddonManifest()) {
          for (final catalog in addon.catalogs!) {
            final result = await service.getCatalog(
              addonByIds[index].id!,
              catalog.type,
              catalog.id,
              search: "Matrix",
            );

            print(
              "id=${catalog.id} type=${catalog.type} name=${addon.name} error=${result.error} itemCount=${result.metas?.length}",
            );
          }

          index += 1;
        }
      },
      timeout: Timeout(
        Duration(seconds: 45),
      ),
    );

    test("should get types for explore", () async {
      print(await explore.getTypes());

      final result = await explore.getCatalogs("movie");

      assert(result.isNotEmpty);

      final rs = await explore.getCatalogs("movie");
    });
  });
}
