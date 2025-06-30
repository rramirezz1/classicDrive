import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  UserModel? _userData;
  UserModel? get userData => _userData;

  // Construtor
  AuthService() {
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _loadUserData(user.uid);
      } else {
        _userData = null;
      }
      notifyListeners();
    });
  }

  // Carregar dados do utilizador
  Future<void> _loadUserData(String uid) async {
    try {
      print("=== LOADING USER DATA ===");
      print("UID: $uid");

      final doc = await _firestore.collection('users').doc(uid).get();
      print("Document exists: ${doc.exists}");

      if (doc.exists) {
        print("Document data: ${doc.data()}");
        _userData = UserModel.fromMap(doc.data()!);
        notifyListeners();
      } else {
        print("ERRO: Documento não existe no Firestore!");
      }
    } catch (e) {
      print('ERRO ao carregar dados do utilizador: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
    }
  }

  // Registar novo utilizador
  Future<String?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String userType,
  }) async {
    try {
      // Criar conta no Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        print("=== CREATING USER DOCUMENT ===");
        print("UID: ${credential.user!.uid}");
        // Criar documento do utilizador no Firestore
        final userData = UserModel(
          uid: credential.user!.uid,
          email: email,
          name: name,
          phone: phone,
          userType: userType,
          createdAt: DateTime.now(),
          isVerified: false,
        );

        print("UserData to save: ${userData.toMap()}");

        await _firestore
            .collection('users')
            .doc(credential.user!.uid)
            .set(userData.toMap());

        print("=== USER DOCUMENT CREATED ===");

        _userData = userData;
        notifyListeners();

        return null; // Sucesso
      }
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'weak-password':
          return 'A palavra-passe é muito fraca.';
        case 'email-already-in-use':
          return 'Este email já está registado.';
        case 'invalid-email':
          return 'Email inválido.';
        default:
          return 'Erro ao registar: ${e.message}';
      }
    } catch (e) {
      return 'Erro inesperado: $e';
    }
    return 'Erro ao criar conta';
  }

  // Login com email e password
  Future<String?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null; // Sucesso
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          return 'Utilizador não encontrado.';
        case 'wrong-password':
          return 'Palavra-passe incorreta.';
        case 'invalid-email':
          return 'Email inválido.';
        case 'user-disabled':
          return 'Esta conta foi desativada.';
        default:
          return 'Erro ao entrar: ${e.message}';
      }
    } catch (e) {
      return 'Erro inesperado: $e';
    }
  }

  // Logout
  Future<void> signOut() async {
    await _auth.signOut();
    _userData = null;
    notifyListeners();
  }

  // Recuperar password
  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null; // Sucesso
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          return 'Email não encontrado.';
        case 'invalid-email':
          return 'Email inválido.';
        default:
          return 'Erro: ${e.message}';
      }
    } catch (e) {
      return 'Erro inesperado: $e';
    }
  }

  // Atualizar perfil do utilizador
  Future<String?> updateUserProfile({
    required Map<String, dynamic> updates,
  }) async {
    try {
      if (currentUser == null) return 'Utilizador não autenticado';

      await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .update(updates);

      // Recarregar dados do utilizador
      await _loadUserData(currentUser!.uid);

      return null; // Sucesso
    } catch (e) {
      return 'Erro ao atualizar perfil: $e';
    }
  }

  

  // Verificar se é proprietário
  bool get isOwner => _userData?.userType == 'owner';

  // Verificar se é cliente
  bool get isRenter => _userData?.userType == 'renter';
}
