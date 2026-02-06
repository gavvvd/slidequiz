import 'package:flutter/material.dart';
import 'package:slidequiz/models/subject.dart';
import 'package:slidequiz/models/quiz.dart';
import 'package:slidequiz/services/hive_service.dart';
import 'package:slidequiz/screens/quizzes/quiz_form_screen.dart';
import 'package:slidequiz/screens/questions/question_list_screen.dart';
import 'package:slidequiz/screens/quiz_sets/quiz_set_list_screen.dart';

class QuizListScreen extends StatefulWidget {
  final Subject subject;

  const QuizListScreen({super.key, required this.subject});

  @override
  State<QuizListScreen> createState() => _QuizListScreenState();
}

class _QuizListScreenState extends State<QuizListScreen> {
  final HiveService _hiveService = HiveService();
  List<Quiz> _quizzes = [];

  @override
  void initState() {
    super.initState();
    _loadQuizzes();
  }

  void _loadQuizzes() {
    setState(() {
      _quizzes = _hiveService.getQuizzesBySubject(widget.subject.id);
    });
  }

  Future<void> _deleteQuiz(Quiz quiz) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Quiz'),
        content: Text('Are you sure you want to delete "${quiz.name}"? This will also delete all associated questions.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await _hiveService.deleteQuiz(quiz.id);
      _loadQuizzes();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${quiz.name} deleted')),
        );
      }
    }
  }

  Future<void> _navigateToForm([Quiz? quiz]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizFormScreen(
          subject: widget.subject,
          quiz: quiz,
        ),
      ),
    );

    if (result == true) {
      _loadQuizzes();
    }
  }

  void _navigateToQuestions(Quiz quiz) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuestionListScreen(quiz: quiz),
      ),
    );
  }

  void _navigateToSets(Quiz quiz) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizSetListScreen(quiz: quiz),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subject.name),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _quizzes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.quiz_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No quizzes yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to create your first quiz',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _quizzes.length,
              itemBuilder: (context, index) {
                final quiz = _quizzes[index];
                final questionCount = _hiveService.getQuestionsByQuiz(quiz.id).length;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: const Icon(
                        Icons.quiz,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      quiz.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (quiz.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(quiz.description),
                        ],
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.help_outline, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              '$questionCount question${questionCount != 1 ? 's' : ''}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(Icons.timer, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              '${quiz.timerSeconds}s',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (quiz.randomizeQuestions) ...[
                              const SizedBox(width: 12),
                              Icon(Icons.shuffle, size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                'Random Q',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                            if (quiz.randomizeChoices) ...[
                              const SizedBox(width: 12),
                              Icon(Icons.shuffle, size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                'Random C',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton(
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'sets',
                          child: Row(
                            children: [
                              Icon(Icons.folder),
                              SizedBox(width: 8),
                              Text('Manage Sets'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) {
                        if (value == 'sets') {
                          _navigateToSets(quiz);
                        } else if (value == 'edit') {
                          _navigateToForm(quiz);
                        } else if (value == 'delete') {
                          _deleteQuiz(quiz);
                        }
                      },
                    ),
                    onTap: () => _navigateToQuestions(quiz),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
