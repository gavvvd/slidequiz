import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:slidequiz/services/auth_service.dart';
import 'package:slidequiz/screens/subjects/subject_list_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _pin = '';
  String _error = '';
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Request focus for keyboard input
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _onDigitPress(String digit) {
    setState(() {
      if (_pin.length < 4) {
        _pin += digit;
        _error = '';
      }
      if (_pin.length == 4) {
        _verifyPin();
      }
    });
  }

  void _onDeletePress() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _error = '';
      });
    }
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey.keyLabel.isNotEmpty &&
          RegExp(r'^[0-9]$').hasMatch(event.logicalKey.keyLabel)) {
        _onDigitPress(event.logicalKey.keyLabel);
      } else if (event.logicalKey == LogicalKeyboardKey.backspace ||
          event.logicalKey == LogicalKeyboardKey.delete) {
        _onDeletePress();
      }
    }
  }

  Future<void> _verifyPin() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final isValid = await authService.verifyPin(_pin);
    if (isValid) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const SubjectListScreen()),
        );
      }
    } else {
      setState(() {
        _pin = '';
        _error = 'Incorrect PIN';
      });
    }
  }

  Widget _buildKeypadButton(String value, VoidCallback onPressed) {
    return Container(
      margin: const EdgeInsets.all(8),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          shape: const CircleBorder(),
          padding: const EdgeInsets.all(24),
          backgroundColor: Colors.grey[200],
          foregroundColor: Colors.black,
        ),
        onPressed: onPressed,
        child: Text(value, style: const TextStyle(fontSize: 24)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).currentUser;

    return Scaffold(
      body: KeyboardListener(
        focusNode: _focusNode,
        onKeyEvent: _handleKeyEvent,
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 40),
              Text(
                'Welcome back, ${user?.name ?? "User"}!',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 20),
              Text('Enter PIN', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index < _pin.length
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey[300],
                    ),
                  );
                }),
              ),
              if (_error.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    _error,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              const Spacer(),
              Expanded(
                flex: 5,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildKeypadButton('1', () => _onDigitPress('1')),
                        _buildKeypadButton('2', () => _onDigitPress('2')),
                        _buildKeypadButton('3', () => _onDigitPress('3')),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildKeypadButton('4', () => _onDigitPress('4')),
                        _buildKeypadButton('5', () => _onDigitPress('5')),
                        _buildKeypadButton('6', () => _onDigitPress('6')),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildKeypadButton('7', () => _onDigitPress('7')),
                        _buildKeypadButton('8', () => _onDigitPress('8')),
                        _buildKeypadButton('9', () => _onDigitPress('9')),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(width: 80), // Empty space for alignment
                        _buildKeypadButton('0', () => _onDigitPress('0')),
                        Container(
                          margin: const EdgeInsets.all(8),
                          child: TextButton(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.all(24),
                              shape: const CircleBorder(),
                            ),
                            onPressed: _onDeletePress,
                            child: const Icon(Icons.backspace, size: 24),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 48,
              ), // Bottom padding since biometric button is removed
            ],
          ),
        ),
      ),
    );
  }
}
