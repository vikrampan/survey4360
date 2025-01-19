import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:survey_app/services/auth_service.dart';
import 'package:survey_app/models/user_model.dart';
import 'package:survey_app/models/project_model.dart';
import 'package:survey_app/models/survey_model.dart';
import 'package:survey_app/screens/auth/login_screen.dart';
import 'package:survey_app/screens/surveyor/survey_history_screen.dart';
import 'package:survey_app/screens/surveyor/pending_sync_screen.dart';
import 'package:survey_app/screens/surveyor/survey_response_screen.dart';

enum SurveyStatus {
  pending,
  inProgress,
  completed,
  needsRevision,
  approved
}

extension SurveyStatusExtension on SurveyStatus {
  String toStatusString() {
    switch (this) {
      case SurveyStatus.pending:
        return 'pending';
      case SurveyStatus.inProgress:
        return 'inProgress';
      case SurveyStatus.completed:
        return 'completed';
      case SurveyStatus.needsRevision:
        return 'needsRevision';
      case SurveyStatus.approved:
        return 'approved';
    }
  }

  static SurveyStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return SurveyStatus.pending;
      case 'inprogress':
        return SurveyStatus.inProgress;
      case 'completed':
        return SurveyStatus.completed;
      case 'needsrevision':
        return SurveyStatus.needsRevision;
      case 'approved':
        return SurveyStatus.approved;
      default:
        return SurveyStatus.pending;
    }
  }
}

class SurveyorDashboard extends StatefulWidget {
  const SurveyorDashboard({Key? key}) : super(key: key);

  @override
  State<SurveyorDashboard> createState() => _SurveyorDashboardState();
}

