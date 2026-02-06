import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:slidequiz/services/auth_service.dart';
import 'package:slidequiz/screens/subjects/subject_list_screen.dart';

class SetupWizard extends StatefulWidget {
  const SetupWizard({super.key});

  @override
  State<SetupWizard> createState() => _SetupWizardState();
}

class _SetupWizardState extends State<SetupWizard> {
  final PageController _pageController = PageController();
  final _nameController = TextEditingController();
  String _pin = '';
  String _confirmPin = '';
  bool _useBiometrics = false;
  int _currentPage = 0;

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _finishSetup() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.createUser(_nameController.text, _pin, _useBiometrics);
     if (mounted) {
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const SubjectListScreen()),
          );
      }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: (page) => setState(() => _currentPage = page),
          children: [
            _buildNameStep(),
            _buildPinStep(),
            _buildBiometricStep(),
          ],
        ),
      ),
    );
  }

  Widget _buildNameStep() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Welcome to SlideQuiz', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text('Let\'s verify your identity. What should we call you?'),
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Display Name',
              border: OutlineInputBorder(),
            ),
            onChanged: (val) => setState(() {}),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _nameController.text.isNotEmpty ? _nextPage : null,
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }

  Widget _buildPinStep() {
    // Simplified PIN input for wizard
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Create a PIN', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text('This will be used to access the app.'),
          const SizedBox(height: 24),
          TextField(
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 4,
            decoration: const InputDecoration(
              labelText: 'Enter 4-digit PIN',
              border: OutlineInputBorder(),
              counterText: '',
            ),
            onChanged: (val) => setState(() => _pin = val),
          ),
          const SizedBox(height: 16),
           TextField(
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 4,
            decoration: const InputDecoration(
              labelText: 'Confirm PIN',
              border: OutlineInputBorder(),
               counterText: '',
            ),
            onChanged: (val) => setState(() => _confirmPin = val),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: (_pin.length == 4 && _pin == _confirmPin) ? _nextPage : null,
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }

  Widget _buildBiometricStep() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Enable Biometrics?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text('Use fingerprint or face unlock for faster access.'),
          const SizedBox(height: 24),
          SwitchListTile(
            title: const Text('Use Biometrics'),
            value: _useBiometrics,
            onChanged: (val) => setState(() => _useBiometrics = val),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _finishSetup,
            child: const Text('Finish Setup'),
          ),
        ],
      ),
    );
  }
}
