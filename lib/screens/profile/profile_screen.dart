import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:slidequiz/services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _oldPinController = TextEditingController();
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();

  bool _isEditingName = false;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    _nameController.text = user?.name ?? '';
  }

  Future<void> _updateName() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.updateName(_nameController.text);
    setState(() {
      _isEditingName = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name updated successfully')),
      );
    }
  }

  Future<void> _changePin() async {
    if (_newPinController.text != _confirmPinController.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('New PINs do not match')));
      return;
    }

    if (_newPinController.text.length != 4) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('PIN must be 4 digits')));
      return;
    }

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.updatePin(
        _oldPinController.text,
        _newPinController.text,
      );
      if (mounted) {
        // Check mounted BEFORE using context
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PIN updated successfully')),
        );
        _oldPinController.clear();
        _newPinController.clear();
        _confirmPinController.clear();
      }
    } catch (e) {
      if (mounted) {
        // Check mounted here too
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
          ), // Use e.toString() to show the actual error
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Personal Information',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    enabled: _isEditingName,
                    decoration: const InputDecoration(
                      labelText: 'Display Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(_isEditingName ? Icons.save : Icons.edit),
                  onPressed: () {
                    if (_isEditingName) {
                      _updateName();
                    } else {
                      setState(() => _isEditingName = true);
                    }
                  },
                ),
              ],
            ),
            const Divider(height: 40),
            const Text(
              'Security',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Change PIN',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _oldPinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: const InputDecoration(
                labelText: 'Old PIN',
                border: OutlineInputBorder(),
                counterText: '',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _newPinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: const InputDecoration(
                labelText: 'New PIN',
                border: OutlineInputBorder(),
                counterText: '',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmPinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: const InputDecoration(
                labelText: 'Confirm New PIN',
                border: OutlineInputBorder(),
                counterText: '',
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _changePin,
                child: const Text('Update PIN'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
