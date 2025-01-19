import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:survey_app/services/survey_response_service.dart';
import 'package:survey_app/services/offline_sync_service.dart';
import 'package:survey_app/services/photo_service.dart';
import 'package:survey_app/models/survey_response_model.dart';
import 'package:survey_app/models/survey_model.dart';
import 'package:intl/intl.dart'; // Added for date formatting

enum ReviewStatus { pending, approved, needsRevision, rejected }

class RoadSurveyScreen extends StatefulWidget {
  final String surveyId;
  final String projectId;
  final bool readOnly;
  final String? existingResponseId;

  const RoadSurveyScreen({
    super.key,
    required this.surveyId,
    required this.projectId,
    this.readOnly = false,
    this.existingResponseId,
  });

  @override
  State<RoadSurveyScreen> createState() => _RoadSurveyScreenState();
}

class _RoadSurveyScreenState extends State<RoadSurveyScreen> {
  final SurveyResponseService _responseService = SurveyResponseService();
  final OfflineSyncService _syncService = OfflineSyncService();
  final PhotoService _photoService = PhotoService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // State management
  final Map<String, bool> _responses = {};
  final Map<String, TextEditingController> _remarkControllers = {};
  final Map<String, List<String>> _photoUrls = {};
  final Map<String, TextEditingController> _reviewControllers = {};
  final Map<String, bool> _isQuestionValid = {};
  final Map<String, String> _followupActions = {};
  final Map<String, bool> _expandedSections = {};

  bool _isSubmitting = false;
  bool _isLoading = true;
  bool _isOnline = true;
  bool _showValidationErrors = false;
  double _completionPercentage = 0.0;
  String? _responseId;
  String _surveyStatus = 'draft';
  ReviewStatus _reviewStatus = ReviewStatus.pending;
  DateTime? _lastSaved;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _initializeSurvey();
  }

  @override
  void dispose() {
    for (var controller in _remarkControllers.values) {
      controller.dispose();
    }
    for (var controller in _reviewControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _initializeServices() async {
    try {
      await _syncService.initialize();
      _syncService.connectivityStream.listen((isOnline) {
        setState(() {
          _isOnline = isOnline;
        });
        if (isOnline) {
          _syncOfflineData();
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize services: $e';
      });
    }
  }

  Future<void> _syncOfflineData() async {
    if (!_isOnline) return;

    try {
      await _syncService.syncOfflineSurveys();
      setState(() {
        _lastSaved = DateTime.now();
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to sync data: $e';
      });
    }
  }

  Future<void> _initializeSurvey() async {
    try {
      if (widget.existingResponseId != null) {
        _responseId = widget.existingResponseId;
        await _loadExistingResponse();
      } else if (!widget.readOnly) {
        _responseId = await _responseService.createSurveyResponse(
          projectId: widget.projectId,
          surveyorId: FirebaseAuth.instance.currentUser!.uid,
          templateType: 'ROAD',
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize survey: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadExistingResponse() async {
    if (_responseId == null) return;

    try {
      final response = await _responseService.getSurveyResponse(_responseId!).first;
      if (response.exists) {
        final data = response.data() as Map<String, dynamic>;
        setState(() {
          _surveyStatus = data['status'] ?? 'draft';
          _reviewStatus = _getReviewStatus(data['reviewStatus']);

          if (data['responses'] != null) {
            for (var response in (data['responses'] as List)) {
              final questionId = response['questionId'];
              _responses[questionId] = response['response'];
              _remarkControllers[questionId] = TextEditingController(
                text: response['remarks'] ?? ''
              );
              _photoUrls[questionId] = List<String>.from(response['photoUrls'] ?? []);
              _followupActions[questionId] = response['followupAction'] ?? '';

              if (widget.readOnly) {
                _reviewControllers[questionId] = TextEditingController(
                  text: response['reviewComment'] ?? ''
                );
              }
            }
          }
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load response: $e';
      });
    }
  }

  ReviewStatus _getReviewStatus(String? status) {
    switch (status) {
      case 'approved':
        return ReviewStatus.approved;
      case 'needs_revision':
        return ReviewStatus.needsRevision;
      case 'rejected':
        return ReviewStatus.rejected;
      default:
        return ReviewStatus.pending;
    }
  }

  // Implement the missing methods
  String _formatTime(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
  }

  Future<void> _submitSurvey(List<dynamic> responses) async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      await _responseService.updateSurveyResponse(
        _responseId!,
        responses,
        _surveyStatus,
      );
      setState(() {
        _lastSaved = DateTime.now();
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to submit survey: $e';
      });
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Widget _buildProgressIndicator() {
    return LinearPercentIndicator(
      width: MediaQuery.of(context).size.width - 40,
      lineHeight: 8.0,
      percent: _completionPercentage,
      backgroundColor: Colors.grey[300],
      progressColor: Colors.blue,
    );
  }

  void _updateProgress(List<dynamic> sections) {
    int completedSections = 0;
    for (var section in sections) {
      if (_responses[section['id']] != null) {
        completedSections++;
      }
    }
    setState(() {
      _completionPercentage = completedSections / sections.length;
    });
  }

  Widget _buildSurveyForm(List<dynamic> sections) {
    return ListView.builder(
      itemCount: sections.length,
      itemBuilder: (context, index) {
        final section = sections[index];
        return ExpansionTile(
          title: Text(section['title']),
          children: [
            // Add form fields for each question in the section
          ],
        );
      },
    );
  }

  Widget _buildReviewPanel() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Review Comments',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          // Add review comments and actions
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.readOnly ? 'Review Survey' : 'Road Survey'),
        actions: [
          if (!_isOnline)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(Icons.cloud_off, color: Colors.orange),
            ),
          if (_lastSaved != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Last saved: ${_formatTime(_lastSaved!)}',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          if (!_isSubmitting && !widget.readOnly)
            TextButton.icon(
              onPressed: () => _submitSurvey([]),
              icon: const Icon(Icons.save, color: Colors.white),
              label: const Text(
                'Submit',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                      ElevatedButton(
                        onPressed: _initializeSurvey,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildProgressIndicator(),
                      Expanded(
                        child: StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('survey_templates')
                              .doc(widget.surveyId)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Center(
                                child: Text('Error: ${snapshot.error}'),
                              );
                            }

                            if (!snapshot.hasData) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            final template = snapshot.data!.data() 
                                as Map<String, dynamic>;
                            final sections = template['sections'] as List;
                            _updateProgress(sections);

                            return _buildSurveyForm(sections);
                          },
                        ),
                      ),
                      if (widget.readOnly) _buildReviewPanel(),
                    ],
                  ),
                ),
    );
  }
}
