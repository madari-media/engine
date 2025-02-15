import 'dart:async';

import 'package:logging/logging.dart';
import 'package:madari_engine/src/services/profile_service.dart';
import 'package:madari_engine/src/types/madari_service.dart';

import 'list_service/index.dart';

class ListService extends MadariService {
  final _logger = Logger('ListService');
  final ProfileService profileService;

  ListService({
    required super.pb,
    required this.profileService,
  });

  Future<List<ListModel>> getLists() async {
    try {
      final records = await pb.collection('list').getFullList(
            filter:
                "account_profile = '${(await profileService.getCurrentProfile())!.id}'",
          );

      return records
          .map((record) => ListModel.fromJson(record.toJson()))
          .toList();
    } catch (e) {
      _logger.severe('Error fetching lists', e);
      rethrow;
    }
  }

  Future<void> createList(CreateListRequest request) async {
    try {
      await pb.collection('list').create(
            body: await request.toJson(profileService),
          );
    } catch (e) {
      _logger.severe('Error creating list', e);
      rethrow;
    }
  }

  Future<void> updateList(String id, UpdateListRequest request) async {
    try {
      await pb.collection('list').update(
            id,
            body: request.toJson(),
          );
    } catch (e) {
      _logger.severe('Error updating list', e);
      rethrow;
    }
  }

  Future<void> deleteList(String id) async {
    try {
      await pb.collection('list').delete(id);
    } catch (e) {
      _logger.severe('Error deleting list', e);
      rethrow;
    }
  }

  Future<void> addListItem(String listId, ListItemModel item) async {
    try {
      final itemData = item.toJson();
      itemData['list'] = listId;

      await pb.collection('list_item').create(
            body: itemData,
          );
    } catch (e) {
      _logger.severe('Error adding list item', e);
      rethrow;
    }
  }

  Future<List<ListItemModel>> getListItems(String listId) async {
    try {
      final records = await pb.collection('list_item').getFullList(
            filter: 'list = "$listId"',
            sort: '-created',
          );

      return records
          .map((record) => ListItemModel.fromJson(record.toJson()))
          .toList();
    } catch (e) {
      _logger.severe('Error fetching list items', e);
      rethrow;
    }
  }

  Future<void> removeListItem(String listId, String itemId) async {
    try {
      await pb.collection('list_item').delete(itemId);
    } catch (e) {
      _logger.severe('Error removing list item', e);
      rethrow;
    }
  }

  @override
  dispose() {}

  @override
  FutureOr<void> setup() {}
}
