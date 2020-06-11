import 'dart:async';

import 'package:agro_picker_bloc/agri_picker_blocs.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class UserRepository {
  static FirebaseAppSingleton firebaseAppSingleton =
      FirebaseAppSingleton.getInstance();
  final FirebaseAuth _firebaseAuth = firebaseAppSingleton.firebaseAuth;
  final CollectionReference _userCollection =
      firebaseAppSingleton.firestore.collection('users');
  final GoogleSignIn _googleSignIn;

  UserRepository({FirebaseAuth firebaseAuth, GoogleSignIn googleSignIn})
      : _googleSignIn = googleSignIn ?? GoogleSignIn();

  Future<FirebaseUser> signInWithGoogle() async {
    final GoogleSignInAccount googleUser = await _googleSignIn.signIn();
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;
    final AuthCredential credential = GoogleAuthProvider.getCredential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    await _firebaseAuth.signInWithCredential(credential);
    return _firebaseAuth.currentUser();
  }

  Future<void> signInWithCredentials(String email, String password) {
    return _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResult> signUp({String email, String password}) async {
    return await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    return Future.wait([
      _firebaseAuth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  Future<bool> isSignedIn() async {
    final currentUser = await _firebaseAuth.currentUser();
    return currentUser != null && !currentUser.isEmailVerified;
  }

  Future<String> getUser() async {
    return (await _firebaseAuth.currentUser()).email;
  }

  getCurrentUser() async {
    return await _firebaseAuth.currentUser();
  }

  getUserDataStream() async* {
    var docId = (await _firebaseAuth.currentUser()).uid;
    yield* _userCollection.document(docId).snapshots();
  }

  Future<void> addUser(Users user) {
    return _userCollection.document(user.userId).setData(user.toJson());
  }

  updateUser(Users user) async {
    await _userCollection.document(user.userId).updateData(user.toJson());
  }

  Future<void> sendEmailVerification() async {
    final currentUser = await _firebaseAuth.currentUser();
    currentUser.sendEmailVerification();
  }

  Future<bool> isEmailVerified() async {
    final currentUser = await _firebaseAuth.currentUser();
    currentUser.reload();
    if (currentUser.isEmailVerified) {
      return true;
    }
    return false;
  }

  Stream<bool> isEmailVerifiedOb() async* {
    final currentUser = await _firebaseAuth.currentUser();
    var controller = StreamController<bool>();
    currentUser.reload();

    if (currentUser.isEmailVerified) {
      controller.sink.add(true);
      yield* controller.stream;
      controller.close();
    } else {
      yield* isEmailVerifiedOb();
    }
  }
}
