import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:civiczero/models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  Future<UserCredential?> signUpWithEmailPassword({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      // Create user account
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user document in Firestore
      if (userCredential.user != null) {
        await _createUserDocument(
          uid: userCredential.user!.uid,
          email: email,
          username: username,
        );
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        throw 'Google sign-in was cancelled';
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      // Create or update user document
      if (userCredential.user != null && userCredential.additionalUserInfo?.isNewUser == true) {
        await _createUserDocument(
          uid: userCredential.user!.uid,
          email: userCredential.user!.email ?? '',
          username: userCredential.user!.displayName ?? userCredential.user!.email!.split('@')[0],
          displayName: userCredential.user!.displayName,
          photoUrl: userCredential.user!.photoURL,
        );
      }

      return userCredential;
    } catch (e) {
      throw 'Google sign-in failed: $e';
    }
  }

  // Sign in with Apple
  Future<UserCredential?> signInWithApple() async {
    try {
      // Request credential for the currently signed in Apple account
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Create an OAuthCredential from the credential returned by Apple
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      // Sign in to Firebase with the Apple credential
      final UserCredential userCredential = await _auth.signInWithCredential(oauthCredential);

      // Create or update user document
      if (userCredential.user != null && userCredential.additionalUserInfo?.isNewUser == true) {
        String displayName = '';
        if (appleCredential.givenName != null || appleCredential.familyName != null) {
          displayName = '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'.trim();
        }

        await _createUserDocument(
          uid: userCredential.user!.uid,
          email: userCredential.user!.email ?? appleCredential.email ?? '',
          username: displayName.isNotEmpty ? displayName : userCredential.user!.email!.split('@')[0],
          displayName: displayName.isNotEmpty ? displayName : null,
        );
      }

      return userCredential;
    } catch (e) {
      throw 'Apple sign-in failed: $e';
    }
  }

  // Sign out
  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  // Get user data from Firestore
  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      throw 'Failed to fetch user data: $e';
    }
  }

  // Check if username is available (must be unique!)
  Future<bool> isUsernameAvailable(String username) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: username.toLowerCase())
          .limit(1)
          .get();
      
      return querySnapshot.docs.isEmpty;
    } catch (e) {
      return false;
    }
  }

  // Create user document in Firestore (UID-based with unique username)
  Future<void> _createUserDocument({
    required String uid,
    required String email,
    required String username,
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      // Check username uniqueness
      final isAvailable = await isUsernameAvailable(username);
      if (!isAvailable) {
        throw 'Username already taken. Please choose another.';
      }
      
      // Create user document keyed by UID (AUTHORITY)
      final userDoc = _firestore.collection('users').doc(uid);
      
      await userDoc.set({
        'uid': uid,
        'email': email,
        'username': username.toLowerCase(), // Store lowercase for consistency
        'usernameDisplay': username, // Original case for display
        'displayName': displayName,
        'photoUrl': photoUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Failed to create user profile: $e';
    }
  }

  // Get username from UID (for display purposes)
  Future<String> getUsernameFromUid(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data()?['usernameDisplay'] as String? ?? 'Unknown User';
      }
      return 'Unknown User';
    } catch (e) {
      return 'Unknown User';
    }
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}
