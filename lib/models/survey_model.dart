// lib/models/survey_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import './checklist_item_model.dart';

enum SurveyStatus {
  pending,
  inProgress,
  completed,
  needsRevision,
  approved,
}

class SurveyModel {
  final String id;
  final String projectId;
  final String surveyorId;
  final DateTime createdAt;
  final DateTime? completedAt;
  final SurveyStatus status;
  final List<ChecklistItemModel> checklistItems;
  final List<String> attachments; // URLs to uploaded files/photos
  final String? notes;
  final bool isSubmitted;
  final bool needsSync; // For offline functionality 

  SurveyModel({
    required this.id,
    required this.projectId,
    required this.surveyorId,
    required this.createdAt,
    this.completedAt,
    required this.status,
    required this.checklistItems,
    this.attachments = const [],
    this.notes,
    this.isSubmitted = false,
    this.needsSync = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'projectId': projectId,
      'surveyorId': surveyorId,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'status': status.toString(),
      'checklistItems': checklistItems.map((item) => item.toMap()).toList(),
      'attachments': attachments,
      'notes': notes,
      'isSubmitted': isSubmitted,
      'needsSync': needsSync,
    };
  }

  factory SurveyModel.fromMap(Map<String, dynamic> map, String id) {
    return SurveyModel(
      id: id,
      projectId: map['projectId'] ?? '',
      surveyorId: map['surveyorId'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      completedAt: map['completedAt'] != null ? (map['completedAt'] as Timestamp).toDate() : null,
      status: SurveyStatus.values.firstWhere(
        (e) => e.toString() == map['status'],
        orElse: () => SurveyStatus.pending,
      ),
      checklistItems: (map['checklistItems'] as List)
          .map((item) => ChecklistItemModel.fromMap(
              Map<String, dynamic>.from(item), 
              item['id'] ?? ''))
          .toList(),
      attachments: List<String>.from(map['attachments'] ?? []),
      notes: map['notes'],
      isSubmitted: map['isSubmitted'] ?? false,
      needsSync: map['needsSync'] ?? false,
    );
  }
}