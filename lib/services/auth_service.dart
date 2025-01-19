// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:survey_app/models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get user stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user data
  Future<UserModel?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!, doc.id);
      }
    }
    return null;
  }

  // Sign in
  Future<UserModel?> signIn(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        final doc = await _firestore.collection('users').doc(result.user!.uid).get();
        
        // Check if user document exists
        if (!doc.exists) {
          throw Exception('User profile not found');
        }

        // Verify user role and active status
        final userData = doc.data()!;
        if (userData['isActive'] == false) {
          throw Exception('User account is deactivated');
        }

        return UserModel.fromMap(userData, doc.id);
      }
      return null;
    } on FirebaseAuthException catch (e) {
      // More specific error handling for authentication
      switch (e.code) {
        case 'user-not-found':
          throw Exception('No user found with this email');
        case 'wrong-password':
          throw Exception('Incorrect password');
        case 'user-disabled':
          throw Exception('User account has been disabled');
        case 'invalid-email':
          throw Exception('Invalid email address');
        default:
          throw Exception('Authentication failed: ${e.message}');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Error during logout: ${e.toString()}');
    }
  }

  // Create new surveyor (Admin only)
  Future<UserModel> createSurveyor({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    try {
      // Validate input
      if (email.isEmpty || password.isEmpty || name.isEmpty) {
        throw Exception('All fields are required');
      }

      // Check if email already exists
      try {
        final existingUser = await _firestore
            .collection('users')
            .where('email', isEqualTo: email)
            .get();
        
        if (existingUser.docs.isNotEmpty) {
          throw Exception('A user with this email already exists');
        }
      } catch (e) {
        // Rethrow if it's not just a "no documents" error
        if (e.toString() != 'Exception: null') rethrow;
      }

      // Create auth user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user document
      final userData = UserModel(
        uid: userCredential.user!.uid,
        email: email,
        role: 'surveyor',
        name: name,
        createdAt: DateTime.now(),
        isActive: true,
        phone: phone,
      );

      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(userData.toMap());

      return userData;
    } on FirebaseAuthException catch (e) {
      // More specific Firebase Authentication errors
      switch (e.code) {
        case 'weak-password':
          throw Exception('The password is too weak');
        case 'email-already-in-use':
          throw Exception('An account already exists with this email');
        case 'invalid-email':
          throw Exception('Invalid email address');
        default:
          throw Exception('User creation failed: ${e.message}');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Method to update user profile
  Future<void> updateUserProfile({
    String? name,
    String? phone,
    String? email,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user');
      }

      // Prepare update data
      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (phone != null) updateData['phone'] = phone;
      if (email != null) {
        // Update email in Authentication
        await currentUser.updateEmail(email);
        updateData['email'] = email;
      }

      // Update Firestore document
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .update(updateData);
    } catch (e) {
      throw Exception('Profile update failed: ${e.toString()}');
    }
  }

  // Method to change password
  Future<void> changePassword(String newPassword) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user');
      }

      await currentUser.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw Exception('Password change failed: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error during password change');
    }
  }
}