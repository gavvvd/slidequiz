import 'package:flutter/material.dart';
import 'package:slidequiz/models/subject.dart';
import 'package:slidequiz/models/quiz.dart';
import 'package:slidequiz/services/hive_service.dart';

class QuizFormScreen extends StatefulWidget {
  final Subject subject;
  final Quiz? quiz;

  const QuizFormScreen({
    super.key,
    required this.subject,
    this.quiz,
  });

  @override
  State<QuizFormScreen> createState() => _QuizFormScreenState();
}

class _QuizFormScreenState extends State<QuizFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _timerController = TextEditingController(text: '60');
  final HiveService _hiveService = HiveService();

  bool _randomizeQuestions = false;
  bool _randomizeChoices = false;

  @override
  void initState() {
    super.initState();
    if (widget.quiz != null) {
      _nameController.text = widget.quiz!.name;
      _descriptionController.text = widget.quiz!.description;
      _timerController.text = widget.quiz!.timerSeconds.toString();
      _randomizeQuestions = widget.quiz!.randomizeQuestions;
      _randomizeChoices = widget.quiz!.randomizeChoices;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _timerController.dispose();
    super.dispose();
  }

  Future<void> _saveQuiz() async {
    if (_formKey.currentState!.validate()) {
      final quiz = widget.quiz ??
          Quiz(
            subjectId: widget.subject.id,
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim(),
            randomizeQuestions: _randomizeQuestions,
            randomizeChoices: _randomizeChoices,
            timerSeconds: int.parse(_timerController.text),
          );

      if (widget.quiz != null) {
        quiz.name = _nameController.text.trim();
        quiz.description = _descriptionController.text.trim();
        quiz.randomizeQuestions = _randomizeQuestions;
        quiz.randomizeChoices = _randomizeChoices;
        quiz.timerSeconds = int.parse(_timerController.text);
        await _hiveService.updateQuiz(quiz);
      } else {
        await _hiveService.addQuiz(quiz);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.quiz != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Quiz' : 'Add Quiz'),
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
                labelText: 'Quiz Name',
                hintText: 'e.g., Midterm Exam, Chapter 1 Quiz',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.quiz),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a quiz name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Brief description of the quiz',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _timerController,
              decoration: const InputDecoration(
                labelText: 'Default Timer (seconds)',
                hintText: 'Default time per question',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.timer),
                helperText: 'Questions can override this value',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a timer value';
                }
                if (int.tryParse(value) == null || int.parse(value) < 1) {
                  return 'Must be at least 1 second';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Quiz Options',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Randomize Questions'),
                    subtitle: const Text('Shuffle question order during quiz'),
                    value: _randomizeQuestions,
                    onChanged: (value) {
                      setState(() {
                        _randomizeQuestions = value;
                      });
                    },
                    secondary: const Icon(Icons.shuffle),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Randomize Choices'),
                    subtitle: const Text('Shuffle answer choices for multiple choice questions'),
                    value: _randomizeChoices,
                    onChanged: (value) {
                      setState(() {
                        _randomizeChoices = value;
                      });
                    },
                    secondary: const Icon(Icons.swap_vert),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _saveQuiz,
              icon: const Icon(Icons.save),
              label: Text(isEditing ? 'Update Quiz' : 'Create Quiz'),
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
