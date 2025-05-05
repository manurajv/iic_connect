import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iic_connect/models/user.dart';
import 'package:iic_connect/utils/constants.dart';
import 'package:iic_connect/models/user.dart' as User;

class AuthService {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Login with email/password
  Future<User.User?> login(String email, String password) async {
    try {
      final UserCredential credential = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return await getUserFromFirestore(credential.user?.uid);
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseError(e);
    }
  }

  // Register new user
  Future<User.User?> register(Map<String, dynamic> userData) async {
    try {
      print('Creating auth user with email: ${userData['email']}');

      // Create auth user
      final UserCredential credential = await auth.createUserWithEmailAndPassword(
        email: userData['email'],
        password: userData['password'],
      );

      print('Auth user created with UID: ${credential.user?.uid}');

      // Create user document in Firestore
      final user = User.User(
        id: credential.user?.uid ?? '',
        name: userData['name'],
        email: userData['email'],
        role: userData['role'] ?? AppConstants.studentRole,
        enrollmentNumber: userData['enrollmentNumber'] ?? '',
        department: userData['department'] ?? 'IIC',
        phone: userData['phone'] ?? '',
        batch: userData['batch'] ?? '',
        course: userData['course'] ?? '',
        classId: userData['class'] ?? '',
        createdAt: Timestamp.now(),
      );

      print('Creating Firestore user document: ${user.toFirestore()}');

      await _firestore.collection('users').doc(user.id).set(user.toFirestore());

      print('User document created successfully');
      return user; // Return the user but don't change auth state
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.code} - ${e.message}');
      throw _handleFirebaseError(e);
    } on FirebaseException catch (e) {
      print('Firestore Error: ${e.code} - ${e.message}');
      throw 'Failed to create user: ${e.message}';
    } catch (e) {
      print('Unexpected Error: $e');
      throw 'Failed to create user: $e';
    }
  }

  // Get current authenticated user
  Future<User.User?> getCurrentUser() async {
    final firebaseUser = auth.currentUser;
    if (firebaseUser == null) return null;
    return await getUserFromFirestore(firebaseUser.uid);
  }

  // Logout user
  Future<void> logout() async {
    await auth.signOut();
  }

  // Get user data from Firestore
  Future<User.User?> getUserFromFirestore(String? uid) async {
    if (uid == null) return null;

    try {
      final DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) {
        print('User document does not exist for UID: $uid');
        return null;
      }

      final userData = doc.data() as Map<String, dynamic>;
      print('Retrieved user data: $userData');

      return User.User.fromFirestore(userData, doc.id);
    } catch (e) {
      print('Error getting user from Firestore: $e');
      rethrow;
    }
  }

  // Get auth token for authenticated requests
  Future<String?> getToken() async {
    return await auth.currentUser?.getIdToken();
  }

  // Firebase error handling
  String _handleFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email': return 'Invalid email format';
      case 'user-disabled': return 'Account disabled';
      case 'user-not-found': return 'No user found';
      case 'wrong-password': return 'Incorrect password';
      case 'email-already-in-use': return 'Email already registered';
      case 'weak-password': return 'Password must be 6+ characters';
      case 'operation-not-allowed': return 'Email/password accounts are not enabled';
      default: return 'Authentication failed: ${e.message}';
    }
  }

  // Optional: Update user profile
  Future<void> updateProfile(User.User user) async {
    await _firestore.collection('users').doc(user.id).update(user.toFirestore());
  }

  Future<UserCredential> createAuthUser(String email, String password) async {
    return await auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> deleteAuthUser(String userId) async {
    // Admin should have permissions to delete users
    final user = await auth.currentUser;
    if (user?.uid == userId) {
      await user?.delete();
    } else {
      // For admin deleting other users, you might need Admin SDK
      throw Exception('Admin SDK required for deleting other users');
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await auth.sendPasswordResetEmail(email: email);
  }

}