// lib/screens/admin/project_details_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:survey_app/models/project_model.dart';
import 'package:survey_app/models/user_model.dart';
import 'package:survey_app/models/survey_template_model.dart';

class ProjectDetailsScreen extends StatefulWidget {
  final String projectId;

  const ProjectDetailsScreen({Key? key, required this.projectId}) : super(key: key);

  @override
  _ProjectDetailsScreenState createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int? _selectedPanelIndex;

  Future<void> _updateProjectStatus(ProjectStatus newStatus) async {
    try {
      await _firestore
          .collection('projects')
          .doc(widget.projectId)
          .update({
        'status': newStatus.toString().split('.').last,
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Project status updated to ${newStatus.toString().split('.').last}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating project status: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showEditProjectDialog(ProjectModel project) async {
    final nameController = TextEditingController(text: project.name);
    final locationController = TextEditingController(text: project.location);
    final contractorNameController = TextEditingController(text: project.contractorName);
    final contractorContactController = TextEditingController(text: project.contractorContact);

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Project Details'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Project Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: contractorNameController,
                  decoration: const InputDecoration(
                    labelText: 'Contractor Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: contractorContactController,
                  decoration: const InputDecoration(
                    labelText: 'Contractor Contact',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey,
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _firestore
                      .collection('projects')
                      .doc(widget.projectId)
                      .update({
                    'name': nameController.text.trim(),
                    'location': locationController.text.trim(),
                    'contractorName': contractorNameController.text.trim(),
                    'contractorContact': contractorContactController.text.trim(),
                  });

                  if (!mounted) return;
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Project details updated'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error updating project: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Save'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final projectSnapshot = await _firestore
                  .collection('projects')
                  .doc(widget.projectId)
                  .get();
              
              if (!projectSnapshot.exists) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Project not found'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              final project = ProjectModel.fromMap(
                projectSnapshot.data()!, 
                projectSnapshot.id,
              );
              
              if (!mounted) return;
              _showEditProjectDialog(project);
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('projects').doc(widget.projectId).snapshots(),
        builder: (context, projectSnapshot) {
          if (projectSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!projectSnapshot.hasData || !projectSnapshot.data!.exists) {
            return const Center(
              child: Text(
                'Project not found',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          final project = ProjectModel.fromMap(
            projectSnapshot.data!.data() as Map<String, dynamic>, 
            projectSnapshot.data!.id,
          );

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProjectSummaryCard(project),
                  const SizedBox(height: 16),
                  _buildProjectStatusSection(project),
                  const SizedBox(height: 16),
                  _buildContractorInfoCard(project),
                  const SizedBox(height: 16),
                  _buildAssignedSurveyorsSection(project),
                  const SizedBox(height: 16),
                  _buildSurveyQuestionsSection(project),
                  const SizedBox(height: 32), // Bottom padding
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  Widget _buildProjectSummaryCard(ProjectModel project) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              project.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              icon: Icons.location_on,
              iconColor: Colors.blue,
              label: 'Location',
              value: project.location,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              icon: Icons.category,
              iconColor: Colors.green,
              label: 'Type',
              value: project.type.toString().split('.').last,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              icon: Icons.calendar_today,
              iconColor: Colors.orange,
              label: 'Start Date',
              value: project.startDate.toLocal().toString().split(' ')[0],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProjectStatusSection(ProjectModel project) {
    final statusColor = {
      ProjectStatus.pending: Colors.orange,
      ProjectStatus.inProgress: Colors.blue,
      ProjectStatus.completed: Colors.green,
    }[project.status];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Project Status',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: statusColor?.withOpacity(0.1),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<ProjectStatus>(
                      value: project.status,
                      items: ProjectStatus.values
                          .map((status) => DropdownMenuItem(
                                value: status,
                                child: Text(
                                  status.toString().split('.').last,
                                  style: TextStyle(
                                    color: {
                                      ProjectStatus.pending: Colors.orange,
                                      ProjectStatus.inProgress: Colors.blue,
                                      ProjectStatus.completed: Colors.green,
                                    }[status],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ))
                          .toList(),
                      onChanged: (status) {
                        if (status != null) {
                          _updateProjectStatus(status);
                        }
                      },
                      icon: Icon(
                        Icons.arrow_drop_down,
                        color: statusColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContractorInfoCard(ProjectModel project) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Contractor Information',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildContactRow(
              icon: Icons.person,
              label: 'Name',
              value: project.contractorName,
            ),
            const SizedBox(height: 12),
            _buildContactRow(
              icon: Icons.phone,
              label: 'Contact',
              value: project.contractorContact,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).primaryColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAssignedSurveyorsSection(ProjectModel project) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Assigned Surveyors',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showAssignSurveyorsDialog(project),
                  icon: const Icon(Icons.edit),
                  label: const Text('Manage'),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            project.assignedSurveyors.isEmpty
                ? const Center(
                    child: Text(
                      'No surveyors assigned',
                      style: TextStyle(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                : _buildSurveyorsList(project),
          ],
        ),
      ),
    );
  }

  Widget _buildSurveyorsList(ProjectModel project) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: project.assignedSurveyors.length,
      itemBuilder: (context, index) {
        return FutureBuilder<DocumentSnapshot>(
          future: _firestore
              .collection('users')
              .doc(project.assignedSurveyors[index])
              .get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: LinearProgressIndicator(),
              );
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const SizedBox.shrink();
            }

            final surveyor = UserModel.fromMap(
              snapshot.data!.data() as Map<String, dynamic>, 
              snapshot.data!.id,
            );

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: surveyor.isActive 
                    ? Colors.green.withOpacity(0.1) 
                    : Colors.red.withOpacity(0.1),
                  child: Text(
                    surveyor.name[0].toUpperCase(),
                    style: TextStyle(
                      color: surveyor.isActive ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  surveyor.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(surveyor.email),
                trailing: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: surveyor.isActive 
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    surveyor.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      color: surveyor.isActive ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSurveyQuestionsSection(ProjectModel project) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('survey_templates')
          .where('projectId', isEqualTo: widget.projectId)
          .limit(1)
          .snapshots(),
      builder: (context, templateSnapshot) {
        if (templateSnapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        if (!templateSnapshot.hasData || templateSnapshot.data!.docs.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Column(
                  children: [
                    const Icon(
                      Icons.quiz_outlined,
                      size: 48,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'No survey template found',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final templateData = templateSnapshot.data!.docs.first.data() as Map<String, dynamic>;

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Survey Questions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Template editing coming soon'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSections(templateData['sections'] as List<dynamic>),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSections(List<dynamic> sections) {
    return ExpansionPanelList(
      elevation: 2,
      expandedHeaderPadding: EdgeInsets.zero,
      expansionCallback: (int index, bool isExpanded) {
        setState(() {
          _selectedPanelIndex = isExpanded ? index : null;
        });
      },
      children: sections.asMap().entries.map((entry) {
        final index = entry.key;
        final section = entry.value as Map<String, dynamic>;
        return ExpansionPanel(
          isExpanded: _selectedPanelIndex == index,
          headerBuilder: (context, isExpanded) {
            return ListTile(
              title: Text(
                section['title'] as String,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                section['description'] as String? ?? '',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            );
          },
          body: Column(
            children: [
              const Divider(height: 1),
              ...(section['questions'] as List<dynamic>)
                  .map((question) => _buildQuestionTile(question as Map<String, dynamic>))
                  .toList(),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildQuestionTile(Map<String, dynamic> question) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          _getQuestionTypeIcon(question['type'] as String),
          color: Theme.of(context).primaryColor,
          size: 24,
        ),
      ),
      title: Text(
        question['question'] as String,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            'Type: ${question['type']}',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
          if (question['category'] != null)
            Text(
              'Category: ${question['category']}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          if (question['subCategory'] != null)
            Text(
              'Sub-category: ${question['subCategory']}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              if (question['requiresPhoto'] as bool)
                Chip(
                  label: const Text('Photo'),
                  avatar: const Icon(Icons.camera_alt, size: 16),
                  backgroundColor: Colors.blue.withOpacity(0.1),
                  labelStyle: const TextStyle(color: Colors.blue),
                ),
              if (question['requiresRemark'] as bool)
                Chip(
                  label: const Text('Remark'),
                  avatar: const Icon(Icons.comment, size: 16),
                  backgroundColor: Colors.green.withOpacity(0.1),
                  labelStyle: const TextStyle(color: Colors.green),
                ),
            ],
          ),
        ],
      ),
      isThreeLine: true,
    );
  }

  IconData _getQuestionTypeIcon(String type) {
    switch (type) {
      case 'YES_NO':
        return Icons.check_circle_outline;
      case 'TEXT':
        return Icons.text_fields;
      case 'NUMERIC':
        return Icons.numbers;
      default:
        return Icons.question_answer;
    }
  }

  Future<void> _showAssignSurveyorsDialog(ProjectModel project) async {
    try {
      final surveyorsSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'surveyor')
          .where('isActive', isEqualTo: true)
          .get();

      List<String> selectedSurveyors = List.from(project.assignedSurveyors);

      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('Assign Surveyors'),
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
                          title: Text(surveyorName),
                          subtitle: Text(surveyorEmail),
                          value: selectedSurveyors.contains(surveyorId),
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                selectedSurveyors.add(surveyorId);
                              } else {
                                selectedSurveyors.remove(surveyorId);
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
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        await _firestore
                            .collection('projects')
                            .doc(widget.projectId)
                            .update({
                          'assignedSurveyors': selectedSurveyors,
                        });

                        if (!mounted) return;
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Surveyors updated (${selectedSurveyors.length} assigned)',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Error updating surveyors: ${e.toString()}',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    child: const Text('Save'),
                  ),
                ],
              );
            },
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading surveyors: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}