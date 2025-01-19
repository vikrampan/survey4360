// lib/screens/surveyor/pending_sync_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:survey_app/models/survey_model.dart';
import 'package:survey_app/models/project_model.dart';
import 'package:survey_app/services/auth_service.dart';

class PendingSyncScreen extends StatefulWidget {
  const PendingSyncScreen({Key? key}) : super(key: key);

  @override
  _PendingSyncScreenState createState() => _PendingSyncScreenState();
}

class _PendingSyncScreenState extends State<PendingSyncScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  bool _isGlobalSyncing = false;
  
  Set<String> _selectedSurveys = {};

  Future<Map<String, dynamic>> _getSurveyProjectDetails(SurveyModel survey) async {
    final projectDoc = await _firestore
        .collection('projects')
        .doc(survey.projectId)
        .get();
    
    final projectData = ProjectModel.fromMap(
      projectDoc.data() as Map<String, dynamic>, 
      projectDoc.id,
    );

    return {
      'project': projectData,
      'survey': survey,
    };
  }

  Future<void> _performGlobalSync() async {
    if (_selectedSurveys.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select surveys to sync')),
      );
      return;
    }

    setState(() {
      _isGlobalSyncing = true;
    });

    try {
      final user = await _authService.getCurrentUser();
      if (user == null) return;

      for (String surveyId in _selectedSurveys) {
        await _firestore.collection('surveys').doc(surveyId).update({
          'needsSync': false,
          'isSubmitted': true,
          'completedAt': Timestamp.now(),
        });
      }

      setState(() {
        _selectedSurveys.clear();
        _isGlobalSyncing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_selectedSurveys.length} surveys synced successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isGlobalSyncing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sync failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _syncIndividualSurvey(String surveyId) async {
    try {
      await _firestore.collection('surveys').doc(surveyId).update({
        'needsSync': false,
        'isSubmitted': true,
        'completedAt': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Survey synced successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sync failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _getStatusColor(SurveyStatus status) {
    switch (status) {
      case SurveyStatus.pending:
        return Colors.orange;
      case SurveyStatus.inProgress:
        return Colors.blue;
      case SurveyStatus.completed:
        return Colors.green;
      case SurveyStatus.needsRevision:
        return Colors.red;
      case SurveyStatus.approved:
        return Colors.purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Syncs'),
        actions: [
          if (_selectedSurveys.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.sync),
              onPressed: _performGlobalSync,
              tooltip: 'Sync Selected Surveys',
            ),
        ],
      ),
      body: FutureBuilder<dynamic>(
        future: () async {
          final user = await _authService.getCurrentUser();
          if (user == null) return null;

          final surveysSnapshot = await _firestore
              .collection('surveys')
              .where('surveyorId', isEqualTo: user.uid)
              .where('needsSync', isEqualTo: true)
              .orderBy('createdAt', descending: true)
              .get();

          // Fetch project details for each survey
          return Future.wait(
            surveysSnapshot.docs.map((doc) async {
              final survey = SurveyModel.fromMap(
                doc.data() as Map<String, dynamic>, 
                doc.id,
              );
              return await _getSurveyProjectDetails(survey);
            }),
          );
        }(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null || snapshot.data.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_done,
                    size: 100,
                    color: Colors.green,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'All Surveys Synced',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'You have no pending syncs',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data.length,
            itemBuilder: (context, index) {
              final data = snapshot.data[index];
              final survey = data['survey'] as SurveyModel;
              final project = data['project'] as ProjectModel;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: CheckboxListTile(
                  value: _selectedSurveys.contains(survey.id),
                  onChanged: (bool? selected) {
                    setState(() {
                      if (selected == true) {
                        _selectedSurveys.add(survey.id);
                      } else {
                        _selectedSurveys.remove(survey.id);
                      }
                    });
                  },
                  secondary: IconButton(
                    icon: const Icon(Icons.sync, color: Colors.orange),
                    onPressed: () => _syncIndividualSurvey(survey.id),
                    tooltip: 'Sync Individual Survey',
                  ),
                  title: Text(
                    project.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Survey #${survey.id.substring(survey.id.length - 6)}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      Text(
                        'Created: ${survey.createdAt.toString().split(' ')[0]}',
                      ),
                    ],
                  ),
                  controlAffinity: ListTileControlAffinity.trailing,
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: _selectedSurveys.isNotEmpty
          ? Container(
              color: Colors.blue.shade50,
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_selectedSurveys.length} surveys selected',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton(
                    onPressed: _performGlobalSync,
                    child: _isGlobalSyncing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Sync Selected'),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  IconData _getStatusIcon(SurveyStatus status) {
    switch (status) {
      case SurveyStatus.pending:
        return Icons.pending_outlined;
      case SurveyStatus.inProgress:
        return Icons.play_circle_outline;
      case SurveyStatus.completed:
        return Icons.check_circle_outline;
      case SurveyStatus.needsRevision:
        return Icons.error_outline;
      case SurveyStatus.approved:
        return Icons.verified_outlined;
    }
  }
}