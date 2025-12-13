import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

/// Serviço de autenticação e gestão de utilizadores.
class AuthService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  UserModel? _userData;
  UserModel? get userData => _userData;

  AuthService() {
    _supabase.auth.onAuthStateChange.listen((AuthState state) {
      if (state.session?.user != null) {
        _loadUserData(state.session!.user.id);
      } else {
        _userData = null;
      }
      notifyListeners();
    });
  }

  /// Carrega os dados do utilizador da base de dados.
  Future<void> _loadUserData(String uid) async {
    try {
      final data = await _supabase
          .from('users')
          .select(
              'id, email, name, phone, user_type, created_at, is_verified, kyc_status, kyc_submitted_at, kyc_approved_at, kyc_rejected_at, verification_level, verification_documents, trust_score, completed_bookings, cancelled_bookings, average_rating, total_reviews, preferences, favorite_vehicles, blocked_users, is_admin')
          .eq('id', uid)
          .single();

      _userData = UserModel.fromJson(data);
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao carregar dados do utilizador: $e');
    }
  }

  /// Recarrega os dados do utilizador atual.
  Future<void> reloadUserData() async {
    if (currentUser != null) {
      await _loadUserData(currentUser!.id);
    }
  }

  /// Regista um novo utilizador com email e password.
  Future<String?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String userType,
  }) async {
    try {
      final AuthResponse response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        final userData = {
          'id': response.user!.id,
          'email': email,
          'name': name,
          'phone': phone,
          'user_type': userType,
          'created_at': DateTime.now().toIso8601String(),
          'is_verified': false,
          'kyc_status': 'none',
          'trust_score': 0.0,
          'completed_bookings': 0,
          'cancelled_bookings': 0,
          'average_rating': 0.0,
          'total_reviews': 0,
          'preferences': {},
          'favorite_vehicles': [],
          'blocked_users': [],
        };

        await _supabase.from('users').insert(userData);
        await _loadUserData(response.user!.id);

        return null;
      }
    } on AuthException catch (e) {
      switch (e.message) {
        case 'User already registered':
          return 'Este email já está registado.';
        case 'Password should be at least 6 characters':
          return 'A palavra-passe deve ter pelo menos 6 caracteres.';
        default:
          return 'Erro ao registar: ${e.message}';
      }
    } catch (e) {
      return 'Erro inesperado: $e';
    }
    return 'Erro ao criar conta';
  }

  /// Inicia sessão com email e password.
  Future<String?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final AuthResponse response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        await _loadUserData(response.user!.id);
        return null;
      }
    } on AuthException catch (e) {
      switch (e.message) {
        case 'Invalid login credentials':
          return 'Email ou palavra-passe incorretos.';
        case 'Email not confirmed':
          return 'Por favor, confirme o seu email antes de fazer login.';
        default:
          return 'Erro ao entrar: ${e.message}';
      }
    } catch (e) {
      return 'Erro inesperado: $e';
    }
    return 'Erro ao entrar';
  }

  /// Termina a sessão do utilizador atual.
  Future<void> signOut() async {
    await _supabase.auth.signOut();
    _userData = null;
    notifyListeners();
  }

  /// Envia email de recuperação de password.
  Future<String?> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      return null;
    } on AuthException catch (e) {
      return 'Erro: ${e.message}';
    } catch (e) {
      return 'Erro inesperado: $e';
    }
  }

  /// Atualiza o perfil do utilizador.
  Future<String?> updateUserProfile({
    required Map<String, dynamic> updates,
  }) async {
    try {
      if (currentUser == null) return 'Utilizador não autenticado';

      final processedUpdates = <String, dynamic>{};

      updates.forEach((key, value) {
        if (value is DateTime) {
          processedUpdates[key] = value.toIso8601String();
        } else {
          processedUpdates[key] = value;
        }
      });

      await _supabase
          .from('users')
          .update(processedUpdates)
          .eq('id', currentUser!.id);

      await _loadUserData(currentUser!.id);

      return null;
    } catch (e) {
      return 'Erro ao atualizar perfil: $e';
    }
  }

  /// Verifica se o utilizador é proprietário.
  bool get isOwner {
    if (_userData == null) return false;
    return _userData!.userType == 'owner';
  }

  /// Verifica se o utilizador é cliente.
  bool get isRenter {
    if (_userData == null) return false;
    return _userData!.userType == 'renter';
  }

  /// Obtém o ID do utilizador atual.
  String? get currentUserId => currentUser?.id;
}
