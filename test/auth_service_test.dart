import 'dart:math';

import 'package:madari_engine/src/services/auth_service.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:test/scaffolding.dart';

void main() {
  late AuthService authService;

  group('auth', () {
    setUp(() {
      authService = AuthService(
        pb: PocketBase("http://100.64.0.1:8090"),
      );
    });

    test("auth success", () async {
      final result = await authService.signInWithEmail(
        email: "success@f22.dev",
        password: "password",
      );

      assert(result.success == true);
      assert(result.error == null);
    });

    test("auth failed", () async {
      final result = await authService.signInWithEmail(
        email: "success@f22.dev",
        password: "new",
      );

      assert(result.success == false);
      assert(result.error != null);
    });

    test(
      "auth success otp",
      () async {
        final result = await authService.sendLoginCode(
          email: "success@f22.dev",
        );

        print(result.payload);

        assert(result.success == true);
        assert(result.payload != null);
      },
    );

    test("auth success pin", () async {
      final result = await authService.verifyCode(
        otpId: "2w4fh6vdaj7p2pk",
        otp: "18509035",
      );

      print(result.success);
      print(result.payload);
      print(result.error);
    });

    test("auth should create email", () async {
      final random = Random();

      final result = await authService.createAccount(
        name: "Ok",
        email: "test+${random.nextInt(100000000)}@f22.dev",
        password: "randompassword",
      );

      assert(result.success == true);
    });

    test("auth should create the email", () async {
      final result = await authService.createAccount(
        name: "success",
        email: "success@f22.dev",
        password: "password",
      );

      assert(result.success == false);
      assert(result.error != null);
    });
  });
}
