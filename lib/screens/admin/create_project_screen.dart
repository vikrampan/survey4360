// lib/screens/admin/create_project_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:survey_app/models/project_model.dart';
import 'package:survey_app/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:survey_app/models/survey_template_model.dart';
import 'package:survey_app/utils/survey_template_generator.dart';
import 'package:survey_app/screens/admin/survey_template_editor_screen.dart';

class CreateProjectScreen extends StatefulWidget {
  const CreateProjectScreen({Key? key}) : super(key: key);

  @override
  _CreateProjectScreenState createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _contractorNameController = TextEditingController();
  final _contractorContactController = TextEditingController();

  ProjectType _selectedProjectType = ProjectType.road;
  DateTime _startDate = DateTime.now();
  List<String> _assignedSurveyors = [];
  bool _isLoading = false;
  SurveyTemplate? _surveyTemplate;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _surveyTemplate = SurveyTemplateGenerator.generateConstructionSurveyTemplate();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _contractorNameController.dispose();
    _contractorContactController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _editSurveyTemplate() async {
    if (_surveyTemplate == null) return;

    final result = await Navigator.push<SurveyTemplate>(
      context,
      MaterialPageRoute(
        builder: (context) => SurveyTemplateEditorScreen(
          template: _surveyTemplate!,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _surveyTemplate = result;
      });
    }
  }

  Future<void> _selectSurveyors() async {
    try {
      final surveyorsSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'surveyor')
          .where('isActive', isEqualTo: true)
          .get();

      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('Select Surveyors'),
                content: SizedBox(
                  width: double.maxFinite,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: surveyorsSnapshot.docs.map((doc) {
                        final surveyorId = doc.id;
                        final surveyorName = doc.data()['name'] ?? 'Unknown';
                        final surveyorEmail = doc.data()['email'] ?? '';
                        return CheckboxListTile(
                          value: _assignedSurveyors.contains(surveyorId),
                          title: Text(surveyorName),
                          subtitle: Text(surveyorEmail),
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                _assignedSurveyors.add(surveyorId);
                              } else {
                                _assignedSurveyors.remove(surveyorId);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Done'),
                  ),
                ],
              );
            },
          );
        },
      );

      // Update parent widget state
      setState(() {});
    } catch (e) {
      print('Error selecting surveyors: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading surveyors: ${e.toString()}')),
      );
    }
  }

  Future<void> _createProject() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_assignedSurveyors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one surveyor')),
      );
      return;
    }

    if (_surveyTemplate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Survey template is required')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception('No user logged in');

      // Create project data
      final projectData = {
        'name': _nameController.text.trim(),
        'location': _locationController.text.trim(),
        'type': _selectedProjectType.toString().split('.').last.toLowerCase(),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': currentUser.uid,
        'assignedSurveyors': _assignedSurveyors,
        'contractorName': _contractorNameController.text.trim(),
        'contractorContact': _contractorContactController.text.trim(),
        'startDate': Timestamp.fromDate(_startDate),
        'endDate': null,
        'isActive': true,
      };

      // Use a batched write for atomic operations
      final batch = _firestore.batch();

      // Create project document
      final projectRef = _firestore.collection('projects').doc();
      batch.set(projectRef, projectData);

      // Convert template to Firestore data
      final templateData = {
        'projectId': projectRef.id,
        'type': _surveyTemplate!.type,
        'createdAt': FieldValue.serverTimestamp(),
        'sections': _surveyTemplate!.sections.map((section) => {
          'title': section.title,
          'description': section.description,
          'questions': section.questions.map((question) => {
            'id': question.id,
            'question': question.question,
            'type': question.type,
            'requiresPhoto': question.requiresPhoto,
            'requiresRemark': question.requiresRemark,
            'category': question.category,
            'subCategory': question.subCategory,
          }).toList(),
        }).toList(),
        'isActive': true,
      };

      // Create survey template
      final templateRef = _firestore.collection('survey_templates').doc();
      batch.set(templateRef, templateData);

      // Create surveys for each surveyor
      for (String surveyorId in _assignedSurveyors) {
        final surveyRef = _firestore.collection('surveys').doc();
        batch.set(surveyRef, {
          'projectId': projectRef.id,
          'surveyorId': surveyorId,
          'templateId': templateRef.id,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
          'responses': {}, // Will store responses to questions
          'attachments': [], // Will store photos
          'isSubmitted': false,
          'needsSync': false,
        });
      }

      // Commit the batch
      await batch.commit();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Project created successfully')),
      );
      
      Navigator.pop(context, true);
    } catch (e) {
      print('Error creating project: $e');
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating project: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Project'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Project Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter project name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Project Location',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter project location';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ProjectType>(
                decoration: const InputDecoration(
                  labelText: 'Project Type',
                  border: OutlineInputBorder(),
                ),
                value: _selectedProjectType,
                items: ProjectType.values
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type.toString().split('.').last),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedProjectType = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contractorNameController,
                decoration: const InputDecoration(
                  labelText: 'Contractor Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter contractor name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contractorContactController,
                decoration: const InputDecoration(
                  labelText: 'Contractor Contact',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter contractor contact';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Start Date: ${_startDate.toLocal()}'.split(' ')[0],
                    ),
                  ),
                  TextButton(
                    onPressed: () => _selectStartDate(context),
                    child: const Text('Select Date'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _selectSurveyors,
                icon: const Icon(Icons.people),
                label: Text(
                  'Assign Surveyors (${_assignedSurveyors.length})',
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _editSurveyTemplate,
                icon: const Icon(Icons.edit_note),
                label: const Text('Preview/Edit Survey Template'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _createProject,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Create Project'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}