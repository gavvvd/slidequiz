import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:slidequiz/models/user_profile.dart';

class AuthService extends ChangeNotifier {
  final _secureStorage = const FlutterSecureStorage();

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

  Future<void> createUser(String name, String pin) async {
    await _secureStorage.write(key: 'user_pin', value: pin);

    final profile = UserProfile(name: name, hasPin: true);

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

  Future<void> updateName(String newName) async {
    if (_currentUser != null) {
      _currentUser!.name = newName;
      await _currentUser!.save();
      notifyListeners();
    }
  }

  Future<void> updatePin(String oldPin, String newPin) async {
    final storedPin = await _secureStorage.read(key: 'user_pin');
    if (storedPin == oldPin) {
      await _secureStorage.write(key: 'user_pin', value: newPin);
    } else {
      throw Exception('Incorrect old PIN');
    }
  }

  void logout() {
    _isAuthenticated = false;
    notifyListeners();
  }
}
