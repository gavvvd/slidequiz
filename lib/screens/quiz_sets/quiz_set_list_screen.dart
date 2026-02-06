import 'package:flutter/material.dart';
import 'package:slidequiz/models/quiz.dart';
import 'package:slidequiz/models/quiz_set.dart';
import 'package:slidequiz/services/hive_service.dart';
import 'package:slidequiz/screens/quiz/quiz_slideshow_screen.dart';
import 'package:slidequiz/models/question.dart';
import 'package:slidequiz/models/choice.dart';
import 'package:slidequiz/widgets/copyright_footer.dart';

class QuizSetListScreen extends StatefulWidget {
  final Quiz quiz;

  const QuizSetListScreen({super.key, required this.quiz});

  @override
  State<QuizSetListScreen> createState() => _QuizSetListScreenState();
}

class _QuizSetListScreenState extends State<QuizSetListScreen> {
  final HiveService _hiveService = HiveService();
  List<QuizSet> _quizSets = [];

  @override
  void initState() {
    super.initState();
    _loadQuizSets();
  }

  void _loadQuizSets() {
    setState(() {
      _quizSets = _hiveService.getQuizSetsByQuiz(widget.quiz.id);
    });
  }

  Future<void> _generateNewSet() async {
    final nameController = TextEditingController();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generate New Set'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Set Name',
                hintText: 'e.g., Set A, Morning Class',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            Text(
              'This will create a new randomized set based on your quiz settings.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Generate'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final name = nameController.text.trim();
      if (name.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a set name')),
        );
        return;
      }

      final quizSet = _hiveService.generateQuizSet(
        quiz: widget.quiz,
        name: name,
      );
      
      await _hiveService.addQuizSet(quizSet);
      _loadQuizSets();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Generated "$name"')),
        );
      }
    }
  }

  Future<void> _deleteSet(QuizSet quizSet) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Set'),
        content: Text('Are you sure you want to delete "${quizSet.name}"?'),
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
      await _hiveService.deleteQuizSet(quizSet.id);
      _loadQuizSets();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${quizSet.name} deleted')),
        );
      }
    }
  }

  void _startQuizWithSet(QuizSet quizSet) {
    // Load questions in the saved order
    final questions = quizSet.questionOrder
        .map((id) => _hiveService.getQuestion(id))
        .whereType<Question>()
        .toList();

    if (questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No questions found for this set')),
      );
      return;
    }

    // Load choices in the saved order
    final Map<String, List<Choice>> questionChoices = {};
    for (var questionId in quizSet.questionOrder) {
      if (quizSet.choiceOrders.containsKey(questionId)) {
        final choiceIds = quizSet.choiceOrders[questionId]!;
        final choices = choiceIds
            .map((id) => _hiveService.getChoice(id))
            .whereType<Choice>()
            .toList();
        questionChoices[questionId] = choices;
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizSlideshowScreen(
          quiz: widget.quiz,
          questions: questions,
          questionChoices: questionChoices,
          setName: quizSet.name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const CopyrightFooter(),
      appBar: AppBar(
        title: Text('${widget.quiz.name} - Sets'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _quizSets.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.folder_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No sets generated yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to generate your first set',
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
              itemCount: _quizSets.length,
              itemBuilder: (context, index) {
                final quizSet = _quizSets[index];
                final questionCount = quizSet.questionOrder.length;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: Colors.purple,
                      child: const Icon(
                        Icons.folder,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      quizSet.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          '$questionCount question${questionCount != 1 ? 's' : ''}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Created ${_formatDate(quizSet.createdAt)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton(
                      itemBuilder: (context) => [
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
                        if (value == 'delete') {
                          _deleteSet(quizSet);
                        }
                      },
                    ),
                    onTap: () => _startQuizWithSet(quizSet),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _generateNewSet,
        child: const Icon(Icons.add),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }
}
