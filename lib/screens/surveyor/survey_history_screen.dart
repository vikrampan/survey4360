// lib/screens/surveyor/survey_history_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:survey_app/models/survey_model.dart';
import 'package:survey_app/models/project_model.dart';
import 'package:survey_app/services/auth_service.dart';

class SurveyHistoryScreen extends StatefulWidget {
  const SurveyHistoryScreen({Key? key}) : super(key: key);

  @override
  _SurveyHistoryScreenState createState() => _SurveyHistoryScreenState();
}

class _SurveyHistoryScreenState extends State<SurveyHistoryScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  
  String _selectedFilter = 'All';
  final List<String> _filterOptions = ['All', 'Completed', 'Pending', 'Needs Revision'];

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
        title: const Text('Survey History'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _filterOptions.map((filter) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: ChoiceChip(
                            label: Text(filter),
                            selected: _selectedFilter == filter,
                            onSelected: (selected) {
                              setState(() {
                                _selectedFilter = filter;
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: FutureBuilder<dynamic>(
        future: () async {
          final user = await _authService.getCurrentUser();
          if (user == null) return null;

          Query query = _firestore
              .collection('surveys')
              .where('surveyorId', isEqualTo: user.uid);

          // Apply filter
          if (_selectedFilter != 'All') {
            final status = SurveyStatus.values.firstWhere(
              (e) => e.toString().split('.').last.toLowerCase() 
                == _selectedFilter.toLowerCase(),
            );
            query = query.where('status', isEqualTo: status.toString());
          }

          final surveysSnapshot = await query
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
              child: Text(
                'No surveys found',
                style: TextStyle(fontSize: 18),
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
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getStatusColor(survey.status).withOpacity(0.1),
                    child: Icon(
                      _getStatusIcon(survey.status),
                      color: _getStatusColor(survey.status),
                    ),
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
                  trailing: Text(
                    survey.status.toString().split('.').last,
                    style: TextStyle(
                      color: _getStatusColor(survey.status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () {
                    // TODO: Implement survey details view
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Survey details view coming soon'),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
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