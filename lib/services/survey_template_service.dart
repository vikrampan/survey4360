// lib/services/survey_template_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class SurveyTemplateService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createRoadWorkTemplate() async {
    final template = {
      'type': 'ROAD',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'isActive': true,
      'sections': [
        {
          'title': 'Bituminous Road',
          'description': 'Testing of following materials',
          'questions': [
            // Coarse Aggregate Testing
            {
              'id': 'road_ca_1',
              'category': 'Coarse Aggregate',
              'question': 'Aggregate Abrasion Value',
              'type': 'YES_NO',
              'requiresRemark': true,
              'requiresPhoto': false,
              'requiresReport': true,
              'reportDescription': 'Enclose brief report & the date of testing'
            },
            {
              'id': 'road_ca_2',
              'category': 'Coarse Aggregate',
              'question': 'Aggregate Impact Value',
              'type': 'YES_NO',
              'requiresRemark': true,
              'requiresPhoto': false
            },
            {
              'id': 'road_ca_3',
              'category': 'Coarse Aggregate',
              'question': 'Flakiness Index',
              'type': 'YES_NO',
              'requiresRemark': true,
              'requiresPhoto': false
            },
            {
              'id': 'road_ca_4',
              'category': 'Coarse Aggregate',
              'question': 'Grading requirement',
              'type': 'YES_NO',
              'requiresRemark': true,
              'requiresPhoto': false
            },

            // Fine Aggregate Testing
            {
              'id': 'road_fa_1',
              'category': 'Fine Aggregate',
              'question': 'Deleterious materials',
              'type': 'YES_NO',
              'requiresRemark': true,
              'requiresPhoto': false
            },

            // Bitumen Testing
            {
              'id': 'road_bit_1',
              'category': 'Bitumen',
              'subCategory': "Manufacturer's certificate",
              'question': 'Specific gravity at 27° C',
              'type': 'YES_NO',
              'requiresRemark': true,
              'requiresPhoto': false
            },
            {
              'id': 'road_bit_2',
              'category': 'Bitumen',
              'subCategory': "Manufacturer's certificate",
              'question': 'Water content',
              'type': 'YES_NO',
              'requiresRemark': true,
              'requiresPhoto': false
            },
            {
              'id': 'road_bit_3',
              'category': 'Bitumen',
              'subCategory': "Manufacturer's certificate",
              'question': 'Flush point',
              'type': 'YES_NO',
              'requiresRemark': true,
              'requiresPhoto': false
            },
            {
              'id': 'road_bit_4',
              'category': 'Bitumen',
              'subCategory': "Manufacturer's certificate",
              'question': 'Softening point',
              'type': 'YES_NO',
              'requiresRemark': true,
              'requiresPhoto': false
            },
            {
              'id': 'road_bit_5',
              'category': 'Bitumen',
              'subCategory': "Manufacturer's certificate",
              'question': 'Penetration at 25°C',
              'type': 'YES_NO',
              'requiresRemark': true,
              'requiresPhoto': false
            },
            {
              'id': 'road_bit_6',
              'category': 'Bitumen',
              'subCategory': "Manufacturer's certificate",
              'question': 'Ductility at 27°C',
              'type': 'YES_NO',
              'requiresRemark': true,
              'requiresPhoto': false
            },
            {
              'id': 'road_bit_7',
              'category': 'Bitumen',
              'subCategory': "Manufacturer's certificate",
              'question': 'Loss of heating',
              'type': 'YES_NO',
              'requiresRemark': true,
              'requiresPhoto': false
            },
            {
              'id': 'road_bit_8',
              'category': 'Bitumen',
              'subCategory': "Manufacturer's certificate",
              'question': 'Residue of specified penetration',
              'type': 'YES_NO',
              'requiresRemark': true,
              'requiresPhoto': false
            },
            {
              'id': 'road_bit_9',
              'category': 'Bitumen',
              'subCategory': "Manufacturer's certificate",
              'question': 'Solubility in carbon-di-sulphide or trichlorothylene',
              'type': 'YES_NO',
              'requiresRemark': true,
              'requiresPhoto': false
            },

            // Embankment Testing
            {
              'id': 'road_emb_1',
              'category': 'Embankment',
              'subCategory': 'OMC conditions',
              'question': 'Moisture content',
              'type': 'YES_NO',
              'requiresRemark': true,
              'requiresPhoto': false
            },
            {
              'id': 'road_emb_2',
              'category': 'Embankment',
              'subCategory': 'OMC conditions',
              'question': 'Density',
              'type': 'YES_NO',
              'requiresRemark': true,
              'requiresPhoto': false
            },
            {
              'id': 'road_emb_3',
              'category': 'Embankment',
              'subCategory': 'OMC conditions',
              'question': 'Control test on borrow pits',
              'type': 'YES_NO',
              'requiresRemark': true,
              'requiresPhoto': false
            },

            // Layout and Construction
            {
              'id': 'road_lay_1',
              'question': 'Layout of road is correlated with architectural drawing',
              'type': 'YES_NO',
              'requiresRemark': true,
              'requiresPhoto': true
            },
            {
              'id': 'road_lay_2',
              'question': 'Proper level is maintained by cutting or filling the earth work',
              'type': 'YES_NO',
              'requiresRemark': true,
              'requiresPhoto': true
            },
            {
              'id': 'road_lay_3',
              'question': 'The sub-grade/embankment have been consolidated with a power road roller of 8 to 12 tonnes (The roller should pass at least 5 runs on the sub-grade)',
              'type': 'YES_NO',
              'requiresRemark': true,
              'requiresPhoto': true
            },

            // Surface Quality Checks
            {
              'id': 'road_surf_1',
              'category': 'Surface Quality',
              'question': 'Longitudinal Profile maximum permissible undulation when measured with 3m straight edge - 24 mm',
              'type': 'YES_NO',
              'requiresRemark': true,
              'requiresPhoto': true,
              'requiresMeasurement': true
            },
            {
              'id': 'road_surf_2',
              'category': 'Surface Quality',
              'question': 'Cross Profile maximum permissible variation from specified profile when measured with a camber template - 15 mm',
              'type': 'YES_NO',
              'requiresRemark': true,
              'requiresPhoto': true,
              'requiresMeasurement': true
            },

            // Construction Process
            {
              'id': 'road_const_1',
              'question': 'Stone aggregate is stacked in convenient units of 1 m top width, 2.20 m bottom width, 60 cm height and of length in multiple of 3 m',
              'type': 'YES_NO',
              'requiresRemark': true,
              'requiresPhoto': true
            },
            {
              'id': 'road_const_2',
              'question': 'The stack is uniformly distributed along the road and has been numbered serially',
              'type': 'YES_NO',
              'requiresRemark': true,
              'requiresPhoto': true
            }
          ]
        },

        // Cement Concrete Pavement Section
        {
          'title': 'Cement Concrete Pavement',
          'description': 'Testing of following materials',
          'questions': [
            // Water Testing
            {
              'id': 'cc_water_1',
              'category': 'Water',
              'question': 'Organic/inorganic testing done',
              'type': 'YES_NO',
              'requiresRemark': true,
              'requiresReport': true,
              'reportDescription': 'Enclose brief report & the date of testing'
            },
            {
              'id': 'cc_water_2',
              'category': 'Water',
              'question': 'Sulphate testing done',
              'type': 'YES_NO',
              'requiresRemark': true,
              'requiresReport': true
            },
            {
              'id': 'cc_water_3',
              'category': 'Water',
              'question': 'Chloride testing done',
              'type': 'YES_NO',
              'requiresRemark': true,
              'requiresReport': true
            },
            {
              'id': 'cc_water_4',
              'category': 'Water',
              'question': 'Suspended matter testing done',
              'type': 'YES_NO',
              'requiresRemark': true,
              'requiresReport': true
            },
            {
              'id': 'cc_water_5',
              'category': 'Water',
              'question': 'PH-value testing done',
              'type': 'YES_NO',
              'requiresRemark': true,
              'requiresReport': true
            },

            // Cement Testing
            {
              'id': 'cc_cement_1',
              'category': 'Cement',
              'question': "Manufacturer's Certificate verified",
              'type': 'YES_NO',
              'requiresRemark': true,
              'requiresReport': true
            },
            {
              'id': 'cc_cement_2',
              'category': 'Cement',
              'question': 'Fineness testing done',
              'type': 'YES_NO',
              'requiresRemark': true,
              'requiresReport': true
            }
          ]
        }
      ]
    };

    // Create or update the template
    try {
      final querySnapshot = await _firestore
          .collection('survey_templates')
          .where('type', isEqualTo: 'ROAD')
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        // Create new template
        await _firestore.collection('survey_templates').add(template);
      } else {
        // Update existing template
        await querySnapshot.docs.first.reference.update({
          'sections': template['sections'],
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      throw Exception('Failed to create/update survey template: $e');
    }
  }

  Future<void> deleteSurveyTemplate(String templateId) async {
    try {
      await _firestore.collection('survey_templates').doc(templateId).delete();
    } catch (e) {
      throw Exception('Failed to delete survey template: $e');
    }
  }

  Stream<QuerySnapshot> getSurveyTemplates() {
    return _firestore
        .collection('survey_templates')
        .where('isActive', isEqualTo: true)
        .snapshots();
  }

  Future<DocumentSnapshot> getSurveyTemplate(String templateId) {
    return _firestore.collection('survey_templates').doc(templateId).get();
  }

  Future<void> updateSurveyTemplateStatus(String templateId, bool isActive) async {
    try {
      await _firestore
          .collection('survey_templates')
          .doc(templateId)
          .update({'isActive': isActive});
    } catch (e) {
      throw Exception('Failed to update template status: $e');
    }
  }

  Future<void> addQuestionToTemplate(
      String templateId, String sectionTitle, Map<String, dynamic> question) async {
    try {
      final template =
          await _firestore.collection('survey_templates').doc(templateId).get();
      final sections = List.from(template.data()!['sections']);

      final sectionIndex =
          sections.indexWhere((section) => section['title'] == sectionTitle);
      if (sectionIndex != -1) {
        sections[sectionIndex]['questions'].add(question);
        await _firestore
            .collection('survey_templates')
            .doc(templateId)
            .update({'sections': sections});
      }
    } catch (e) {
      throw Exception('Failed to add question to template: $e');
    }
  }
}