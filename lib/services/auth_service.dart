import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:local_auth/local_auth.dart';
import 'package:slidequiz/models/user_profile.dart';

class AuthService extends ChangeNotifier {
  final _secureStorage = const FlutterSecureStorage();
  final _localAuth = LocalAuthentication();

  UserProfile? _currentUser;
  bool _isAuthenticated = false;

  UserProfile? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get userExists => _currentUser != null;

  Future<void> init() async {
    // Load user profile from Hive
    var box = await Hive.openBox<UserProfile>('user_profile');
    if (box.isNotEmpty) {
      _currentUser = box.getAt(0);
      notifyListeners();
    }
  }

  Future<void> createUser(String name, String pin, bool useBiometrics) async {
    await _secureStorage.write(key: 'user_pin', value: pin);

    final profile = UserProfile(
      name: name,
      useBiometrics: useBiometrics,
      hasPin: true,
    );

    var box = await Hive.openBox<UserProfile>('user_profile');
    await box.clear();
    await box.add(profile);

    _currentUser = profile;
    _isAuthenticated = true; // Auto login on creation
    notifyListeners();
  }

  Future<bool> verifyPin(String pin) async {
    final storedPin = await _secureStorage.read(key: 'user_pin');
    if (storedPin == pin) {
      _isAuthenticated = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> authenticateWithBiometrics() async {
    try {
      if (!await _localAuth.canCheckBiometrics) return false;

      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to access SlideQuiz',
        biometricOnly: true,
      );

      if (didAuthenticate) {
        _isAuthenticated = true;
        notifyListeners();
      }
      return didAuthenticate;
    } catch (e) {
      debugPrint('Biometric auth error: $e');
      return false;
    }
  }

  void logout() {
    _isAuthenticated = false;
    notifyListeners();
  }
}
