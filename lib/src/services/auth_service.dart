import 'dart:async';
import 'dart:js_interop';

import 'package:logging/logging.dart';
import 'package:pocketbase/pocketbase.dart';

import '../types/madari_service.dart';

@JSExport()
class AuthService extends MadariService {
  final Logger _logger = Logger('AuthService');

  AuthService({
    required super.pb,
  });

  String? get language {
    final lang = pb.authStore.record?.getStringValue("language");

    if (lang == null || lang.trim() == "") {
      return null;
    }

    return lang;
  }

  String? get region {
    final region = pb.authStore.record?.getStringValue("region");

    if (region == null || region.trim() == "") {
      return null;
    }

    return region;
  }

  @override
  FutureOr<void> setup() {}

  @override
  dispose() {}

  Future<AuthResponse<RecordAuth>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _logger.info('Attempting email sign in for user: $email');

    try {
      final result = await pb.collection("users").authWithPassword(
            email,
            password,
          );

      _logger.info('Successfully signed in user: $email');
      return AuthResponse(
        success: true,
        error: null,
        payload: result,
      );
    } on ClientException catch (e) {
      _logger.warning(
          'Failed to sign in user: $email. Error: ${e.response["message"]}');
      return AuthResponse(
        success: false,
        error: e.response["message"],
        payload: null,
      );
    }
  }

  Future<AuthResponse<String>> sendLoginCode({required String email}) async {
    _logger.info('Sending login code to: $email');

    try {
      final result = await pb.collection("users").requestOTP(email);

      _logger.info('Successfully sent login code to: $email');
      return AuthResponse(
        success: true,
        payload: result.otpId,
      );
    } on ClientException catch (e) {
      _logger.warning(
          'Failed to send login code to: $email. Error: ${e.response["message"]}');
      return AuthResponse(
        success: false,
        error: e.response["message"],
      );
    }
  }

  Future<AuthResponse<RecordAuth>> verifyCode({
    required String otpId,
    required String otp,
  }) async {
    _logger.info('Verifying OTP code for ID: $otpId');

    try {
      final result = await pb.collection("users").authWithOTP(
            otpId,
            otp,
          );

      _logger.info('Successfully verified OTP code for ID: $otpId');
      return AuthResponse(
        success: true,
        payload: result,
      );
    } on ClientException catch (e) {
      _logger.warning(
          'Failed to verify OTP code for ID: $otpId. Error: ${e.response["message"]}');
      return AuthResponse(
        success: false,
        error: e.response["message"],
      );
    }
  }

  Future<AuthResponse<RecordAuth>> createAccount({
    required String name,
    required String email,
    required String password,
  }) async {
    _logger.info('Creating new account for user: $email');

    try {
      await pb.collection("users").create(
        body: {
          "name": name,
          "email": email,
          "password": password,
          "passwordConfirm": password,
        },
      );

      _logger.info(
          'Successfully created account for user: $email. Attempting initial sign in.');
      return signInWithEmail(email: email, password: password);
    } on ClientException catch (e) {
      _logger.warning(
          'Failed to create account for user: $email. Error: ${e.response["message"]}');
      return AuthResponse(
        success: false,
        error: e.response["message"],
      );
    }
  }
}

class AuthResponse<T> {
  final bool success;
  final String? error;
  final T? payload;

  AuthResponse({
    required this.success,
    this.error,
    this.payload,
  });
}
