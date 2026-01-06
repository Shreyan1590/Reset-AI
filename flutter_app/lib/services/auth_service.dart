import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // GoogleSignIn with web clientId for Flutter Web
  // For web, we need to use the OAuth 2.0 Client ID from Google Cloud Console
  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb 
        ? '883561761358-q5kc0u02jvjv7ju6v4c5hj5f3l2h4k7g.apps.googleusercontent.com'
        : null,
    scopes: ['email', 'profile'],
  );
  User? _user;
  Map<String, dynamic>? _userProfile;
  bool _isLoading = false;
  String? _error;
  bool _needsPasswordSetup = false;
  bool _isInitialized = false;

  User? get user => _user;
  Map<String, dynamic>? get userProfile => _userProfile;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get needsPasswordSetup => _needsPasswordSetup;
  bool get isInitialized => _isInitialized;
  
  // Check if password is set - always fetch fresh from profile
  bool get hasPassword {
    if (_userProfile == null) return false;
    return _userProfile!['hasPassword'] == true;
  }

  AuthService() {
    _init();
  }

  Future<void> _init() async {
    _auth.authStateChanges().listen((User? user) async {
      _user = user;
      if (user != null) {
        await _fetchUserProfile(); // Always fetch fresh profile
        await _saveSession();
      } else {
        _userProfile = null;
        _needsPasswordSetup = false;
        await _clearSession();
      }
      _isInitialized = true;
      notifyListeners();
    });
    
    await _restoreSession();
  }

  Future<void> _saveSession() async {
    if (_user == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', _user!.uid);
    await prefs.setString('userEmail', _user!.email ?? '');
    await prefs.setString('userName', _user!.displayName ?? '');
  }

  Future<void> _restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    if (userId != null && _user == null) {
      notifyListeners();
    }
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    await prefs.remove('userEmail');
    await prefs.remove('userName');
  }

  // Fetch user profile from Firestore - always get fresh data
  Future<void> _fetchUserProfile() async {
    if (_user == null) return;
    
    try {
      final doc = await _firestore.collection('users').doc(_user!.uid).get();
      
      if (doc.exists) {
        _userProfile = doc.data();
        _needsPasswordSetup = _userProfile?['hasPassword'] != true;
        
        // Update last login
        await _firestore.collection('users').doc(_user!.uid).update({
          'lastLogin': FieldValue.serverTimestamp(),
        });
      } else {
        // New user - needs to create profile
        _needsPasswordSetup = true;
        await _createUserProfile(isGoogleUser: _isGoogleUser(), hasPassword: false);
      }
    } catch (e) {
      _error = 'Failed to load profile';
    }
    notifyListeners();
  }

  // Force refresh profile from Firestore
  Future<void> refreshProfile() async {
    if (_user == null) return;
    await _fetchUserProfile();
  }

  bool _isGoogleUser() {
    return _user?.providerData.any((p) => p.providerId == 'google.com') ?? false;
  }

  // Create user profile in Firestore
  Future<void> _createUserProfile({
    bool isGoogleUser = false, 
    bool hasPassword = false,
    String? name,
  }) async {
    if (_user == null) return;
    
    final profile = {
      'name': name ?? _user!.displayName ?? 'User',
      'email': _user!.email ?? '',
      'photoURL': _user!.photoURL ?? '',
      'authProvider': hasPassword ? (isGoogleUser ? 'google-linked-password' : 'email') : (isGoogleUser ? 'google' : 'email'),
      'hasPassword': hasPassword,
      'focusScore': 75,
      'lastLogin': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      'settings': {
        'aiSensitivity': 5,
        'darkMode': true,
        'notificationsEnabled': true,
      },
      'stats': {
        'totalRecoveries': 0,
        'totalFocusTime': 0,
        'streak': 0,
      },
    };
    
    await _firestore.collection('users').doc(_user!.uid).set(profile);
    _userProfile = profile;
    _needsPasswordSetup = !hasPassword;
  }

  // Email/Password Sign Up - password is set from the start
  Future<bool> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        await credential.user!.updateDisplayName(name);
        _user = credential.user;
        await _createUserProfile(isGoogleUser: false, hasPassword: true, name: name);
      }

      _isLoading = false;
      _needsPasswordSetup = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _error = _getAuthErrorMessage(e.code);
      notifyListeners();
      return false;
    }
  }

  // Email/Password Sign In - check password status after
  Future<Map<String, dynamic>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Fetch profile to check passwordSet
      await _fetchUserProfile();

      _isLoading = false;
      notifyListeners();
      
      return {
        'success': true,
        'needsPassword': _needsPasswordSetup,
      };
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _error = _getAuthErrorMessage(e.code);
      notifyListeners();
      return {'success': false, 'needsPassword': false};
    }
  }

  // Google Sign In - always check password status
  // Uses signInWithPopup for web, google_sign_in for mobile
  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      UserCredential userCredential;
      
      if (kIsWeb) {
        // For web: use Firebase Auth's signInWithPopup directly
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        googleProvider.setCustomParameters({
          'prompt': 'select_account'
        });
        
        userCredential = await _auth.signInWithPopup(googleProvider);
      } else {
        // For mobile: use google_sign_in package
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          _isLoading = false;
          notifyListeners();
          return {'success': false, 'needsPassword': false};
        }

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        userCredential = await _auth.signInWithCredential(credential);
      }
      
      _user = userCredential.user;

      // Check if user exists in Firestore and has password set
      final doc = await _firestore.collection('users').doc(_user!.uid).get();
      
      if (doc.exists) {
        _userProfile = doc.data();
        _needsPasswordSetup = _userProfile?['hasPassword'] != true;
        
        // Update last login
        await _firestore.collection('users').doc(_user!.uid).update({
          'lastLogin': FieldValue.serverTimestamp(),
        });
      } else {
        // NEW Google user - needs password setup
        await _createUserProfile(isGoogleUser: true, hasPassword: false);
        _needsPasswordSetup = true;
      }

      _isLoading = false;
      notifyListeners();
      
      return {
        'success': true, 
        'needsPassword': _needsPasswordSetup,
        'user': _user
      };
    } catch (e) {
      _isLoading = false;
      _error = 'Google sign in failed: ${e.toString()}';
      notifyListeners();
      return {'success': false, 'needsPassword': false, 'error': e.toString()};
    }
  }

  // Set password for user - link with credential if Google user
  Future<bool> setPasswordForUser(String password) async {
    if (_user == null) return false;
    
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final email = _user!.email;
      if (email == null) {
        _error = 'No email associated with this account';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Check if user is Google-only (no email provider linked)
      final hasEmailProvider = _user!.providerData.any((p) => p.providerId == 'password');
      
      if (!hasEmailProvider) {
        // Link the password credential to the current user
        final credential = EmailAuthProvider.credential(
          email: email,
          password: password,
        );
        await _user!.linkWithCredential(credential);
      }

      // Update Firestore - mark password as set
      await _firestore.collection('users').doc(_user!.uid).update({
        'hasPassword': true,
        'authProvider': _isGoogleUser() ? 'google-linked-password' : 'email',
        'lastLogin': FieldValue.serverTimestamp(),
      });

      _userProfile?['hasPassword'] = true;
      _userProfile?['authProvider'] = _isGoogleUser() ? 'google-linked-password' : 'email';
      _needsPasswordSetup = false;

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _error = _getAuthErrorMessage(e.code);
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to set password: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      _user = null;
      _userProfile = null;
      _needsPasswordSetup = false;
      notifyListeners();
    } catch (e) {
      _error = 'Sign out failed';
      notifyListeners();
    }
  }

  // Update user profile
  Future<bool> updateProfile({
    String? name,
    String? photo,
    Map<String, dynamic>? settings,
  }) async {
    if (_user == null) return false;
    
    try {
      final updates = <String, dynamic>{
        'lastLogin': FieldValue.serverTimestamp(),
      };
      
      if (name != null) {
        updates['name'] = name;
        await _user!.updateDisplayName(name);
      }
      if (photo != null) updates['photoURL'] = photo;
      if (settings != null) {
        settings.forEach((key, value) {
          updates['settings.$key'] = value;
        });
      }
      
      await _firestore.collection('users').doc(_user!.uid).update(updates);
      await _fetchUserProfile();
      return true;
    } catch (e) {
      _error = 'Failed to update profile';
      notifyListeners();
      return false;
    }
  }

  // Update focus score
  Future<void> updateFocusScore(double score) async {
    if (_user == null) return;
    
    try {
      await _firestore.collection('users').doc(_user!.uid).update({
        'focusScore': score,
        'lastLogin': FieldValue.serverTimestamp(),
      });
      
      if (_userProfile != null) {
        _userProfile!['focusScore'] = score;
        notifyListeners();
      }
    } catch (e) {
      // Silent fail
    }
  }

  // Get context memory
  Future<Map<String, dynamic>?> getContextMemory() async {
    if (_user == null) return null;
    
    try {
      final doc = await _firestore
          .collection('userData')
          .doc(_user!.uid)
          .collection('context')
          .doc('current')
          .get();
      
      return doc.data();
    } catch (e) {
      return null;
    }
  }

  // Save context memory
  Future<void> saveContextMemory({
    required String lastTask,
    String? lastNotes,
    Map<String, dynamic>? recoveryState,
  }) async {
    if (_user == null) return;
    
    try {
      await _firestore
          .collection('userData')
          .doc(_user!.uid)
          .collection('context')
          .doc('current')
          .set({
            'lastTask': lastTask,
            'lastNotes': lastNotes,
            'recoveryState': recoveryState,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (e) {
      // Silent fail
    }
  }

  // Password reset
  Future<bool> resetPassword(String email) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _auth.sendPasswordResetEmail(email: email);

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _error = _getAuthErrorMessage(e.code);
      notifyListeners();
      return false;
    }
  }

  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'weak-password':
        return 'Password is too weak (min 6 characters)';
      case 'email-already-in-use':
        return 'Email already in use';
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'provider-already-linked':
        return 'Password already set for this account';
      case 'credential-already-in-use':
        return 'This credential is already associated with another account';
      case 'invalid-credential':
        return 'Invalid email or password';
      default:
        return 'Authentication failed';
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
