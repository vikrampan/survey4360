// lib/models/checklist_item_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ChecklistItemModel {
  final String id;
  final String question;
  final String? category;
  final String? subCategory;
  final bool response; // Y/N
  final String? reasonIfNo;
  final String? followupAction;
  final String? remarks;
  final DateTime? checkDate;
  final String checkedBy; // Surveyor ID 

  ChecklistItemModel({
    required this.id,
    required this.question,
    this.category,
    this.subCategory,
    required this.response,
    this.reasonIfNo,
    this.followupAction,
    this.remarks,
    this.checkDate,
    required this.checkedBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'question': question,
      'category': category,
      'subCategory': subCategory,
      'response': response,
      'reasonIfNo': reasonIfNo,
      'followupAction': followupAction,
      'remarks': remarks,
      'checkDate': checkDate != null ? Timestamp.fromDate(checkDate!) : null,
      'checkedBy': checkedBy,
    };
  }

  factory ChecklistItemModel.fromMap(Map<String, dynamic> map, String id) {
    return ChecklistItemModel(
      id: id,
      question: map['question'] ?? '',
      category: map['category'],
      subCategory: map['subCategory'],
      response: map['response'] ?? false,
      reasonIfNo: map['reasonIfNo'],
      followupAction: map['followupAction'],
      remarks: map['remarks'],
      checkDate: map['checkDate'] != null ? (map['checkDate'] as Timestamp).toDate() : null,
      checkedBy: map['checkedBy'] ?? '',
    );
  }
}