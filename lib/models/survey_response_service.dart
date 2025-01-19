// lib/services/survey_response_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class SurveyResponseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Create new survey response
  Future<String> createSurveyResponse({
    required String projectId,
    required String surveyorId,
    required String templateType,
  }) async {
    try {
      final response = {
        'projectId': projectId,
        'surveyorId': surveyorId,
        'templateType': templateType,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'draft',
        'isSubmitted': false,
        'needsSync': false,
        'responses': [],
      };

      final docRef = await _firestore.collection('survey_responses').add(response);
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create survey response: $e');
    }
  }

  // Save question response
  Future<void> saveQuestionResponse({
    required String responseId,
    required QuestionResponse questionResponse,
  }) async {
    try {
      final responseDoc = await _firestore
          .collection('survey_responses')
          .doc(responseId)
          .get();

      List responses = responseDoc.data()?['responses'] ?? [];
      
      // Remove existing response for this question if it exists
      responses.removeWhere(
        (r) => r['questionId'] == questionResponse.questionId
      );
      
      // Add new response
      responses.add(questionResponse.toMap());

      await _firestore
          .collection('survey_responses')
          .doc(responseId)
          .update({
        'responses': responses,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to save question response: $e');
    }
  }

  // Upload photo
  Future<String> uploadPhoto(String responseId, String questionId, File photo) async {
    try {
      final path = 'surveys/$responseId/$questionId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child(path);
      
      await ref.putFile(photo);
      final url = await ref.getDownloadURL();
      
      return url;
    } catch (e) {
      throw Exception('Failed to upload photo: $e');
    }
  }

  // Submit survey response
  Future<void> submitSurveyResponse(String responseId) async {
    try {
      await _firestore.collection('survey_responses').doc(responseId).update({
        'isSubmitted': true,
        'status': 'submitted',
        'submittedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to submit survey response: $e');
    }
  }

  // Get survey response
  Stream<DocumentSnapshot> getSurveyResponse(String responseId) {
    return _firestore
        .collection('survey_responses')
        .doc(responseId)
        .snapshots();
  }

  // Get all responses for a project
  Stream<QuerySnapshot> getProjectResponses(String projectId) {
    return _firestore
        .collection('survey_responses')
        .where('projectId', isEqualTo: projectId)
        .snapshots();
  }

  // Get all responses by surveyor
  Stream<QuerySnapshot> getSurveyorResponses(String surveyorId) {
    return _firestore
        .collection('survey_responses')
        .where('surveyorId', isEqualTo: surveyorId)
        .snapshots();
  }
}