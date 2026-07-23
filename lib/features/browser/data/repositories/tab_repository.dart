import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:mechanix_browser/core/utils/constants.dart';
import 'package:mechanix_browser/features/browser/data/models/tab_entity.dart';
import 'package:mechanix_browser/objectbox.g.dart';

class TabRepository {
  final Store store;
  final Box<TabEntity> _tabBox;

  TabRepository._(this.store) : _tabBox = store.box<TabEntity>();

static Future<TabRepository> create({Store? store}) async {
    try {
      if (store != null) {
        return TabRepository._(store);
      }

      final home = Platform.environment['HOME'];
      if (home == null || home.isEmpty) {
        throw Exception('HOME environment variable is not set');
      }

      final storeDir = Directory('$home/${AppConstants.dbPath}');
      if (!await storeDir.exists()) {
        await storeDir.create(recursive: true);
      }

      final newStore = await openStore(directory: storeDir.path);
      return TabRepository._(newStore);
    } catch (e, stackTrace) {
      debugPrint('Unable to initialize bookmark storage: $e');
      debugPrint(stackTrace.toString());
      rethrow;
    }
  }
  void saveTab(TabEntity tab) {
    try {
      // Check if tab already exists by tabId
      final query = _tabBox.query(TabEntity_.tabId.equals(tab.tabId)).build();
      final existing = query.findFirst();
      query.close();

      if (existing != null) {
        tab.id = existing.id;
      }
      _tabBox.put(tab);
    } catch (e, stackTrace) {
      debugPrint('Unable to save tab: $e');
      debugPrint(stackTrace.toString());
    }
  }

  void saveAllTabs(List<TabEntity> tabs) {
    try {
      _tabBox.putMany(tabs);
    } catch (e, stackTrace) {
      debugPrint('Unable to save tabs: $e');
      debugPrint(stackTrace.toString());
    }
  }

  List<TabEntity> getAllTabs() {
    try {
      final query = (_tabBox.query()..order(TabEntity_.tabIndex)).build();
      final results = query.find();
      query.close();
      return results;
    } catch (e, stackTrace) {
      debugPrint('Unable to get tabs: $e');
      debugPrint(stackTrace.toString());
      return [];
    }
  }

  void deleteTab(String tabId) {
    try {
      final query = _tabBox.query(TabEntity_.tabId.equals(tabId)).build();
      final existing = query.findFirst();
      query.close();

      if (existing != null) {
        _tabBox.remove(existing.id);
      }
    } catch (e, stackTrace) {
      debugPrint('Unable to delete tab: $e');
      debugPrint(stackTrace.toString());
    }
  }

  void deleteAllTabs() {
    try {
      _tabBox.removeAll();
    } catch (e, stackTrace) {
      debugPrint('Unable to delete all tabs: $e');
      debugPrint(stackTrace.toString());
    }
  }
}
