// lib/models/project_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

enum ProjectType { road, services, civil }

enum ProjectStatus { pending, inProgress, completed }

class ProjectModel {
  final String id;
  final String name;
  final String location;
  final ProjectType type;
  final ProjectStatus status;
  final DateTime createdAt;
  final String createdBy; // Admin ID
  final List<String> assignedSurveyors;
  final String contractorName;
  final String contractorContact;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;

  ProjectModel({
    required this.id,
    required this.name,
    required this.location,
    required this.type,
    required this.status,
    required this.createdAt,
    required this.createdBy,
    required this.assignedSurveyors,
    required this.contractorName,
    required this.contractorContact,
    required this.startDate,
    this.endDate,
    this.isActive = true,
  });

  // Convert project type to string format that matches survey templates
  String _getProjectTypeString() {
    switch (type) {
      case ProjectType.road:
        return 'CONSTRUCTION';  // Changed to match template type
      case ProjectType.services:
        return 'SERVICES';
      case ProjectType.civil:
        return 'CONSTRUCTION';  // Civil projects also use CONSTRUCTION template
      default:
        return 'CONSTRUCTION';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'location': location,
      'type': _getProjectTypeString(), // Using the new conversion method
      'status': status.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'assignedSurveyors': assignedSurveyors,
      'contractorName': contractorName,
      'contractorContact': contractorContact,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'isActive': isActive,
    };
  }

  factory ProjectModel.fromMap(Map<String, dynamic> map, String id) {
    return ProjectModel(
      id: id,
      name: map['name'] ?? '',
      location: map['location'] ?? '',
      type: _parseProjectType(map['type'] ?? ''),
      status: _parseProjectStatus(map['status'] ?? ''),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      createdBy: map['createdBy'] ?? '',
      assignedSurveyors: List<String>.from(map['assignedSurveyors'] ?? []),
      contractorName: map['contractorName'] ?? '',
      contractorContact: map['contractorContact'] ?? '',
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: map['endDate'] != null ? (map['endDate'] as Timestamp).toDate() : null,
      isActive: map['isActive'] ?? true,
    );
  }

  // Updated parsing method to handle both enum strings and template type strings
  static ProjectType _parseProjectType(String typeStr) {
    final type = typeStr.toUpperCase();
    switch (type) {
      case 'CONSTRUCTION':
        return ProjectType.road;
      case 'SERVICES':
        return ProjectType.services;
      default:
        // Try to parse as enum if not matched above
        return ProjectType.values.firstWhere(
          (e) => e.toString().split('.').last.toUpperCase() == type,
          orElse: () => ProjectType.road,
        );
    }
  }

  static ProjectStatus _parseProjectStatus(String statusStr) {
    final status = statusStr.toLowerCase();
    return ProjectStatus.values.firstWhere(
      (e) => e.toString().split('.').last.toLowerCase() == status,
      orElse: () => ProjectStatus.pending,
    );
  }

  // Rest of the methods remain the same
  ProjectModel copyWith({
    String? name,
    String? location,
    ProjectType? type,
    ProjectStatus? status,
    DateTime? createdAt,
    String? createdBy,
    List<String>? assignedSurveyors,
    String? contractorName,
    String? contractorContact,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
  }) {
    return ProjectModel(
      id: this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      assignedSurveyors: assignedSurveyors ?? this.assignedSurveyors,
      contractorName: contractorName ?? this.contractorName,
      contractorContact: contractorContact ?? this.contractorContact,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
    );
  }

  String get statusString => status.toString().split('.').last;
  String get typeString => _getProjectTypeString();
  bool get isProjectActive => isActive;
  bool get hasEnded => endDate != null && endDate!.isBefore(DateTime.now());

  int get projectDuration {
    if (endDate == null) {
      return DateTime.now().difference(startDate).inDays;
    }
    return endDate!.difference(startDate).inDays;
  }

  @override
  String toString() {
    return 'ProjectModel(id: $id, name: $name, status: $statusString)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProjectModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}