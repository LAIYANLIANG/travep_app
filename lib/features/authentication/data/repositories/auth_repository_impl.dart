import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../domain/entities/user_model.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final FirebaseFirestore _firestore;

  AuthRepositoryImpl(
    this._firebaseAuth,
    this._googleSignIn,
    this._firestore,
  );

  @override
  Stream<AppUser?> get user {
    return _firebaseAuth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;
      // Fetch Custom User Data from Firestore
      try {
        final doc = await _firestore.collection('travel_users').doc(firebaseUser.uid).get();
        if (doc.exists && doc.data() != null) {
          // Parse from Firestore
           final data = doc.data()!;
           return AppUser(
             uid: firebaseUser.uid,
             email: firebaseUser.email ?? '',
             displayName: data['display_name'] ?? firebaseUser.displayName ?? '',
             photoUrl: firebaseUser.photoURL,
             role: _parseRole(data['role']),
             points: data['points'] ?? 0,
             freeQuota: data['free_quota'] ?? 10,
             adsWatched: data['ads_watched'] ?? 0,
             joinedProjects: List<String>.from(data['joined_projects'] ?? []),
           );
        }
      } catch (e) {
        // Fallback or Error logging
      }
      
      // Default / New User
      return AppUser(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        displayName: firebaseUser.displayName ?? 'New User',
        photoUrl: firebaseUser.photoURL,
      );
    });
  }
  
  UserRole _parseRole(String? roleStr) {
    if (roleStr == 'admin') return UserRole.admin;
    return UserRole.user;
  }

  @override
  AppUser? get currentUser {
     // This is imperfect because we need the async Firestore data.
     // For now, we return a partial user or null 
     //Ideally, we should rely on the stream or a cached provider.
     final user = _firebaseAuth.currentUser;
     if (user == null) return null;
     return AppUser(
       uid: user.uid,
       email: user.email ?? '',
       displayName: user.displayName ?? '',
       photoUrl: user.photoURL,
     );
  }

  @override
  Future<Either<String, AppUser>> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return const Left("Google Sign In Cancelled");

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);
      final user = userCredential.user;
      
      if (user == null) return const Left("Firebase Sign In Failed");
      
      // Check if user document exists, if not create it
      final userDoc = await _firestore.collection('travel_users').doc(user.uid).get();
      if (!userDoc.exists) {
        await _firestore.collection('travel_users').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email,
          'display_name': user.displayName,
          'role': 'user', // default user role for new architecture
          'points': 0, // 預設點數
          'free_quota': 10, // 免費額度
          'ads_watched': 0, // 看廣告次數
          'joined_projects': [],
          'created_at': FieldValue.serverTimestamp(),
        });
      }

      return Right(AppUser(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? '',
        photoUrl: user.photoURL,
      ));
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, AppUser>> signInWithApple() async {
    // Placeholder - Apple Sign In requires more setup (Apple developer account capability)
    return const Left("Apple Sign In Not Implemented Yet");
  }

  @override
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }

  @override
  Future<Either<String, void>> joinProject(String projectCode) async {
    // Placeholder logic
    return const Left("Join Project Logic Not Implemented");
  }
}
