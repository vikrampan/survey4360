// lib/services/database_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:survey_app/models/user_model.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all surveyors
  Stream<List<UserModel>> getSurveyors() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'surveyor')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => UserModel.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  // Update surveyor status
  Future<void> updateSurveyorStatus(String uid, bool isActive) async {
    await _firestore.collection('users').doc(uid).update({
      'isActive': isActive,
    });
  }

  // Get surveys by surveyor
  Stream<List<Map<String, dynamic>>> getSurveysBySurveyor(String surveyorId) {
    return _firestore
        .collection('surveys')
        .where('surveyorId', isEqualTo: surveyorId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => doc.data()).toList();
        });
  }
}