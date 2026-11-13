import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'database_helper.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream of user auth state
  Stream<User?> get firebaseUserStream => _firebaseAuth.authStateChanges();

  // Login
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final UserCredential credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (credential.user == null) {
      throw Exception("User tidak ditemukan");
    }

    // Fetch additional profile from Firestore
    final userDoc = await _firestore.collection('users').doc(credential.user!.uid).get();
    UserModel user;

    if (userDoc.exists && userDoc.data() != null) {
      user = UserModel.fromMap(userDoc.data()!, credential.user!.uid);
    } else {
      // Fallback profile if Firestore document does not exist yet
      user = UserModel(
        uid: credential.user!.uid,
        name: email.split('@')[0],
        email: email,
        nim: 'N/A',
        major: 'N/A',
      );
    }

    // Cache user locally
    await DatabaseHelper.saveLocalUser(user.toMap());
    return user;
  }

  // Register
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required String nim,
    required String major,
  }) async {
    final UserCredential credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (credential.user == null) {
      throw Exception("Gagal melakukan registrasi");
    }

    final user = UserModel(
      uid: credential.user!.uid,
      name: name,
      email: email,
      nim: nim,
      major: major,
    );

    // Save user profile to Firestore
    await _firestore.collection('users').doc(user.uid).set(user.toMap());

    // Also cache user locally
    await DatabaseHelper.saveLocalUser(user.toMap());

    return user;
  }

  // Get Current Authenticated User Profile
  Future<UserModel?> getCurrentUser() async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) return null;

    try {
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      if (userDoc.exists && userDoc.data() != null) {
        return UserModel.fromMap(userDoc.data()!, currentUser.uid);
      }
    } catch (_) {
      // Fallback to local cache
    }

    // Fallback user from shared_preferences cache
    final cachedUser = await DatabaseHelper.getLocalUser();
    if (cachedUser != null && cachedUser['uid'] == currentUser.uid) {
      return UserModel.fromMap(cachedUser, currentUser.uid);
    }

    return UserModel(
      uid: currentUser.uid,
      name: currentUser.displayName ?? currentUser.email?.split('@')[0] ?? 'User',
      email: currentUser.email ?? '',
      nim: 'N/A',
      major: 'N/A',
    );
  }

  // Sign Out
  Future<void> logout() async {
    try {
      await DatabaseHelper.clearLocalUser();
    } catch (e) {
      // Local cache clear fallback
    }
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      // FirebaseAuth sign out error fallback
    }
  }
}
