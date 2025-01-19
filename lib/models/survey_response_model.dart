import 'package:cloud_firestore/cloud_firestore.dart';

class SurveyResponse {
  final String id;
  final String surveyId;
  final String projectId;
  final String surveyorId;
  final String templateType; // "ROAD", "SERVICES", "CIVIL"
  final List<QuestionResponse> responses;
  final DateTime createdAt;
  final DateTime? submittedAt;
  final bool isSubmitted;
  final bool needsSync;
  final String status; // "draft", "submitted", "reviewed", "rejected"

  const SurveyResponse({
    required this.id,
    required this.surveyId,
    required this.projectId,
    required this.surveyorId,
    required this.templateType,
    required this.responses,
    required this.createdAt,
    this.submittedAt,
    this.isSubmitted = false,
    this.needsSync = false,
    this.status = 'draft',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'surveyId': surveyId,
      'projectId': projectId,
      'surveyorId': surveyorId,
      'templateType': templateType,
      'responses': responses.map((r) => r.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'submittedAt': submittedAt != null ? Timestamp.fromDate(submittedAt!) : null,
      'isSubmitted': isSubmitted,
      'needsSync': needsSync,
      'status': status,
    };
  }

  factory SurveyResponse.fromMap(Map<String, dynamic> map, String documentId) {
    return SurveyResponse(
      id: documentId,
      surveyId: map['surveyId'] as String,
      projectId: map['projectId'] as String,
      surveyorId: map['surveyorId'] as String,
      templateType: map['templateType'] as String,
      responses: (map['responses'] as List<dynamic>)
          .map((r) => QuestionResponse.fromMap(r as Map<String, dynamic>))
          .toList(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      submittedAt: map['submittedAt'] != null
          ? (map['submittedAt'] as Timestamp).toDate()
          : null,
      isSubmitted: map['isSubmitted'] as bool,
      needsSync: map['needsSync'] as bool? ?? false,
      status: map['status'] as String? ?? 'draft',
    );
  }

  // Add a copyWith method for easy modification
  SurveyResponse copyWith({
    String? id,
    String? surveyId,
    String? projectId,
    String? surveyorId,
    String? templateType,
    List<QuestionResponse>? responses,
    DateTime? createdAt,
    DateTime? submittedAt,
    bool? isSubmitted,
    bool? needsSync,
    String? status,
  }) {
    return SurveyResponse(
      id: id ?? this.id,
      surveyId: surveyId ?? this.surveyId,
      projectId: projectId ?? this.projectId,
      surveyorId: surveyorId ?? this.surveyorId,
      templateType: templateType ?? this.templateType,
      responses: responses ?? this.responses,
      createdAt: createdAt ?? this.createdAt,
      submittedAt: submittedAt ?? this.submittedAt,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      needsSync: needsSync ?? this.needsSync,
      status: status ?? this.status,
    );
  }
}

class QuestionResponse {
  final String questionId;
  final bool response; // Yes/No
  final String? remarks;
  final List<String> photoUrls;
  final Map<String, dynamic>? measurements;
  final DateTime timestamp;
  final String? followupAction;
  final bool hasIssue;
  final String? reviewComment;

  const QuestionResponse({
    required this.questionId,
    required this.response,
    this.remarks,
    this.photoUrls = const [],
    this.measurements,
    required this.timestamp,
    this.followupAction,
    this.hasIssue = false,
    this.reviewComment,
  });

  Map<String, dynamic> toMap() {
    return {
      'questionId': questionId,
      'response': response,
      'remarks': remarks,
      'photoUrls': photoUrls,
      'measurements': measurements,
      'timestamp': Timestamp.fromDate(timestamp),
      'followupAction': followupAction,
      'hasIssue': hasIssue,
      'reviewComment': reviewComment,
    };
  }

  factory QuestionResponse.fromMap(Map<String, dynamic> map) {
    return QuestionResponse(
      questionId: map['questionId'] as String,
      response: map['response'] as bool,
      remarks: map['remarks'] as String?,
      photoUrls: List<String>.from(map['photoUrls'] ?? []),
      measurements: map['measurements'] as Map<String, dynamic>?,
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      followupAction: map['followupAction'] as String?,
      hasIssue: map['hasIssue'] as bool? ?? false,
      reviewComment: map['reviewComment'] as String?,
    );
  }

  // Add a copyWith method for easy modification
  QuestionResponse copyWith({
    String? questionId,
    bool? response,
    String? remarks,
    List<String>? photoUrls,
    Map<String, dynamic>? measurements,
    DateTime? timestamp,
    String? followupAction,
    bool? hasIssue,
    String? reviewComment,
  }) {
    return QuestionResponse(
      questionId: questionId ?? this.questionId,
      response: response ?? this.response,
      remarks: remarks ?? this.remarks,
      photoUrls: photoUrls ?? this.photoUrls,
      measurements: measurements ?? this.measurements,
      timestamp: timestamp ?? this.timestamp,
      followupAction: followupAction ?? this.followupAction,
      hasIssue: hasIssue ?? this.hasIssue,
      reviewComment: reviewComment ?? this.reviewComment,
    );
  }
}