class _SurveyorDashboardState extends State<SurveyorDashboard> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late AnimationController _notificationController;
  late Animation<double> _notificationAnimation;
  int _selectedIndex = 0;
  bool _isSyncing = false;
  UserModel? _currentUser;
  bool _hasUnreadNotifications = false;

  @override
  void initState() {
    super.initState();
    _fetchCurrentUser();
    _setupNotificationAnimation();
    _checkUnreadNotifications();
  }

  void _setupNotificationAnimation() {
    _notificationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _notificationAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _notificationController,
        curve: Curves.easeInOut,
      ),
    );

    _notificationController.repeat(reverse: true);
  }

  Future<void> _checkUnreadNotifications() async {
    if (_currentUser == null) return;
    
    // Subscribe to notifications stream
    _firestore
        .collection('surveys')
        .where('surveyorId', isEqualTo: _currentUser?.uid)
        .where('isSubmitted', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          _hasUnreadNotifications = snapshot.docs.isNotEmpty;
        });
        if (_hasUnreadNotifications) {
          _notificationController.forward();
        } else {
          _notificationController.stop();
          _notificationController.reset();
        }
      }
    });
  }

  Future<void> _fetchCurrentUser() async {
    final user = await _authService.getCurrentUser();
    if (mounted) {
      setState(() {
        _currentUser = user;
      });
      _checkUnreadNotifications();
    }
  }

  @override
  void dispose() {
    _notificationController.dispose();
    super.dispose();
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
        SnackBar(
          content: Text('Error logging out: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showLogoutDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _handleLogout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  void _showProfileDialog() {
    if (_currentUser == null) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Surveyor Profile',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Hero(
                tag: 'profile-avatar',
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.blue.shade100,
                  child: Text(
                    _currentUser!.name[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _currentUser!.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _currentUser!.email,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              _buildProfileDetail('Role', 'Surveyor'),
              const Divider(height: 20),
              _buildProfileDetail(
                'Member Since',
                '${_currentUser!.createdAt.day}/${_currentUser!.createdAt.month}/${_currentUser!.createdAt.year}',
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
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _performSync() async {
    if (_isSyncing) return false;

    setState(() {
      _isSyncing = true;
    });

    try {
      // Simulated sync delay
      await Future.delayed(const Duration(seconds: 2));
      
      // Show success message
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Sync completed successfully!'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      return true;
    } catch (e) {
      // Show error message
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Text('Sync failed: ${e.toString()}'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      body: RefreshIndicator(
        onRefresh: () async {
          await _fetchCurrentUser();
          await _performSync();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeHeader(),
              const SizedBox(height: 20),
              _buildStatusGrid(),
              const SizedBox(height: 24),
              _buildRecentSurveys(),
              const SizedBox(height: 24),
              _buildPendingSyncs(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Theme.of(context).primaryColor,
      title: const Text(
        'Surveyor Dashboard',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      actions: [
        _buildNotificationButton(),
        if (_isSyncing)
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
          icon: const Icon(Icons.sync, color: Colors.white),
          onPressed: _performSync,
          tooltip: 'Sync Data',
        ),
        IconButton(
          icon: const Icon(Icons.person, color: Colors.white),
          onPressed: _showProfileDialog,
          tooltip: 'Profile',
        ),
      ],
    );
  }

  Widget _buildNotificationButton() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('surveys')
          .where('surveyorId', isEqualTo: _currentUser?.uid)
          .where('isSubmitted', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        int pendingCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
        
        return Stack(
          alignment: Alignment.center,
          children: [
            ScaleTransition(
              scale: _notificationAnimation,
              child: IconButton(
                icon: Icon(
                  Icons.notifications,
                  color: _hasUnreadNotifications ? Colors.yellow : Colors.white,
                ),
                onPressed: () => _showAssignedSurveys(context),
                tooltip: 'Notifications',
              ),
            ),
            if (pendingCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 20,
                    minHeight: 20,
                  ),
                  child: Text(
                    pendingCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(
                _currentUser?.name ?? 'Surveyor',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              accountEmail: Text(
                _currentUser?.email ?? '',
                style: const TextStyle(fontSize: 14),
              ),
              currentAccountPicture: Hero(
                tag: 'profile-avatar',
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Text(
                    (_currentUser?.name ?? 'S')[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: 40.0,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                image: const DecorationImage(
                  image: AssetImage('assets/images/drawer_header_bg.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            _buildDrawerItem(
              icon: Icons.home,
              title: 'Home',
              onTap: () => _onItemTapped(0),
              selected: _selectedIndex == 0,
            ),
            _buildDrawerItem(
              icon: Icons.history,
              title: 'Survey History',
              onTap: () => _onItemTapped(1),
              selected: _selectedIndex == 1,
            ),
            _buildDrawerItem(
              icon: Icons.sync,
              title: 'Pending Sync',
              onTap: () => _onItemTapped(2),
              selected: _selectedIndex == 2,
            ),
            const Divider(),
            _buildDrawerItem(
              icon: Icons.logout,
              title: 'Logout',
              onTap: _showLogoutDialog,
              textColor: Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool selected = false,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: selected ? Theme.of(context).primaryColor : textColor,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? (selected ? Theme.of(context).primaryColor : null),
          fontWeight: selected ? FontWeight.bold : null,
        ),
      ),
      selected: selected,
      selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.1),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Hero(
                tag: 'welcome-avatar',
                child: CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.white,
                  child: Text(
                    (_currentUser?.name ?? 'S')[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currentUser?.name ?? 'Surveyor',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Have a great day!',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
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

  Widget _buildStatusGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('surveys')
          .where('surveyorId', isEqualTo: _currentUser?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        int totalSurveys = 0;
        int completedSurveys = 0;
        int pendingSync = 0;

        if (snapshot.hasData) {
          final surveys = snapshot.data!.docs;
          totalSurveys = surveys.length;
          completedSurveys = surveys
              .where((doc) => (doc.data() as Map<String, dynamic>)['isSubmitted'] == true)
              .length;
          pendingSync = surveys
              .where((doc) => (doc.data() as Map<String, dynamic>)['needsSync'] == true)
              .length;
        }

        return GridView.count(
          shrinkWrap: true,
          crossAxisCount: 3,
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildStatCard(
              'Total Surveys',
              totalSurveys.toString(),
              Icons.assignment,
              Colors.blue,
              'All assigned surveys',
            ),
            _buildStatCard(
              'Completed',
              completedSurveys.toString(),
              Icons.check_circle,
              Colors.green,
              'Successfully completed surveys',
            ),
            _buildStatCard(
              'To Sync',
              pendingSync.toString(),
              Icons.sync_problem,
              Colors.orange,
              'Surveys pending synchronization',
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String tooltip,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Tooltip(
        message: tooltip,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.1),
                Colors.white,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
                const SizedBox(height: 12),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: () => _showAssignedSurveys(context),
      icon: const Icon(Icons.add),
      label: const Text('New Survey'),
      elevation: 4,
      backgroundColor: Theme.of(context).primaryColor,
    );
  }

  Future<void> _showAssignedSurveys(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return AssignedSurveysSheet(
            userId: _currentUser!.uid,
            scrollController: scrollController,
          );
        },
      ),
    );
  }

  Widget _buildRecentSurveys() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('surveys')
          .where('surveyorId', isEqualTo: _currentUser?.uid)
          .orderBy('createdAt', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent Surveys',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SurveyHistoryScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.history),
                      label: const Text('View All'),
                    ),
                  ],
                ),
              ),
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                _buildEmptyRecentSurveys()
              else
                _buildRecentSurveysList(snapshot.data!.docs),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyRecentSurveys() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No recent surveys',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start a new survey using the button below',
              style: TextStyle(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSurveysList(List<QueryDocumentSnapshot> surveys) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: surveys.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final surveyDoc = surveys[index];
        final surveyData = surveyDoc.data() as Map<String, dynamic>;

        return FutureBuilder<DocumentSnapshot>(
          future: _firestore
              .collection('projects')
              .doc(surveyData['projectId'])
              .get(),
          builder: (context, projectSnapshot) {
            if (!projectSnapshot.hasData) {
              return const SizedBox(
                height: 80,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final projectData = projectSnapshot.data!.data() as Map<String, dynamic>;

            return ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              leading: CircleAvatar(
                backgroundColor: _getSurveyStatusColor(surveyData['status'])
                    .withOpacity(0.2),
                child: Icon(
                  Icons.assignment,
                  color: _getSurveyStatusColor(surveyData['status']),
                ),
              ),
              title: Text(
                projectData['name'] ?? 'Untitled Project',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(projectData['location'] ?? 'No location'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _getSurveyStatusColor(surveyData['status'])
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      surveyData['status'] ?? 'pending',
                      style: TextStyle(
                        color: _getSurveyStatusColor(surveyData['status']),
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.arrow_forward_ios, size: 16),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SurveyResponseScreen(
                        surveyId: surveyDoc.id,
                        projectId: surveyData['projectId'],
                      ),
                    ),
                  );
                },
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SurveyResponseScreen(
                      surveyId: surveyDoc.id,
                      projectId: surveyData['projectId'],
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

  Color _getSurveyStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'inprogress':
        return Colors.blue;
      case 'needsrevision':
        return Colors.orange;
      case 'approved':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Widget _buildPendingSyncs() {return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('surveys')
          .where('surveyorId', isEqualTo: _currentUser?.uid)
          .where('needsSync', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox();
        }

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.sync_problem,
                          color: Colors.orange[700],
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Pending Syncs',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: _performSync,
                      icon: const Icon(Icons.sync),
                      label: const Text('Sync All'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final surveyDoc = snapshot.data!.docs[index];
                  final surveyData = surveyDoc.data() as Map<String, dynamic>;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: Colors.orange.shade200,
                          width: 1,
                        ),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.orange.shade100,
                          child: Icon(
                            Icons.sync_problem,
                            color: Colors.orange[700],
                          ),
                        ),
                        title: Text(
                          'Survey #${surveyDoc.id.substring(0, 6)}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              'Last modified: ${_formatDate(surveyData['lastModified'] as Timestamp)}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Waiting to sync...',
                              style: TextStyle(
                                color: Colors.orange[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.sync),
                          color: Colors.orange[700],
                          onPressed: () => _performSyncForSurvey(surveyDoc.id),
                          tooltip: 'Sync this survey',
                        ),
                        onTap: () => _showSyncDetails(surveyDoc),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _performSyncForSurvey(String surveyId) async {
    if (_isSyncing) return;

    setState(() {
      _isSyncing = true;
    });

    try {
      // Simulated individual survey sync
      await Future.delayed(const Duration(seconds: 1));
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text('Survey #${surveyId.substring(0, 6)} synced successfully!'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Text('Failed to sync survey #${surveyId.substring(0, 6)}'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  void _showSyncDetails(QueryDocumentSnapshot surveyDoc) {
    final surveyData = surveyDoc.data() as Map<String, dynamic>;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sync Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSyncDetailItem('Survey ID', '#${surveyDoc.id.substring(0, 6)}'),
            _buildSyncDetailItem(
              'Last Modified',
              _formatDate(surveyData['lastModified'] as Timestamp),
            ),
            _buildSyncDetailItem(
              'Status',
              surveyData['status'] ?? 'Unknown',
            ),
            _buildSyncDetailItem(
              'Changes',
              'Pending local changes need to be synchronized',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _performSyncForSurvey(surveyDoc.id);
            },
            icon: const Icon(Icons.sync),
            label: const Text('Sync Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
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
        // Survey History
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SurveyHistoryScreen(),
          ),
        );
        break;
      case 2:
        // Pending Sync
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const PendingSyncScreen(),
          ),
        );
        break;
    }
  }
}

// AssignedSurveysSheet Widget
class AssignedSurveysSheet extends StatelessWidget {
  final String userId;
  final ScrollController scrollController;

  const AssignedSurveysSheet({
    Key? key,
    required this.userId,
    required this.scrollController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.assignment_outlined, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Assigned Surveys',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('surveys')
                  .where('surveyorId', isEqualTo: userId)
                  .where('isSubmitted', isEqualTo: false)
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
                          Icons.assignment_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No pending surveys',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final surveyDoc = snapshot.data!.docs[index];
                    final surveyData = surveyDoc.data() as Map<String, dynamic>;

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('projects')
                          .doc(surveyData['projectId'])
                          .get(),
                      builder: (context, projectSnapshot) {
                        if (!projectSnapshot.hasData) {
                          return const SizedBox(
                            height: 100,
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        final projectData = projectSnapshot.data!.data() 
                            as Map<String, dynamic>;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue.shade100,
                              child: const Icon(
                                Icons.assignment,
                                color: Colors.blue,
                              ),
                            ),
                            title: Text(
                              projectData['name'] ?? 'Untitled Project',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      size: 16,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      projectData['location'] ?? 'No location',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    surveyData['status'] ?? 'pending',
                                    style: TextStyle(
                                      color: Colors.blue[700],
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                           trailing: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context); // Close sheet
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SurveyResponseScreen(
                                      surveyId: surveyDoc.id,
                                      projectId: surveyData['projectId'],
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Start'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}