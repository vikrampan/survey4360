// lib/screens/admin/manage_surveyors_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:survey_app/models/user_model.dart';
import 'package:survey_app/screens/admin/add_surveyor_screen.dart';

class ManageSurveyorsScreen extends StatefulWidget {
  const ManageSurveyorsScreen({Key? key}) : super(key: key);

  @override
  _ManageSurveyorsScreenState createState() => _ManageSurveyorsScreenState();
}

class _ManageSurveyorsScreenState extends State<ManageSurveyorsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _toggleSurveyorStatus(UserModel surveyor) async {
    try {
      await _firestore.collection('users').doc(surveyor.uid).update({
        'isActive': !surveyor.isActive,
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            surveyor.isActive 
              ? 'Surveyor deactivated successfully' 
              : 'Surveyor activated successfully'
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating surveyor status: ${e.toString()}')),
      );
    }
  }

  Future<void> _deleteSurveyor(UserModel surveyor) async {
    bool? confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete ${surveyor.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmDelete == true) {
      try {
        // In a real app, you might want to soft delete or archive the user
        await _firestore.collection('users').doc(surveyor.uid).delete();
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${surveyor.name} deleted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting surveyor: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Surveyors'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddSurveyorScreen(),
                ),
              ).then((value) {
                // Refresh list if a new surveyor was added
                setState(() {});
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search surveyors...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('users')
                  .where('role', isEqualTo: 'surveyor')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No surveyors found'),
                  );
                }

                // Filter surveyors based on search query
                final filteredSurveyors = snapshot.data!.docs.where((doc) {
                  final surveyor = UserModel.fromMap(
                    doc.data() as Map<String, dynamic>, 
                    doc.id,
                  );
                  return surveyor.name.toLowerCase().contains(_searchQuery) ||
                         surveyor.email.toLowerCase().contains(_searchQuery);
                }).toList();

                return ListView.builder(
                  itemCount: filteredSurveyors.length,
                  itemBuilder: (context, index) {
                    final doc = filteredSurveyors[index];
                    final surveyor = UserModel.fromMap(
                      doc.data() as Map<String, dynamic>, 
                      doc.id,
                    );

                    return Dismissible(
                      key: Key(surveyor.uid),
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Icon(
                          Icons.delete,
                          color: Colors.white,
                        ),
                      ),
                      confirmDismiss: (direction) async {
                        return await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Confirm Delete'),
                            content: Text('Are you sure you want to delete ${surveyor.name}?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                style: TextButton.styleFrom(foregroundColor: Colors.red),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                      },
                      onDismissed: (direction) {
                        _deleteSurveyor(surveyor);
                      },
                      child: Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8, 
                          vertical: 4
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: surveyor.isActive 
                              ? Colors.green.shade100 
                              : Colors.red.shade100,
                            child: Text(
                              surveyor.name[0].toUpperCase(),
                              style: TextStyle(
                                color: surveyor.isActive 
                                  ? Colors.green 
                                  : Colors.red,
                              ),
                            ),
                          ),
                          title: Text(
                            surveyor.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: surveyor.isActive ? Colors.black : Colors.grey,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                surveyor.email, 
                                style: TextStyle(
                                  color: surveyor.isActive ? Colors.black87 : Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                surveyor.isActive ? 'Active' : 'Inactive',
                                style: TextStyle(
                                  color: surveyor.isActive ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (String value) {
                              switch (value) {
                                case 'toggle':
                                  _toggleSurveyorStatus(surveyor);
                                  break;
                                case 'delete':
                                  _deleteSurveyor(surveyor);
                                  break;
                                case 'details':
                                  _showSurveyorDetailsDialog(surveyor);
                                  break;
                              }
                            },
                            itemBuilder: (BuildContext context) => [
                              PopupMenuItem<String>(
                                value: 'details',
                                child: Row(
                                  children: const [
                                    Icon(Icons.info_outline, color: Colors.blue),
                                    SizedBox(width: 8),
                                    Text('View Details'),
                                  ],
                                ),
                              ),
                              PopupMenuItem<String>(
                                value: 'toggle',
                                child: Row(
                                  children: [
                                    Icon(
                                      surveyor.isActive 
                                        ? Icons.block 
                                        : Icons.check_circle,
                                      color: surveyor.isActive 
                                        ? Colors.orange 
                                        : Colors.green,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      surveyor.isActive 
                                        ? 'Deactivate' 
                                        : 'Activate',
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem<String>(
                                value: 'delete',
                                child: Row(
                                  children: const [
                                    Icon(Icons.delete, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Delete'),
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
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddSurveyorScreen(),
            ),
          ).then((value) {
            // Refresh list if a new surveyor was added
            setState(() {});
          });
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Surveyor'),
      ),
    );
  }

  void _showSurveyorDetailsDialog(UserModel surveyor) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Surveyor Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Name', surveyor.name),
              _buildDetailRow('Email', surveyor.email),
              _buildDetailRow('Status', surveyor.isActive ? 'Active' : 'Inactive'),
              _buildDetailRow('Joined', surveyor.createdAt.toString().split(' ')[0]),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value),
        ],
      ),
    );
  }
}