// lib/screens/admin/filtered_list_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:survey_app/models/project_model.dart';
import 'package:survey_app/models/user_model.dart';
import 'package:survey_app/screens/admin/project_details_screen.dart';
import 'package:survey_app/screens/admin/surveyor_projects_screen.dart';

class FilteredListScreen extends StatelessWidget {
  final String title;
  final String type; // 'projects' or 'surveyors'
  final ProjectStatus? statusFilter;

  const FilteredListScreen({
    Key? key,
    required this.title,
    required this.type,
    this.statusFilter,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: type == 'projects' ? _buildProjectsList() : _buildSurveyorsList(),
    );
  }

  Widget _buildProjectsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getProjectsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          print('Error in stream: ${snapshot.error}');
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        final projects = _processProjectsData(snapshot);

        if (projects.isEmpty) {
          return _buildEmptyProjectsView();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: projects.length,
          itemBuilder: (context, index) => _buildProjectCard(context, projects[index]),
        );
      },
    );
  }

  Stream<QuerySnapshot> _getProjectsStream() {
    Query query = FirebaseFirestore.instance.collection('projects');
    
    if (statusFilter != null) {
      // Convert enum to the stored string format ("pending", "inProgress", "completed")
      String statusString = statusFilter.toString().split('.').last;
      print('Filtering projects by status: $statusString'); // Debug print
      query = query.where('status', isEqualTo: statusString);
    }
    
    return query.orderBy('createdAt', descending: true).snapshots();
  }

  List<ProjectModel> _processProjectsData(AsyncSnapshot<QuerySnapshot> snapshot) {
    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
      return [];
    }

    return snapshot.data!.docs.map((doc) {
      try {
        final data = doc.data() as Map<String, dynamic>;
        print('Processing document ${doc.id} with status: ${data['status']}'); // Debug print
        return ProjectModel.fromMap(data, doc.id);
      } catch (e) {
        print('Error processing project document ${doc.id}: $e');
        return null;
      }
    }).whereType<ProjectModel>().toList();
  }

  Widget _buildEmptyProjectsView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            statusFilter != null 
              ? 'No ${statusFilter.toString().split('.').last.toLowerCase()} projects found'
              : 'No projects found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          if (statusFilter != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Projects with ${statusFilter.toString().split('.').last.toLowerCase()} status will appear here',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProjectCard(BuildContext context, ProjectModel project) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProjectDetailsScreen(
                projectId: project.id,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: _getStatusColor(project.status).withOpacity(0.2),
                child: Icon(
                  Icons.assignment,
                  color: _getStatusColor(project.status),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            project.location,
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.business,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            project.contractorName,
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(project.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.people,
                            size: 16,
                            color: _getStatusColor(project.status),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${project.assignedSurveyors.length} Surveyors',
                            style: TextStyle(
                              color: _getStatusColor(project.status),
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSurveyorsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'surveyor')
          .where('isActive', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No active surveyors found',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final surveyor = UserModel.fromMap(
              snapshot.data!.docs[index].data() as Map<String, dynamic>,
              snapshot.data!.docs[index].id,
            );

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SurveyorProjectsScreen(
                        surveyor: surveyor,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.blue.shade100,
                        child: Text(
                          surveyor.name[0].toUpperCase(),
                          style: TextStyle(
                            color: Colors.blue.shade800,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              surveyor.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              surveyor.email,
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),
                            if (surveyor.phone != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                surveyor.phone!,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color _getStatusColor(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.pending:
        return Colors.orange;
      case ProjectStatus.inProgress:
        return Colors.blue;
      case ProjectStatus.completed:
        return Colors.green;
    }
  }
}