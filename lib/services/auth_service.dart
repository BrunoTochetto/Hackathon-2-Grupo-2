import 'dart:async';
import '../models/user_model.dart';
import '../models/establishment_model.dart';
import 'backend_service.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

/// Serviço de Autenticação com suporte a multi-empresa e persistência no backend Node.js
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final BackendService _backend = BackendService();

  UserModel? _currentUser;
  EstablishmentModel? _currentEstablishment;
  final StreamController<UserModel?> _authStateController =
      StreamController<UserModel?>.broadcast();

  Stream<UserModel?> get authStateChanges => _authStateController.stream;
  UserModel? get currentUser => _currentUser;
  EstablishmentModel? get currentEstablishment => _currentEstablishment;
  bool get isAuthenticated => _currentUser != null;

  /// Cadastro completo de usuário e empresa no Backend
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
    required String establishmentName,
    required EstablishmentType establishmentType,
  }) async {
    if (name.trim().isEmpty) {
      throw AuthException('Por favor, informe seu nome completo.');
    }
    if (email.trim().isEmpty || !email.contains('@') || !email.contains('.')) {
      throw AuthException('Informe um e-mail válido.');
    }
    if (password.length < 4) {
      throw AuthException('A senha deve ter pelo menos 4 caracteres.');
    }
    if (password != confirmPassword) {
      throw AuthException('As senhas digitadas não coincidem.');
    }
    if (establishmentName.trim().isEmpty) {
      throw AuthException('Informe o nome da sua empresa / restaurante.');
    }

    final cleanEmail = email.trim().toLowerCase();

    // Tenta cadastrar no backend Node.js
    final backendResult = await _backend.register(
      email: cleanEmail,
      password: password,
      name: name.trim(),
      establishmentName: establishmentName.trim(),
    );

    final String userId;
    final String establishmentId;
    final String finalRestName;

    if (backendResult != null && backendResult['user'] != null) {
      final u = backendResult['user'];
      final r = backendResult['restaurante'];
      userId = (u['id'] ?? '1').toString();
      establishmentId = (r['id'] ?? '1').toString();
      finalRestName = r['nome'] ?? establishmentName.trim();
    } else {
      userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
      establishmentId = 'est_${DateTime.now().millisecondsSinceEpoch}';
      finalRestName = establishmentName.trim();
    }

    final user = UserModel(
      id: userId,
      name: name.trim(),
      email: cleanEmail,
      establishmentId: establishmentId,
      createdAt: DateTime.now(),
    );

    final establishment = EstablishmentModel(
      id: establishmentId,
      name: finalRestName,
      type: EstablishmentType.restaurante,
      ownerId: userId,
      openingTime: '11:00',
      closingTime: '14:30',
      currentGuests: 0,
      expectedGuests: 120,
      updatedAt: DateTime.now(),
    );

    _currentUser = user;
    _currentEstablishment = establishment;
    _authStateController.add(user);

    return user;
  }

  /// Login com e-mail e senha no Backend
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      throw AuthException('Por favor, informe um e-mail válido.');
    }
    if (password.isEmpty) {
      throw AuthException('Por favor, informe sua senha.');
    }

    // Tenta autenticar no backend Node.js
    final backendResult = await _backend.login(email: cleanEmail, password: password);

    final String userId;
    final String establishmentId;
    final String restName;

    if (backendResult != null && backendResult['user'] != null) {
      final u = backendResult['user'];
      final r = backendResult['restaurante'];
      userId = (u['id'] ?? '1').toString();
      establishmentId = (r['id'] ?? '1').toString();
      restName = r['nome'] ?? 'Restaurante Sabor & Arte';
    } else {
      userId = 'user_${cleanEmail.hashCode.abs()}';
      establishmentId = 'est_1';
      restName = 'Restaurante Sabor & Arte';
    }

    final user = UserModel(
      id: userId,
      name: cleanEmail.split('@').first.toUpperCase(),
      email: cleanEmail,
      establishmentId: establishmentId,
      createdAt: DateTime.now(),
    );

    final establishment = EstablishmentModel(
      id: establishmentId,
      name: restName,
      type: EstablishmentType.restaurante,
      ownerId: userId,
      openingTime: '11:00',
      closingTime: '14:30',
      currentGuests: 38,
      expectedGuests: 120,
      updatedAt: DateTime.now(),
    );

    _currentUser = user;
    _currentEstablishment = establishment;
    _authStateController.add(user);

    return user;
  }

  Future<void> sendPasswordResetEmail(String email) async {
    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      throw AuthException('Informe um e-mail válido para envio da recuperação.');
    }
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<void> logout() async {
    _currentUser = null;
    _currentEstablishment = null;
    _authStateController.add(null);
  }

  void updateEstablishment(EstablishmentModel establishment) {
    _currentEstablishment = establishment;
  }

  void updateUserName(String newName) {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(name: newName);
      _authStateController.add(_currentUser);
    }
  }
}
