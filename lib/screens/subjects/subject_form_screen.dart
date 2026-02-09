import 'package:flutter/material.dart';
import 'package:slidequiz/models/subject.dart';
import 'package:slidequiz/services/hive_service.dart';

class SubjectFormScreen extends StatefulWidget {
  final Subject? subject;

  const SubjectFormScreen({super.key, this.subject});

  @override
  State<SubjectFormScreen> createState() => _SubjectFormScreenState();
}

class _SubjectFormScreenState extends State<SubjectFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final HiveService _hiveService = HiveService();

  @override
  void initState() {
    super.initState();
    if (widget.subject != null) {
      _nameController.text = widget.subject!.name;
      _descriptionController.text = widget.subject!.description;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveSubject() async {
    if (_formKey.currentState!.validate()) {
      final subject =
          widget.subject ??
          Subject(
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim(),
          );

      if (widget.subject != null) {
        subject.name = _nameController.text.trim();
        subject.description = _descriptionController.text.trim();
        await _hiveService.updateSubject(subject);
      } else {
        await _hiveService.addSubject(subject);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.subject != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Subject' : 'Add Subject'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Subject Name',
                hintText: 'e.g., Mathematics, Science',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.school),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a subject name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Brief description of the subject',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _saveSubject,
              icon: const Icon(Icons.save),
              label: Text(isEditing ? 'Update Subject' : 'Create Subject'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
