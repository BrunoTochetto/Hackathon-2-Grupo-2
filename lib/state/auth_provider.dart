import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/establishment_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _user;
  EstablishmentModel? _establishment;
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider() {
    _user = _authService.currentUser;
    _establishment = _authService.currentEstablishment;
    _authService.authStateChanges.listen((user) {
      _user = user;
      _establishment = _authService.currentEstablishment;
      notifyListeners();
    });
  }

  UserModel? get user => _user;
  EstablishmentModel? get establishment => _establishment;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authService.login(email: email, password: password);
      _user = user;
      _establishment = _authService.currentEstablishment;
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Ocorreu um erro ao realizar o login. Tente novamente.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
    required String establishmentName,
    required EstablishmentType establishmentType,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authService.register(
        name: name,
        email: email,
        password: password,
        confirmPassword: confirmPassword,
        establishmentName: establishmentName,
        establishmentType: establishmentType,
      );
      _user = user;
      _establishment = _authService.currentEstablishment;
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Ocorreu um erro inesperado ao cadastrar. Tente novamente.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.sendPasswordResetEmail(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Não foi possível enviar o e-mail de recuperação.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    _establishment = null;
    notifyListeners();
  }

  void updateProfileName(String newName) {
    _authService.updateUserName(newName);
    _user = _authService.currentUser;
    notifyListeners();
  }

  void updateEstablishment(EstablishmentModel establishment) {
    _establishment = establishment;
    _authService.updateEstablishment(establishment);
    notifyListeners();
  }
}
