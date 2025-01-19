// lib/models/survey_assignment_model.dart
class SurveyAssignment {
  final String id;
  final String surveyId;
  final String surveyorId;
  final String projectId;
  final DateTime assignedDate;
  final String status;
  final bool isActive;

  SurveyAssignment({
    required this.id,
    required this.surveyId,
    required this.surveyorId,
    required this.projectId,
    required this.assignedDate,
    this.status = 'pending',
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'surveyId': surveyId,
      'surveyorId': surveyorId,
      'projectId': projectId,
      'assignedDate': assignedDate,
      'status': status,
      'isActive': isActive,
    };
  }

  factory SurveyAssignment.fromMap(Map<String, dynamic> map, String id) {
    return SurveyAssignment(
      id: id,
      surveyId: map['surveyId'],
      surveyorId: map['surveyorId'],
      projectId: map['projectId'],
      assignedDate: (map['assignedDate'] as Timestamp).toDate(),
      status: map['status'] ?? 'pending',
      isActive: map['isActive'] ?? true,
    );
  }
}