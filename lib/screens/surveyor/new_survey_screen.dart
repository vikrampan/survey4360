// lib/screens/surveyor/new_survey_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:survey_app/models/project_model.dart';
import 'package:survey_app/models/survey_model.dart' show SurveyStatus, SurveyModel;
// Removed the conflicting import
// import 'package:survey_app/screens/surveyor/road_survey_screen.dart';
import 'package:survey_app/services/auth_service.dart';
import 'package:survey_app/screens/surveyor/road_survey_screen.dart'; // Ensure this import does not conflict with SurveyStatus
import 'package:intl/intl.dart';

class NewSurveyScreen extends StatefulWidget {
  const NewSurveyScreen({super.key});

  @override
  State<NewSurveyScreen> createState() => _NewSurveyScreenState();
}

class _NewSurveyScreenState extends State<NewSurveyScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Surveys'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Assigned Surveys'),
              Tab(text: 'Survey History'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildAssignedSurveys(),
            _buildSurveyHistory(),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignedSurveys() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('survey_assignments')
          .where('surveyorId', isEqualTo: _currentUserId)
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, assignmentSnapshot) {
        if (assignmentSnapshot.hasError) {
          return Center(child: Text('Error: ${assignmentSnapshot.error}'));
        }

        if (assignmentSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!assignmentSnapshot.hasData || assignmentSnapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No Surveys Assigned',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text('New assignments will appear here'),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: assignmentSnapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final assignment = assignmentSnapshot.data!.docs[index];
            final assignmentData = assignment.data() as Map<String, dynamic>;

            return FutureBuilder<DocumentSnapshot>(
              future: _firestore
                  .collection('projects')
                  .doc(assignmentData['projectId'])
                  .get(),
              builder: (context, projectSnapshot) {
                if (!projectSnapshot.hasData) {
                  return const SizedBox();
                }

                final projectData = projectSnapshot.data!.data() as Map<String, dynamic>;

                return Card(
                  margin: const EdgeInsets.all(8),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    projectData['name'] ?? 'Untitled Project',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Location: ${projectData['location'] ?? 'N/A'}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Type: ${projectData['type'] ?? 'N/A'}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _buildStatusChip(assignmentData['status']),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Assigned: ${_formatDate(assignmentData['assignedDate'])}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                                if (assignmentData['dueDate'] != null)
                                  Text(
                                    'Due: ${_formatDate(assignmentData['dueDate'])}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                            ElevatedButton.icon(
                              onPressed: () => _startSurvey(
                                assignmentData['surveyId'],
                                assignmentData['projectId'],
                                assignment.id,
                              ),
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Start Survey'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSurveyHistory() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('surveys')
          .where('surveyorId', isEqualTo: _currentUserId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('No survey history'),
          );
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final survey = SurveyModel.fromMap(
              snapshot.data!.docs[index].data() as Map<String, dynamic>,
              snapshot.data!.docs[index].id,
            );

            return FutureBuilder<DocumentSnapshot>(
              future: _firestore
                  .collection('projects')
                  .doc(survey.projectId)
                  .get(),
              builder: (context, projectSnapshot) {
                if (!projectSnapshot.hasData) {
                  return const SizedBox();
                }

                final projectData = projectSnapshot.data!.data() as Map<String, dynamic>;

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getStatusColor(survey.status),
                      child: Icon(
                        _getStatusIcon(survey.status),
                        color: Colors.white,
                      ),
                    ),
                    title: Text(projectData['name'] ?? 'Untitled Project'),
                    subtitle: Text(
                      'Created: ${_formatDate(survey.createdAt)}\n'
                      'Status: ${survey.status}',
                    ),
                    isThreeLine: true,
                    trailing: IconButton(
                      icon: const Icon(Icons.arrow_forward),
                      onPressed: () => _viewSurvey(survey),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _startSurvey(
    String surveyId,
    String projectId,
    String assignmentId,
  ) async {
    try {
      // Update assignment status
      await _firestore
          .collection('survey_assignments')
          .doc(assignmentId)
          .update({'status': 'in_progress'});

      if (!mounted) return;
      
      // Navigate to survey screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RoadSurveyScreen(
            surveyId: surveyId,
            projectId: projectId,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error starting survey: $e')),
      );
    }
  }

  void _viewSurvey(SurveyModel survey) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoadSurveyScreen(
          surveyId: survey.id,
          projectId: survey.projectId,
          readOnly: true,
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'pending':
        color = Colors.orange;
        break;
      case 'in_progress':
        color = Colors.blue;
        break;
      case 'completed':
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
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
      default:
        return Colors.grey;
    }
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
      default:
        return Icons.help_outline;
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    if (date is Timestamp) {
      return DateFormat('MMM d, yyyy').format(date.toDate());
    }
    return 'N/A';
  }
}
