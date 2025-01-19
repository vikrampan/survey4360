import 'package:cloud_firestore/cloud_firestore.dart';

class SurveyResponseService {
 final FirebaseFirestore _firestore = FirebaseFirestore.instance;

 // Create new survey response
 Future<String> createSurveyResponse({
   required String projectId,
   required String surveyorId,
   required String templateType,
 }) async {
   try {
     final docRef = await _firestore.collection('survey_responses').add({
       'projectId': projectId,
       'surveyorId': surveyorId,
       'templateType': templateType,
       'status': 'draft',
       'createdAt': FieldValue.serverTimestamp(),
       'responses': [],
       'needsSync': false,
     });
     return docRef.id;
   } catch (e) {
     throw Exception('Failed to create survey response: $e');
   }
 }

 // Save individual question response
 Future<void> saveQuestionResponse({
   required String responseId,
   required Map<String, dynamic> questionResponse,
 }) async {
   try {
     await _firestore
         .collection('survey_responses')
         .doc(responseId)
         .update({
       'responses': FieldValue.arrayUnion([questionResponse]),
       'lastUpdated': FieldValue.serverTimestamp(),
     });
   } catch (e) {
     throw Exception('Failed to save question response: $e');
   }
 }

 // Submit complete survey
 Future<void> submitSurveyResponse(
   String responseId, {
   String status = 'submitted',
 }) async {
   try {
     await _firestore
         .collection('survey_responses')
         .doc(responseId)
         .update({
       'status': status,
       'submittedAt': FieldValue.serverTimestamp(),
     });
   } catch (e) {
     throw Exception('Failed to submit survey: $e');
   }
 }

 // Update survey response
 Future<void> updateSurveyResponse(
   String responseId,
   List<dynamic> responses,
   String status,
 ) async {
   try {
     await _firestore
         .collection('survey_responses')
         .doc(responseId)
         .update({
       'responses': responses,
       'status': status,
       'lastUpdated': FieldValue.serverTimestamp(),
     });
   } catch (e) {
     throw Exception('Failed to update survey response: $e');
   }
 }

 // Update survey status (for review process)
 Future<void> updateSurveyStatus(
   String responseId,
   String status, {
   Map<String, String>? reviewComments,
   String? reviewerId,
   DateTime? reviewDate,
 }) async {
   try {
     final Map<String, dynamic> updateData = {
       'status': status,
       'reviewStatus': status,
       'reviewedAt': FieldValue.serverTimestamp(),
     };

     if (reviewerId != null) {
       updateData['reviewerId'] = reviewerId;
     }

     if (reviewComments != null) {
       updateData['reviewComments'] = reviewComments;
     }

     await _firestore
         .collection('survey_responses')
         .doc(responseId)
         .update(updateData);
   } catch (e) {
     throw Exception('Failed to update survey status: $e');
   }
 }

 // Get survey response stream
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

 // Delete survey response
 Future<void> deleteSurveyResponse(String responseId) async {
   try {
     await _firestore
         .collection('survey_responses')
         .doc(responseId)
         .delete();
   } catch (e) {
     throw Exception('Failed to delete survey response: $e');
   }
 }
}
