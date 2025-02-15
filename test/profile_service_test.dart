import 'package:logging/logging.dart';
import 'package:madari_engine/src/services/auth_service.dart';
import 'package:madari_engine/src/services/profile_service.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

void main() {
  group("profile service", () {
    late AuthService authService;
    late ProfileService profileService;

    setUp(() async {
      Logger.root.level = Level.ALL;
      Logger.root.onRecord.listen((record) {
        print('${record.level.name}: ${record.time}: ${record.message}');
      });

      authService = AuthService(
        pb: PocketBase("http://100.64.0.1:8090"),
      );

      await authService.signInWithEmail(
        email: "success@f22.dev",
        password: "password",
      );

      profileService = ProfileService(
        pb: authService.pb,
      );

      profileService.setup();
    });

    tearDown(() {
      profileService.dispose();
    });

    test("should get the profile", () async {
      final profiles = await profileService.getAllProfiles();

      if (profiles.isNotEmpty) {
        await Future.wait(
          profiles.map(
            (profile) {
              return profileService.deleteProfile(id: profile.id);
            },
          ),
        );
      }

      final profile = await profileService.createProfile(
        name: "Test",
        canSearch: true,
      );

      final result = await profileService.getAllProfiles();

      assert(result.length == 1);

      await profileService.setCurrentProfile(profile.id);

      final newProfile = await profileService.createProfile(
        name: "Ajax",
        canSearch: true,
      );

      assert(result.length == 2);

      await profileService.deleteProfile(
        id: newProfile.id,
      );

      final result2 = await profileService.getAllProfiles();

      assert(result2.length == 1);

      expect(
        () async => await profileService.deleteProfile(id: profile.id),
        throwsA(isA<Exception>()),
      );
    });
  });
}
