import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? _user;
  String? _role;
  bool _loading = true;

  User? get user => _user;
  String? get role => _role;
  bool get loading => _loading;
  bool get isAdmin => _role == 'admin';
  bool get isDriver => _role == 'driver';
  bool get isCitizen => _role == 'citizen';

  AuthProvider() {
    _auth.authStateChanges().listen(_onAuthChanged);
  }

  Future<void> loadUserRole([User? user]) async {
    _loading = true;
    notifyListeners();

    final resolvedUser = user ?? _auth.currentUser;
    _user = resolvedUser;
    print('🔍 loadUserRole called with user: ${resolvedUser?.uid ?? 'null'}');

    if (resolvedUser != null) {
      try {
        final doc = await _db.collection('users').doc(resolvedUser.uid).get();
        if (doc.exists) {
          _role = doc.data()?['role'] as String?;
          print('✅ Role loaded from Firestore: $_role');
        } else {
          print('❌ User document NOT found for uid: ${resolvedUser.uid}');
          _role = null;
        }
      } catch (e) {
        print('❌ Error loading role: $e');
        _role = null;
      }
    } else {
      print('❌ No user provided and no current user');
      _role = null;
    }

    _loading = false;
    notifyListeners();
    print('✅ loadUserRole complete - Role: $_role, Loading: $_loading');
  }

  Future<void> _onAuthChanged(User? user) async {
    print('🔄 Auth state changed: ${user?.uid ?? 'null'}');
    await loadUserRole(user);
  }

  Future<String?> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    try {
      print('📝 Signing up: $email');
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      await _db.collection('users').doc(cred.user!.uid).set({
        'uid': cred.user!.uid,
        'name': name,
        'email': email,
        'phone': phone,
        'role': 'citizen',
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ User created with role: citizen');
      return null;
    } catch (e) {
      print('❌ Signup error: $e');
      return e.toString();
    }
  }

  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      print('🔑 Signing in: $email');
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('✅ Sign in successful');
      return null;
    } catch (e) {
      print('❌ Sign in error: $e');
      return 'Invalid email or password';
    }
  }

  Future<void> signOut() async {
    print('🚪 Signing out');
    await _auth.signOut();
    _user = null;
    _role = null;
    notifyListeners();
  }

  // Helper method to reload user role (useful after role changes)
  Future<void> refreshUserRole() async {
    if (_user != null) {
      await loadUserRole(_user);
    }
  }
}