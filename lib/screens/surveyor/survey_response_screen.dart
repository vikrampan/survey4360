// lib/screens/surveyor/survey_response_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:survey_app/services/photo_service.dart';

class SurveyResponseScreen extends StatefulWidget {
  final String surveyId;
  final String projectId;

  const SurveyResponseScreen({
    Key? key,
    required this.surveyId,
    required this.projectId,
  }) : super(key: key);

  @override
  State<SurveyResponseScreen> createState() => _SurveyResponseScreenState();
}

class _SurveyResponseScreenState extends State<SurveyResponseScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final PhotoService _photoService = PhotoService();
  final Map<String, TextEditingController> _controllers = {};
  
  bool _isLoading = true;
  bool _isSaving = false;
  Map<String, dynamic>? _surveyTemplate;
  Map<String, dynamic> _responses = {};
  Map<String, String> _photoUrls = {};
  int _currentSectionIndex = 0;
  Map<int, bool> _sectionValidityMap = {};

  @override
  void initState() {
    super.initState();
    _loadSurveyTemplate();
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _getController(String questionId) {
    if (!_controllers.containsKey(questionId)) {
      _controllers[questionId] = TextEditingController(
        text: _responses[questionId]?.toString() ?? '',
      );
    }
    return _controllers[questionId]!;
  }

  // Add validation for entire section
  bool _validateSection(List<dynamic> questions) {
    bool isValid = true;
    
    for (var question in questions) {
      final String questionId = question['id'];
      final bool requiresPhoto = question['requiresPhoto'] ?? false;
      final bool requiresRemark = question['requiresRemark'] ?? false;
      final String questionType = question['type'] ?? 'TEXT';

      // Validate main response
      if (questionType == 'YES_NO') {
        final response = _responses[questionId]?.toString().toLowerCase();
        if (response != 'yes' && response != 'no') {
          isValid = false;
        }
      } else {
        if (!_responses.containsKey(questionId) || 
            _responses[questionId] == null || 
            _responses[questionId].toString().trim().isEmpty) {
          isValid = false;
        }
      }

      // Validate photo if required
      if (requiresPhoto) {
        if (!_photoUrls.containsKey(questionId) || 
            _photoUrls[questionId] == null || 
            _photoUrls[questionId]!.isEmpty) {
          isValid = false;
        }
      }

      // Validate remark if required
      if (requiresRemark) {
        final remarkId = '${questionId}_remark';
        if (!_responses.containsKey(remarkId) || 
            _responses[remarkId] == null || 
            _responses[remarkId].toString().trim().isEmpty) {
          isValid = false;
        }
      }
    }

    return isValid;
  }

  Future<void> _loadSurveyTemplate() async {
    try {
      print('Loading survey template...');
      
      final projectDoc = await _firestore
          .collection('projects')
          .doc(widget.projectId)
          .get();

      if (!projectDoc.exists) {
        throw 'Project not found';
      }

      final projectData = projectDoc.data() as Map<String, dynamic>;
      print('Project data type: ${projectData['type']}');

      var templatesSnapshot = await _firestore
          .collection('survey_templates')
          .where('type', isEqualTo: 'CONSTRUCTION')
          .get();

      if (templatesSnapshot.docs.isEmpty) {
        print('No CONSTRUCTION template found, checking all templates:');
        final allTemplates = await _firestore
            .collection('survey_templates')
            .get();
        
        for (var doc in allTemplates.docs) {
          print('Template ID: ${doc.id}, Type: ${doc.data()['type']}');
        }
        throw 'No survey template found';
      }

      final surveyDoc = await _firestore
          .collection('surveys')
          .doc(widget.surveyId)
          .get();

      if (surveyDoc.exists) {
        final surveyData = surveyDoc.data();
        if (surveyData != null) {
          setState(() {
            _responses = Map<String, dynamic>.from(surveyData['responses'] ?? {});
            _photoUrls = Map<String, String>.from(surveyData['photoUrls'] ?? {});
          });

          // Initialize controllers with existing responses including remarks
          for (var entry in _responses.entries) {
            _getController(entry.key).text = entry.value.toString();
          }
        }
      }

      setState(() {
        _surveyTemplate = templatesSnapshot.docs.first.data();
        _isLoading = false;
        
        // Initialize section validity map
        final sections = _surveyTemplate?['sections'] ?? [];
        for (int i = 0; i < sections.length; i++) {
          _sectionValidityMap[i] = _validateSection(sections[i]['questions']);
        }
      });

    } catch (e) {
      print('Error loading survey: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading survey: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveSurveyProgress() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // Update responses map with current remark values
      for (var section in _surveyTemplate?['sections'] ?? []) {
        for (var question in section['questions']) {
          if (question['requiresRemark'] == true) {
            final remarkId = '${question['id']}_remark';
            _responses[remarkId] = _getController(remarkId).text.trim();
          }
        }
      }

      await _firestore.collection('surveys').doc(widget.surveyId).update({
        'responses': _responses,
        'photoUrls': _photoUrls,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Progress saved successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving progress: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _takePhoto(String questionId) async {
    try {
      final photoUrl = await _photoService.showPhotoOptions(
        context: context,
        surveyId: widget.surveyId,
        questionId: questionId,
      );

      if (photoUrl != null) {
        setState(() {
          _photoUrls[questionId] = photoUrl;
          
          // Update section validity
          final sections = _surveyTemplate?['sections'] ?? [];
          _sectionValidityMap[_currentSectionIndex] = 
              _validateSection(sections[_currentSectionIndex]['questions']);
        });

        // Save progress after each photo
        await _firestore.collection('surveys').doc(widget.surveyId).update({
          'photoUrls': _photoUrls,
          'lastUpdated': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Photo saved successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('Error taking photo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitSurvey() async {
    final sections = _surveyTemplate?['sections'] ?? [];
    bool isValid = true;
    List<String> missingFields = [];

    // Validate all sections
    for (int sectionIndex = 0; sectionIndex < sections.length; sectionIndex++) {
      final section = sections[sectionIndex];
      for (var question in section['questions']) {
        final String questionId = question['id'];
        final bool requiresPhoto = question['requiresPhoto'] ?? false;
        final bool requiresRemark = question['requiresRemark'] ?? false;
        final String questionType = question['type'] ?? 'TEXT';
        
        // Check main response
        if (questionType == 'YES_NO') {
          final response = _responses[questionId]?.toString().toLowerCase();
          if (response != 'yes' && response != 'no') {
            isValid = false;
            missingFields.add('${section['title']}: ${question['question']} (Answer required)');
          }
        } else {
          if (!_responses.containsKey(questionId) || 
              _responses[questionId] == null || 
              _responses[questionId].toString().trim().isEmpty) {
            isValid = false;
            missingFields.add('${section['title']}: ${question['question']} (Answer required)');
          }
        }

        // Check required photos
        if (requiresPhoto) {
          if (!_photoUrls.containsKey(questionId) || 
              _photoUrls[questionId] == null || 
              _photoUrls[questionId]!.isEmpty) {
            isValid = false;
            missingFields.add('${section['title']}: ${question['question']} (Photo required)');
          }
        }

        // Check required remarks
        if (requiresRemark) {
          final remarkId = '${questionId}_remark';
          final remarkValue = _getController(remarkId).text.trim();
          
          if (remarkValue.isEmpty) {
            isValid = false;
            missingFields.add('${section['title']}: ${question['question']} (Remarks required)');
          }
          _responses[remarkId] = remarkValue;
        }
      }
    }

    if (!isValid) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Missing Required Fields'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Please complete the following:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...missingFields.map((field) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    '• $field',
                    style: const TextStyle(fontSize: 14),
                  ),
                )),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    try {
      setState(() {
        _isSaving = true;
      });

      await _firestore.collection('surveys').doc(widget.surveyId).update({
        'responses': _responses,
        'photoUrls': _photoUrls,
        'status': 'completed',
        'isSubmitted': true,
        'completedAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Survey submitted successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error submitting survey: $e');
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting survey: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Widget _buildQuestionCard(Map<String, dynamic> question) {
    final String questionId = question['id'];
    final bool requiresPhoto = question['requiresPhoto'] ?? false;
    final bool requiresRemark = question['requiresRemark'] ?? false;
    final String questionType = question['type'] ?? 'TEXT';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    question['question'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (requiresPhoto)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _photoUrls.containsKey(questionId)
                          ? Colors.green.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _photoUrls.containsKey(questionId)
                              ? Icons.check_circle
                              : Icons.camera_alt,
                          size: 16,
                          color: _photoUrls.containsKey(questionId)
                              ? Colors.green
                              : Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _photoUrls.containsKey(questionId)
                              ? 'Photo Added'
                              : 'Photo Required',
                          style: TextStyle(
                            fontSize: 12,
                            color: _photoUrls.containsKey(questionId)
                                ? Colors.green
                                : Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            if (question['category'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Category: ${question['category']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            if (questionType == 'YES_NO')
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Yes'),
                        value: 'yes',
                        groupValue: _responses[questionId]?.toString().toLowerCase(),
                        onChanged: (value) {
                          setState(() {
                            _responses[questionId] = value;
                            // Update section validity
                            final sections = _surveyTemplate?['sections'] ?? [];
                            _sectionValidityMap[_currentSectionIndex] = 
                                _validateSection(sections[_currentSectionIndex]['questions']);
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('No'),
                        value: 'no',
                        groupValue: _responses[questionId]?.toString().toLowerCase(),
                        onChanged: (value) {
                          setState(() {
                            _responses[questionId] = value;
                            // Update section validity
                            final sections = _surveyTemplate?['sections'] ?? [];
                            _sectionValidityMap[_currentSectionIndex] = 
                                _validateSection(sections[_currentSectionIndex]['questions']);
                          });
                        },
                      ),
                    ),
                  ],
                ),
              )
            else if (questionType == 'NUMERIC')
              TextField(
                controller: _getController(questionId),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Enter number',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                onChanged: (value) {
                  setState(() {
                    _responses[questionId] = value;
                    // Update section validity
                    final sections = _surveyTemplate?['sections'] ?? [];
                    _sectionValidityMap[_currentSectionIndex] = 
                        _validateSection(sections[_currentSectionIndex]['questions']);
                  });
                },
              )
            else
              TextField(
                controller: _getController(questionId),
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Enter your response',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                onChanged: (value) {
                  setState(() {
                    _responses[questionId] = value;
                    // Update section validity
                    final sections = _surveyTemplate?['sections'] ?? [];
                    _sectionValidityMap[_currentSectionIndex] = 
                        _validateSection(sections[_currentSectionIndex]['questions']);
                  });
                },
              ),

            if (requiresPhoto) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add_a_photo),
                      label: Text(_photoUrls.containsKey(questionId) 
                        ? 'Change Photo' 
                        : 'Add Photo'
                      ),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => _takePhoto(questionId),
                    ),
                  ),
                  if (_photoUrls.containsKey(questionId)) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      color: Colors.red,
                      onPressed: () async {
                        if (_photoUrls.containsKey(questionId)) {
                          await _photoService.deletePhoto(_photoUrls[questionId]!);
                          setState(() {
                            _photoUrls.remove(questionId);
                            // Update section validity
                            final sections = _surveyTemplate?['sections'] ?? [];
                            _sectionValidityMap[_currentSectionIndex] = 
                                _validateSection(sections[_currentSectionIndex]['questions']);
                          });
                        }
                      },
                    ),
                  ],
                ],
              ),
              if (_photoUrls.containsKey(questionId))
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        Image.network(
                          _photoUrls[questionId]!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              height: 200,
                              width: double.infinity,
                              color: Colors.grey[200],
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 200,
                              width: double.infinity,
                              color: Colors.grey[200],
                              child: const Center(
                                child: Icon(Icons.error),
                              ),
                            );
                          },
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.fullscreen,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => Scaffold(
                                      appBar: AppBar(
                                        backgroundColor: Colors.black,
                                        iconTheme: const IconThemeData(color: Colors.white),
                                      ),
                                      body: Container(
                                        color: Colors.black,
                                        child: Center(
                                          child: InteractiveViewer(
                                            child: Image.network(
                                              _photoUrls[questionId]!,
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
            if (requiresRemark) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _getController('${questionId}_remark'),
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Remarks *',
                  hintText: 'Enter detailed remarks for this question',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  errorText: _responses['${questionId}_remark']?.toString().trim().isEmpty == true
                    ? 'Remarks are required'
                    : null,
                ),
                onChanged: (value) {
                  setState(() {
                    _responses['${questionId}_remark'] = value.trim();
                    // Update section validity
                    final sections = _surveyTemplate?['sections'] ?? [];
                    _sectionValidityMap[_currentSectionIndex] = 
                        _validateSection(sections[_currentSectionIndex]['questions']);
                  });
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final sections = _surveyTemplate?['sections'] ?? [];
    final currentSection = sections[_currentSectionIndex];
    final questions = currentSection['questions'] ?? [];
    final bool isSectionValid = _sectionValidityMap[_currentSectionIndex] ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(currentSection['title'] ?? 'Survey'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isSaving ? null : _saveSurveyProgress,
            tooltip: 'Save Progress',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.grey[100],
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(8),
              child: Row(
                children: List.generate(
                  sections.length,
                  (index) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(sections[index]['title']),
                          if (_sectionValidityMap[index] == true) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.check_circle,
                              size: 16,
                              color: Colors.green,
                            ),
                          ],
                        ],
                      ),
                      selected: index == _currentSectionIndex,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _currentSectionIndex = index;
                          });
                        }
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: questions.length,
              padding: const EdgeInsets.only(bottom: 100),
              itemBuilder: (context, index) {
                return _buildQuestionCard(questions[index]);
              },
            ),
          ),
          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentSectionIndex > 0)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Previous'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.black87,
                        backgroundColor: Colors.grey[200],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _currentSectionIndex--;
                        });
                      },
                    )
                  else
                    const SizedBox.shrink(),
                  if (_currentSectionIndex < sections.length - 1)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Next Section'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: isSectionValid ? Colors.blue : Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onPressed: isSectionValid
                          ? () {
                              setState(() {
                                _currentSectionIndex++;
                              });
                            }
                          : () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please complete all required fields in this section before proceeding',
                                  ),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            },
                    )
                  else
                    ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle),
                      label: Text(_isSaving ? 'Submitting...' : 'Submit Survey'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: isSectionValid ? Colors.green : Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      onPressed: (_isSaving || !isSectionValid) 
                          ? null 
                          : () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Confirm Submission'),
                                  content: const Text(
                                    'Are you sure you want to submit this survey? '
                                    'Once submitted, you won\'t be able to make further changes.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.grey[700],
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        _submitSurvey();
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: const Text('Submit'),
                                    ),
                                  ],
                                ),
                              );
                            },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}