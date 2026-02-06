import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:slidequiz/services/auth_service.dart';
import 'package:slidequiz/screens/auth/login_screen.dart';
import 'package:slidequiz/screens/auth/setup_wizard.dart';
import 'package:slidequiz/screens/subjects/subject_list_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // Trigger initialization if not already done, though main calls init
    WidgetsBinding.instance.addPostFrameCallback((_) {
       // Optional: could do async checks here 
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    if (!authService.userExists) {
      return const SetupWizard();
    }

    if (!authService.isAuthenticated) {
      return const LoginScreen();
    }

    return const SubjectListScreen();
  }
}
