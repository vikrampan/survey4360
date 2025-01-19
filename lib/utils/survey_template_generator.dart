// lib/utils/survey_template_generator.dart

import 'package:survey_app/models/survey_template_model.dart';

class SurveyTemplateGenerator {
  static SurveyTemplate generateConstructionSurveyTemplate() {
    return SurveyTemplate(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'CONSTRUCTION',
      sections: [
        // Section 1: Basic Information
        SurveySection(
          title: 'Site Information',
          description: 'Basic details about the site and personnel',
          questions: [
            SurveyQuestion(
              id: 'SI_001',
              question: 'Name of Site Engineer',
              type: 'TEXT',
              requiresRemark: true,
              category: 'Personnel',
            ),
            SurveyQuestion(
              id: 'SI_002',
              question: 'Name of Project Manager',
              type: 'TEXT',
              requiresRemark: true,
              category: 'Personnel',
            ),
            SurveyQuestion(
              id: 'SI_003',
              question: 'Name of Zonal Manager',
              type: 'TEXT',
              requiresRemark: true,
              category: 'Personnel',
            ),
            SurveyQuestion(
              id: 'SI_004',
              question: 'Physical progress at time of inspection (%)',
              type: 'NUMERIC',
              requiresRemark: true,
              category: 'Progress',
            ),
            SurveyQuestion(
              id: 'SI_005',
              question: 'Financial progress (%)',
              type: 'NUMERIC',
              requiresRemark: true,
              category: 'Progress',
            ),
          ],
        ),

        // Section 2: Quality Control Setup
        SurveySection(
          title: 'Quality Control Lab Setup',
          description: 'Verification of quality control equipment and facilities',
          questions: [
            SurveyQuestion(
              id: 'QC_001',
              question: 'Is field laboratory existing and well equipped?',
              type: 'YES_NO',
              requiresPhoto: true,
              requiresRemark: true,
              category: 'Lab Equipment',
            ),
            SurveyQuestion(
              id: 'QC_002',
              question: 'Are balances (7-10kg capacity) available and functional?',
              type: 'YES_NO',
              requiresRemark: true,
              category: 'Lab Equipment',
            ),
            SurveyQuestion(
              id: 'QC_003',
              question: 'Is compression testing machine available and functional?',
              type: 'YES_NO',
              requiresRemark: true,
              category: 'Lab Equipment',
            ),
            SurveyQuestion(
              id: 'QC_004',
              question: 'Are sieves as per IS 460:1962 available?',
              type: 'YES_NO',
              requiresRemark: true,
              category: 'Lab Equipment',
            ),
          ],
        ),

        // Section 3: Documentation Check
        SurveySection(
          title: 'Documentation Check',
          description: 'Verification of site documentation',
          questions: [
            SurveyQuestion(
              id: 'DOC_001',
              question: 'Is cement register properly maintained?',
              type: 'YES_NO',
              requiresRemark: true,
              category: 'Documentation',
            ),
            SurveyQuestion(
              id: 'DOC_002',
              question: 'Is site order book maintained?',
              type: 'YES_NO',
              requiresRemark: true,
              category: 'Documentation',
            ),
            SurveyQuestion(
              id: 'DOC_003',
              question: 'Are cube test registers maintained?',
              type: 'YES_NO',
              requiresRemark: true,
              category: 'Documentation',
            ),
            SurveyQuestion(
              id: 'DOC_004',
              question: 'Is mix design report available?',
              type: 'YES_NO',
              requiresRemark: true,
              category: 'Documentation',
            ),
          ],
        ),

        // Section 4: RCC Works
        SurveySection(
          title: 'RCC Works Inspection',
          description: 'Quality checks for RCC work components',
          questions: [
            SurveyQuestion(
              id: 'RCC_001',
              question: 'Foundation & Plinth Work status and quality',
              type: 'YES_NO',
              requiresPhoto: true,
              requiresRemark: true,
              category: 'RCC',
              subCategory: 'Foundation',
            ),
            SurveyQuestion(
              id: 'RCC_002',
              question: 'Bar Bending & Reinforcement quality',
              type: 'YES_NO',
              requiresPhoto: true,
              requiresRemark: true,
              category: 'RCC',
              subCategory: 'Reinforcement',
            ),
            SurveyQuestion(
              id: 'RCC_003',
              question: 'Column work status and quality',
              type: 'YES_NO',
              requiresPhoto: true,
              requiresRemark: true,
              category: 'RCC',
              subCategory: 'Columns',
            ),
            SurveyQuestion(
              id: 'RCC_004',
              question: 'Are cover blocks provided in adequate quantity?',
              type: 'YES_NO',
              requiresPhoto: true,
              requiresRemark: true,
              category: 'RCC',
              subCategory: 'Cover Blocks',
            ),
            SurveyQuestion(
              id: 'RCC_005',
              question: 'Are shear keys provided at construction joints?',
              type: 'YES_NO',
              requiresPhoto: true,
              requiresRemark: true,
              category: 'RCC',
              subCategory: 'Construction Joints',
            ),
          ],
        ),

        // Section 5: Material Quality
        SurveySection(
          title: 'Material Quality Check',
          description: 'Inspection of construction materials',
          questions: [
            SurveyQuestion(
              id: 'MAT_001',
              question: 'Cement storage conditions and quality',
              type: 'YES_NO',
              requiresPhoto: true,
              requiresRemark: true,
              category: 'Materials',
              subCategory: 'Cement',
            ),
            SurveyQuestion(
              id: 'MAT_002',
              question: 'Steel reinforcement storage and quality',
              type: 'YES_NO',
              requiresPhoto: true,
              requiresRemark: true,
              category: 'Materials',
              subCategory: 'Steel',
            ),
            SurveyQuestion(
              id: 'MAT_003',
              question: 'Aggregates quality (grading and nominal size)',
              type: 'YES_NO',
              requiresPhoto: true,
              requiresRemark: true,
              category: 'Materials',
              subCategory: 'Aggregates',
            ),
            SurveyQuestion(
              id: 'MAT_004',
              question: 'Fine aggregate quality and zone',
              type: 'YES_NO',
              requiresPhoto: true,
              requiresRemark: true,
              category: 'Materials',
              subCategory: 'Sand',
            ),
          ],
        ),

        // Section 6: Safety and Housekeeping
        SurveySection(
          title: 'Safety and Housekeeping',
          description: 'Site safety and cleanliness assessment',
          questions: [
            SurveyQuestion(
              id: 'SH_001',
              question: 'Are workers using proper PPE?',
              type: 'YES_NO',
              requiresPhoto: true,
              requiresRemark: true,
              category: 'Safety',
            ),
            SurveyQuestion(
              id: 'SH_002',
              question: 'Is material stacking done properly as per IS:4082?',
              type: 'YES_NO',
              requiresPhoto: true,
              requiresRemark: true,
              category: 'Housekeeping',
            ),
            SurveyQuestion(
              id: 'SH_003',
              question: 'Is the site properly cleaned and maintained?',
              type: 'YES_NO',
              requiresPhoto: true,
              requiresRemark: true,
              category: 'Housekeeping',
            ),
          ],
        ),
      ],
      isActive: true,
    );
  }
}