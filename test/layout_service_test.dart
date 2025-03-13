import 'package:madari_engine/src/services/addon_service.dart';
import 'package:madari_engine/src/services/auth_service.dart';
import 'package:madari_engine/src/services/layout_service.dart';
import 'package:madari_engine/src/services/profile_service.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:test/scaffolding.dart';

import 'helper/base_path.dart';

void main() async {
  final profileService = ProfileService(
    pb: PocketBase(
      baseUrl,
    ),
  );

  final addonService = AddonService(pb: profileService.pb);

  final layoutService = LayoutService(
    pb: profileService.pb,
    profileService: profileService,
    addonService: addonService,
  );

  final authService = AuthService(pb: profileService.pb);

  final result = await authService.signInWithEmail(
    email: mockUsername,
    password: mockPassword,
  );

  final profiles = await profileService.getAllProfiles();

  await profileService.setCurrentProfile(profiles.first.id);

  test("Layout service", () async {
    final result = await layoutService.getHomeLayout();

    print(result);
  });
}
