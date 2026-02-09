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
        content: Text(
          'Are you sure you want to delete "${quiz.name}"? This will also delete all associated questions.',
        ),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${quiz.name} deleted')));
      }
    }
  }

  Future<void> _navigateToForm([Quiz? quiz]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            QuizFormScreen(subject: widget.subject, quiz: quiz),
      ),
    );

    if (result == true) {
      _loadQuizzes();
    }
  }

  void _navigateToQuestions(Quiz quiz) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => QuestionListScreen(quiz: quiz)),
    );
  }

  void _navigateToSets(Quiz quiz) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => QuizSetListScreen(quiz: quiz)),
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
                  Icon(Icons.quiz_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No quizzes yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to create your first quiz',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _quizzes.length,
              itemBuilder: (context, index) {
                final quiz = _quizzes[index];
                final questionCount = _hiveService
                    .getQuestionsByQuiz(quiz.id)
                    .length;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => _navigateToQuestions(quiz),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              child: const Icon(
                                Icons.quiz,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              quiz.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            trailing: PopupMenuButton(
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Edit'),
                                ),
                                const PopupMenuItem(
                                  value: 'questions',
                                  child: Text('Questions'),
                                ),
                                const PopupMenuItem(
                                  value: 'sets',
                                  child: Text('Saved Sets'),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Delete'),
                                ),
                              ],
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _editQuiz(quiz);
                                } else if (value == 'questions') {
                                  _navigateToQuestions(quiz);
                                } else if (value == 'sets') {
                                  _navigateToSets(quiz);
                                } else if (value == 'delete') {
                                  _deleteQuiz(quiz);
                                }
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 16,
                              right: 16,
                              bottom: 16,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  quiz.description.isNotEmpty
                                      ? quiz.description
                                      : 'No description',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontStyle: quiz.description.isEmpty
                                        ? FontStyle.italic
                                        : FontStyle.normal,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.help_outline,
                                      size: 16,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$questionCount Qs',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Icon(
                                      Icons.timer,
                                      size: 16,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${quiz.timerSeconds}s',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToForm,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _editQuiz(Quiz quiz) {
    _navigateToForm(quiz);
  }
}
