// lib/services/offline_sync_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class OfflineSyncService {
  static const String _boxName = 'offline_surveys';
  late Box _box;

  Future<void> initialize() async {
    _box = await Hive.openBox(_boxName);
  }

  Future<void> saveSurveyOffline(String responseId, Map<String, dynamic> data) async {
    await _box.put(responseId, {
      ...data,
      'needsSync': true,
      'lastModified': DateTime.now().toIso8601String(),
    });
  }

  Future<void> syncOfflineSurveys() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      return;
    }

    final entries = _box.toMap();
    for (var entry in entries.entries) {
      if (entry.value['needsSync'] == true) {
        try {
          await FirebaseFirestore.instance
              .collection('survey_responses')
              .doc(entry.key)
              .update(entry.value);

          await _box.put(entry.key, {
            ...entry.value,
            'needsSync': false,
          });
        } catch (e) {
          print('Error syncing survey: ${entry.key}: $e');
        }
      }
    }
  }

  Stream<bool> get connectivityStream {
    return Connectivity().onConnectivityChanged.map(
      (result) => result != ConnectivityResult.none
    );
  }
}