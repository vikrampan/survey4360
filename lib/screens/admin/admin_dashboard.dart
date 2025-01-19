// lib/screens/admin/admin_dashboard.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:survey_app/services/auth_service.dart';
import 'package:survey_app/models/project_model.dart';
import 'package:survey_app/models/user_model.dart';
import 'package:survey_app/screens/auth/login_screen.dart';
import 'package:survey_app/screens/admin/add_surveyor_screen.dart';
import 'package:survey_app/screens/admin/create_project_screen.dart';
import 'package:survey_app/screens/admin/manage_surveyors_screen.dart';
import 'package:survey_app/screens/admin/project_details_screen.dart';
import 'package:survey_app/screens/admin/project_list_screen.dart';
import 'package:survey_app/screens/admin/surveyor_projects_screen.dart';
import 'package:survey_app/screens/admin/filtered_list_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int _selectedIndex = 0;
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _fetchCurrentUser();
  }

  Future<void> _fetchCurrentUser() async {
    final user = await _authService.getCurrentUser();
    if (mounted) {
      setState(() {
        _currentUser = user;
      });
    }
  }

  Future<void> _handleLogout() async {
    try {
      await _authService.signOut();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging out: ${e.toString()}')),
      );
    }
  }

  Future<void> _showLogoutDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _handleLogout();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  void _showProfileDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Admin Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.blue.shade100,
                child: Text(
                  _currentUser?.name[0].toUpperCase() ?? 'A',
                  style: TextStyle(
                    fontSize: 40,
                    color: Colors.blue.shade800,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _currentUser?.name ?? 'Admin User',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _currentUser?.email ?? 'admin@example.com',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              _buildProfileDetail('Role', 'Administrator'),
              _buildProfileDetail(
                'Member Since', 
                _currentUser?.createdAt != null 
                  ? '${_currentUser!.createdAt.day}/${_currentUser!.createdAt.month}/${_currentUser!.createdAt.year}' 
                  : 'N/A'
              ),
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

  Widget _buildProfileDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: _showProfileDialog,
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeHeader(),
            const SizedBox(height: 20),
            _buildStatsGrid(),
            const SizedBox(height: 30),
            _buildSurveyorsSection(),
            const SizedBox(height: 30),
            _buildRecentProjectsSection(),
          ],
        ),
      ),
      floatingActionButton: _buildSpeedDial(),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(_currentUser?.name ?? 'Admin User'),
            accountEmail: Text(_currentUser?.email ?? 'admin@example.com'),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                (_currentUser?.name ?? 'A')[0].toUpperCase(),
                style: TextStyle(
                  fontSize: 40.0,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
          ),
          _buildDrawerItem(
            icon: Icons.dashboard,
            title: 'Dashboard',
            onTap: () => _onItemTapped(0),
            selected: _selectedIndex == 0,
          ),
          _buildDrawerItem(
            icon: Icons.assignment,
            title: 'Projects',
            onTap: () => _onItemTapped(1),
            selected: _selectedIndex == 1,
          ),
          _buildDrawerItem(
            icon: Icons.people,
            title: 'Surveyors',
            onTap: () => _onItemTapped(2),
            selected: _selectedIndex == 2,
          ),
          _buildDrawerItem(
            icon: Icons.analytics,
            title: 'Reports',
            onTap: () => _onItemTapped(3),
            selected: _selectedIndex == 3,
          ),
          const Divider(),
          _buildDrawerItem(
            icon: Icons.logout,
            title: 'Logout',
            onTap: _showLogoutDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool selected = false,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      selected: selected,
      onTap: onTap,
    );
  }

  Widget _buildWelcomeHeader() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.blue.shade100,
              child: Text(
                (_currentUser?.name ?? 'A')[0].toUpperCase(),
                style: TextStyle(
                  fontSize: 30,
                  color: Colors.blue.shade800,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, ${_currentUser?.name ?? 'Admin'}!',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Admin Dashboard',
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('projects').snapshots(),
      builder: (context, projectSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('users')
              .where('role', isEqualTo: 'surveyor')
              .snapshots(),
          builder: (context, surveyorSnapshot) {
            int totalProjects = projectSnapshot.data?.docs.length ?? 0;
            int activeSurveyors = surveyorSnapshot.data?.docs.length ?? 0;
            int pendingProjects = projectSnapshot.data?.docs.where((doc) {
                  final project = ProjectModel.fromMap(
                    doc.data() as Map<String, dynamic>, 
                    doc.id,
                  );
                  return project.status == ProjectStatus.pending;
                }).length ?? 0;
            int completedProjects = projectSnapshot.data?.docs.where((doc) {
                  final project = ProjectModel.fromMap(
                    doc.data() as Map<String, dynamic>, 
                    doc.id,
                  );
                  return project.status == ProjectStatus.completed;
                }).length ?? 0;

            return GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStatCard(
                  'Total Projects',
                  totalProjects.toString(),
                  Icons.assignment,
                  Colors.blue,
                ),
                _buildStatCard(
                  'Active Surveyors',
                  activeSurveyors.toString(),
                  Icons.people,
                  Colors.green,
                ),
                _buildStatCard(
                  'Pending Projects',
                  pendingProjects.toString(),
                  Icons.pending_actions,
                  Colors.orange,
                ),
                _buildStatCard(
                  'Completed Projects',
                  completedProjects.toString(),
                  Icons.done_all,
                  Colors.purple,
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: () {
          switch (title) {
            case 'Total Projects':
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FilteredListScreen(
                    title: 'All Projects',
                    type: 'projects',
                  ),
                ),
              );
              break;
            case 'Active Surveyors':
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FilteredListScreen(
                    title: 'Active Surveyors',
                    type: 'surveyors',
                  ),
                ),
              );
              break;
            case 'Pending Projects':
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FilteredListScreen(
                    title: 'Pending Projects',
                    type: 'projects',
                    statusFilter: ProjectStatus.pending,
                  ),
                ),
              );
              break;
            case 'Completed Projects':
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FilteredListScreen(
                    title: 'Completed Projects',
                    type: 'projects',
                    statusFilter: ProjectStatus.completed,
                  ),
                ),
              );
              break;
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 40,
                color: color,
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSurveyorsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Active Surveyors',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ManageSurveyorsScreen(),
                  ),
                );
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('users')
              .where('role', isEqualTo: 'surveyor')
              .where('isActive', isEqualTo: true)
              .limit(3)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Card(
                child: ListTile(
                  title: Text('No active surveyors'),
                ),
              );
            }

            return Card(
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  var surveyor = UserModel.fromMap(
                    snapshot.data!.docs[index].data() as Map<String, dynamic>, 
                    snapshot.data!.docs[index].id,
                  );
                  return ListTile(
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
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.withOpacity(0.1),
                      child: Text(
                        surveyor.name[0].toUpperCase(),
                        style: const TextStyle(color: Colors.blue),
                      ),
                    ),
                    title: Text(surveyor.name),
                    subtitle: Text(surveyor.email),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentProjectsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Projects',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProjectListScreen(),
                  ),
                );
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('projects')
              .orderBy('createdAt', descending: true)
              .limit(5)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Card(
                child: ListTile(
                  title: Text('No projects found'),
                ),
              );
            }

            return Card(
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  var project = ProjectModel.fromMap(
                    snapshot.data!.docs[index].data() as Map<String, dynamic>, 
                    snapshot.data!.docs[index].id,
                  );
                  return ListTile(
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
                    leading: CircleAvatar(
                      backgroundColor: _getStatusColor(project.status).withOpacity(0.1),
                      child: Icon(
                        Icons.assignment,
                        color: _getStatusColor(project.status),
                      ),
                    ),
                    title: Text(
                      project.name,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Location: ${project.location}'),
                        Row(
                          children: [
                            Icon(
                              Icons.person,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${project.assignedSurveyors.length} Surveyors',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(project.status).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                project.status.toString().split('.').last,
                                style: TextStyle(
                                  color: _getStatusColor(project.status),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    isThreeLine: true,
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Color _getStatusColor(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.pending: return Colors.orange;
      case ProjectStatus.inProgress:
        return Colors.blue;
      case ProjectStatus.completed:
        return Colors.green;
    }
  }

  Widget _buildSpeedDial() {
    return SpeedDial(
      icon: Icons.add,
      activeIcon: Icons.close,
      spacing: 3,
      backgroundColor: Theme.of(context).primaryColor,
      foregroundColor: Colors.white,
      children: [
        SpeedDialChild(
          child: const Icon(Icons.assignment_add),
          label: 'Create Project',
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CreateProjectScreen(),
              ),
            );
          },
        ),
        SpeedDialChild(
          child: const Icon(Icons.person_add),
          label: 'Add Surveyor',
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddSurveyorScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.pop(context); // Close drawer
    
    switch (index) {
      case 0:
        // Already on Dashboard
        break;
      case 1:
        // Projects
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ProjectListScreen(),
          ),
        );
        break;
      case 2:
        // Surveyors
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ManageSurveyorsScreen(),
          ),
        );
        break;
      case 3:
        // Reports - Show coming soon message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reports feature coming soon'),
            duration: Duration(seconds: 2),
          ),
        );
        break;
    }
  }
}