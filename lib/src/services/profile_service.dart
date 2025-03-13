import 'dart:async';

import 'package:logging/logging.dart';
import 'package:madari_engine/src/services/profile_service/types.dart';
import 'package:madari_engine/src/types/madari_service.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:rxdart/rxdart.dart';

class ProfileService extends MadariService {
  final Logger _logger = Logger('ProfileService');
  UserProfile? _profile;
  List<UserProfile>? _availableProfiles;
  late StreamSubscription<AuthStoreEvent> _listeners;
  final onProfileUpdate = BehaviorSubject.seeded(true);

  ProfileService({
    required super.pb,
  });

  @override
  Future<void> setup() async {
    _logger.info('Setting up ProfileService');
    _listeners = pb.authStore.onChange.listen(
      (item) {
        if (!pb.authStore.isValid) {
          _logger
              .info('Auth store became invalid, clearing available profiles');
          _availableProfiles = null;
        }
      },
    );
    _logger.info('ProfileService setup completed');
  }

  Future<UserProfile?> getCurrentProfile() async {
    _logger.info('Getting current profile: ${_profile?.id ?? 'none set'}');
    return _profile;
  }

  Future<void> setCurrentProfile(String id) async {
    _logger.info('Setting current profile to ID: $id');
    _availableProfiles = await getAllProfiles();
    try {
      _profile = _availableProfiles!.firstWhere((item) {
        return item.id == id;
      });

      onProfileUpdate.add(false);

      _logger.info('Successfully set current profile to: ${_profile?.name}');
    } catch (e) {
      _logger.warning('Failed to set profile with ID $id: $e');
      rethrow;
    }
  }

  Future<List<UserProfile>> getAllProfiles() async {
    _logger.info('Fetching all profiles');

    if (_availableProfiles != null) {
      _logger.info(
          'Returning cached profiles: ${_availableProfiles!.length} profiles');
      return _availableProfiles!;
    }

    try {
      final result =
          await pb.collection("account_profile").getFullList().then((docs) {
        return docs.map((res) {
          String? profileImage;

          if (res.getStringValue("profile_image") != "") {
            profileImage = pb.files
                .getURL(
                  res,
                  res.getStringValue("profile_image"),
                )
                .toString();
          }

          return UserProfile(
            id: res.id,
            name: res.getStringValue("name"),
            profileImage: profileImage,
            canSearch: res.getBoolValue("can_search"),
          );
        }).toList();
      });

      _availableProfiles = result;
      _logger.info('Successfully fetched ${result.length} profiles');
      return result;
    } catch (e) {
      _logger.severe('Failed to fetch profiles: $e');
      rethrow;
    }
  }

  Future<UserProfile> createProfile({
    required String name,
    required bool canSearch,
  }) async {
    _logger.info('Creating new profile: $name (canSearch: $canSearch)');

    try {
      final user = await pb.collection("account_profile").create(
        body: {
          "name": name,
          "can_search": canSearch,
          "user": pb.authStore.record!.id,
        },
      );

      onProfileUpdate.add(false);

      final profile = UserProfile(
        id: user.id,
        name: user.getStringValue("name"),
        canSearch: user.getBoolValue("can_search"),
      );

      _availableProfiles?.add(profile);
      _logger.info('Successfully created profile: ${profile.id}');

      return profile;
    } catch (e) {
      _logger.severe('Failed to create profile: $e');
      rethrow;
    }
  }

  Future<void> deleteProfile({
    required String id,
  }) async {
    _logger.info('Attempting to delete profile: $id');

    if (_profile?.id == id) {
      _logger.warning('Attempted to delete currently selected profile: $id');
      throw Exception(
        "Can't delete selected profile",
      );
    }

    onProfileUpdate.add(false);

    try {
      await pb.collection("account_profile").delete(id);
      _logger.info('Successfully deleted profile: $id');

      _availableProfiles = null;
      _logger.info('Refreshing profiles list');
      await getAllProfiles();
    } catch (e) {
      _logger.severe('Failed to delete profile $id: $e');
      rethrow;
    }
  }

  @override
  dispose() {
    _logger.info('Disposing ProfileService');
    _listeners.cancel();
  }
}
