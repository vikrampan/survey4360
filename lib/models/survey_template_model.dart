// lib/models/survey_template_model.dart
class SurveyTemplate {
  final String id;
  final String type; // "ROAD", "SERVICES", "CIVIL"
  final List<SurveySection> sections;
  final bool isActive;

  SurveyTemplate({
    required this.id,
    required this.type,
    required this.sections,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'sections': sections.map((s) => s.toMap()).toList(),
      'isActive': isActive,
    };
  }
}

class SurveySection {
  final String title;
  final List<SurveyQuestion> questions;
  final String? description;

  SurveySection({
    required this.title,
    required this.questions,
    this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'questions': questions.map((q) => q.toMap()).toList(),
      'description': description,
    };
  }
}

class SurveyQuestion {
  final String id;
  final String question;
  final String type; // "YES_NO", "TEXT", "NUMERIC"
  final bool requiresPhoto;
  final bool requiresRemark;
  final String? category;
  final String? subCategory;

  SurveyQuestion({
    required this.id,
    required this.question,
    required this.type,
    this.requiresPhoto = false,
    this.requiresRemark = true,
    this.category,
    this.subCategory,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question': question,
      'type': type,
      'requiresPhoto': requiresPhoto,
      'requiresRemark': requiresRemark,
      'category': category,
      'subCategory': subCategory,
    };
  }
}