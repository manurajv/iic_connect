import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iic_connect/models/user.dart' as app_user;
import 'package:iic_connect/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/constants.dart';

class AuthProvider with ChangeNotifier {
  app_user.User? _user;
  List<app_user.User> _allUsers = [];
  bool _isLoading = false;
  String? _error;
  bool _isAdmin = false;

  app_user.User? get user => _user;
  List<app_user.User> get allUsers => _allUsers;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAdmin => _isAdmin;

  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> _checkAdminStatus() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      print('Before token refresh - UID: ${user.uid}');
      final token = await user.getIdTokenResult(true);
      print('Token claims: ${token.claims}'); // Debug claims

      final isAdmin = token.claims?['isAdmin'] == true;
      print('Admin status: $isAdmin'); // Debug final status

      _isAdmin = isAdmin;
      notifyListeners();
      return isAdmin;
    } catch (e) {
      print('Error checking admin: $e');
      return false;
    }
  }

  Future<void> setAdminStatus(String uid, bool isAdmin) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('setAdmin');
      await callable({'uid': uid, 'isAdmin': isAdmin});

      // Force refresh current user's token if it's them
      if (uid == FirebaseAuth.instance.currentUser?.uid) {
        await FirebaseAuth.instance.currentUser?.getIdToken(true);
      }
    } catch (e) {
      print('Error setting admin: $e');
      throw Exception('Failed to set admin status');
    }
  }

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      if (userId != null) {
        _user = await _authService.getUserFromFirestore(userId);
        print('Retrieved user from shared preferences: $_user');

        if (_user != null) {
          await _checkAdminStatus();
          if (_isAdmin) {
            await fetchAllUsers();
          }
        } else {
          // User document not found, clear the login state
          await prefs.remove('isLoggedIn');
          await prefs.remove('userId');
        }
      }
      _error = null;
    } catch (e) {
      print('Error initializing auth: $e');
      _error = e.toString();

      // Clear invalid login state on error
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('isLoggedIn');
      await prefs.remove('userId');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      print('Attempting login with email: $email');
      _user = await _authService.login(email, password);
      print('Login successful, user: $_user');

      if (_user != null) {
        await _checkAdminStatus();
        print('Admin status: $_isAdmin');

        // Save login state
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userId', _user!.id);

        // Force notify listeners to trigger rebuild
        notifyListeners();
      }
      _error = null;
    } catch (e) {
      print('Login error: $e');
      _user = null;
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.logout();
      _user = null;
      _allUsers = [];
      _isAdmin = false;
      _error = null;

      // Clear login state
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('isLoggedIn');
      await prefs.remove('userId');

    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // In the register method of AuthProvider
  Future<void> register(Map<String, dynamic> userData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('Starting registration process...');

      // 1. First create the auth user
      final newUser = await _authService.register(userData);
      print('Auth user created successfully for ${newUser?.email}');

      if (newUser == null) throw Exception('User creation failed');

      // 2. Create the user document in Firestore
      await _firestore.collection('users').doc(newUser.id).set({
        'name': userData['name'],
        'email': userData['email'],
        'role': userData['role'],
        'enrollmentNumber': userData['enrollmentNumber'],
        'phone': userData['phone'],
        'department': userData['department'] ?? 'IIC',
        'isAdmin': userData['isAdmin'] ?? false,
        if (userData['course'] != null) 'course': userData['course'],
        if (userData['batch'] != null) 'batch': userData['batch'],
        if (userData['class'] != null) 'class': userData['class'],
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 3. If faculty, add to faculty collection
      if (userData['role'] == AppConstants.facultyRole) {
        await _firestore.collection('faculty').doc(newUser.id).set({
          'name': userData['name'],
          'email': userData['email'],
          'facultyId': userData['enrollmentNumber'],
          'userId': newUser.id, // Reference to the user document
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await fetchAllUsers();
      _error = null;
    } catch (e) {
      print('Registration error in AuthProvider: $e');
      _error = 'Registration failed: ${e.toString()}';

      // Attempt to clean up if anything failed
      try {
        if (FirebaseAuth.instance.currentUser != null) {
          await FirebaseAuth.instance.currentUser?.delete();
        }
      } catch (cleanupError) {
        print('Cleanup error: $cleanupError');
      }

      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAllUsers() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      _allUsers = snapshot.docs
          .map((doc) => app_user.User.fromFirestore(doc.data(), doc.id))
          .toList();
      _error = null;
    } catch (e) {
      _allUsers = [];
      _error = 'Failed to fetch users: ${e.toString()}';
      rethrow;
    }
  }

  Future<void> createUser(Map<String, dynamic> userData) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || !_isAdmin) {
      throw Exception('Unauthorized: Admin access required');
    }

    _isLoading = true;
    notifyListeners();

    try {
      final userCredential = await _authService.createAuthUser(
        userData['email'],
        userData['password'],
      );

      await _firestore.collection('users').doc(userCredential.user?.uid).set({
        'name': userData['name'],
        'email': userData['email'],
        'role': userData['role'] ?? 'student',
        'enrollmentNumber': userData['enrollmentNumber'],
        'department': userData['department'] ?? 'IIC',
        'phone': userData['phone'],
        'batch': userData['batch'],
        'course': userData['course'],
        'class': userData['class'],
        'createdAt': FieldValue.serverTimestamp(),
      });

      await fetchAllUsers();
      _error = null;
    } catch (e) {
      _error = 'Failed to create user: ${e.toString()}';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateUser(String userId, Map<String, dynamic> updates) async {
    if (!_isAdmin) {
      throw Exception('Unauthorized: Admin access required');
    }

    _isLoading = true;
    notifyListeners();

    try {
      await _firestore.collection('users').doc(userId).update(updates);
      await fetchAllUsers();

      if (userId == _user?.id) {
        _user = await _authService.getCurrentUser();
      }

      _error = null;
    } catch (e) {
      _error = 'Failed to update user: ${e.toString()}';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteUser(String userId) async {
    if (!_isAdmin) {
      throw Exception('Unauthorized: Admin access required');
    }

    _isLoading = true;
    notifyListeners();

    try {
      await _firestore.collection('users').doc(userId).delete();
      await _authService.deleteAuthUser(userId);
      await fetchAllUsers();
      _error = null;
    } catch (e) {
      _error = 'Failed to delete user: ${e.toString()}';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> reloadUser() async {
    try {
      _user = await _authService.getCurrentUser();
      if (_user != null) {
        await _checkAdminStatus();
        if (_isAdmin) {
          await fetchAllUsers();
        }
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.sendPasswordResetEmail(email);
      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile(Map<String, dynamic> updates) async {
    if (_user == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      await _firestore.collection('users').doc(_user!.id).update(updates);
      _user = await _authService.getCurrentUser();
      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}