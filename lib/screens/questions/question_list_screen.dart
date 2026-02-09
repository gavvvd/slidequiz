import 'package:flutter/material.dart';
import 'package:slidequiz/models/quiz.dart';
import 'package:slidequiz/models/question.dart';
import 'package:slidequiz/services/hive_service.dart';
import 'package:slidequiz/screens/questions/question_form_screen.dart';
import 'package:slidequiz/models/quiz_set.dart';
import 'package:slidequiz/screens/quiz/quiz_intro_screen.dart';
import 'package:uuid/uuid.dart';
import 'package:slidequiz/widgets/copyright_footer.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:slidequiz/services/csv_import_service.dart';

class QuestionListScreen extends StatefulWidget {
  final Quiz quiz;

  const QuestionListScreen({super.key, required this.quiz});

  @override
  State<QuestionListScreen> createState() => _QuestionListScreenState();
}

class _QuestionListScreenState extends State<QuestionListScreen> {
  final HiveService _hiveService = HiveService();
  List<Question> _questions = [];

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  void _loadQuestions() {
    setState(() {
      _questions = _hiveService.getQuestionsByQuiz(widget.quiz.id);
    });
  }

  Future<void> _deleteQuestion(Question question) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Question'),
        content: const Text('Are you sure you want to delete this question?'),
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
      await _hiveService.deleteQuestion(question.id);
      _loadQuestions();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Question deleted')));
      }
    }
  }

  Future<void> _navigateToForm([Question? question]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            QuestionFormScreen(quiz: widget.quiz, question: question),
      ),
    );

    if (result == true) {
      _loadQuestions();
    }
  }

  Future<void> _startQuiz() async {
    if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add questions before starting quiz')),
      );
      return;
    }

    await _showStartDialog();
  }

  Future<void> _showStartDialog() async {
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final sets = _hiveService.getQuizSetsByQuiz(widget.quiz.id);
            return AlertDialog(
              title: const Text('Start Quiz'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.add_circle, color: Colors.blue),
                      title: const Text(
                        'Generate New Set',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      subtitle: const Text('Create a new randomized order'),
                      onTap: () async {
                        Navigator.pop(context);
                        await _handleGenerateNewSet();
                      },
                    ),
                    if (sets.isNotEmpty) ...[
                      const Divider(),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Saved Sets:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      ...sets.map(
                        (set) => ListTile(
                          leading: const Icon(Icons.folder_outlined),
                          title: Text(set.name),
                          subtitle: Text(
                            '${set.questionOrder.length} Questions',
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            _launchQuizWithSet(set);
                          },
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete Set'),
                                  content: Text('Delete set "${set.name}"?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text(
                                        'Delete',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                await _hiveService.deleteQuizSet(set.id);
                                setStateDialog(() {});
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _handleGenerateNewSet() async {
    final nameController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Name Your Set'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Set Name',
            hintText: 'e.g., Class A - Set 1',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, nameController.text.trim()),
            child: const Text('Generate & Start'),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty) {
      final newSet = await _generateAndSaveSet(name);
      _launchQuizWithSet(newSet);
    }
  }

  Future<QuizSet> _generateAndSaveSet(String name) async {
    // 1. Randomize Questions
    final questions = List<Question>.from(_questions);
    if (widget.quiz.randomizeQuestions) {
      questions.shuffle();
    }

    // 2. Randomize Choices
    final choiceOrders = <String, List<String>>{};

    for (var question in questions) {
      if (question.type == Question.typeMultipleChoice ||
          question.type == Question.typeIdentification) {
        // Identify also has choices in this app? Check model.
        // Assuming choices are relevant to be stored for consistency
        final choices = _hiveService.getChoicesByQuestion(question.id);
        if (widget.quiz.randomizeChoices) {
          choices.shuffle();
        }
        choiceOrders[question.id] = choices.map((c) => c.id).toList();
      }
    }

    // 3. Create QuizSet
    final setId = const Uuid().v4();
    final set = QuizSet(
      id: setId,
      quizId: widget.quiz.id,
      name: name,
      questionOrder: questions.map((q) => q.id).toList(),
      choiceOrders: choiceOrders,
      createdAt: DateTime.now(),
    );

    // 4. Save
    await _hiveService.addQuizSet(set);
    return set;
  }

  Future<void> _downloadTemplate() async {
    const csvHeader =
        '"TYPE","QUESTION","CHOICE_A","CHOICE_B","CHOICE_C","CHOICE_D","CHOICE_E","CHOICE_F","ANSWER","TIMER"\n'
        '"Multiple Choice","Example Question","Option A","Option B","Option C","Option D","Option E","Option F","Option A <Must be in the answer field>","30 <in seconds>"\n'
        '"Identification","Example Question","<required if multiple choice>","<required if multiple choice>","","","","","","30 <in seconds remove if you will use the quiz timer as default time>"\n'
        '"True or False","Example Question","<required if multiple choice>","<required if multiple choice>","","","","","","30 <in seconds remove if you will use the quiz timer as default time>"\n';
    try {
      final String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save CSV Template',
        fileName: 'quiz_template.csv',
        allowedExtensions: ['csv'],
        type: FileType.custom,
      );

      if (outputFile != null) {
        final file = File(outputFile);
        await file.writeAsString(csvHeader);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Template saved to $outputFile')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving template: $e')));
      }
    }
  }

  Future<void> _importQuestions() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null) {
        final file = File(result.files.single.path!);
        final csvString = await file.readAsString();

        final importService = CsvImportService();
        final importResult = await importService.importQuestions(
          csvString,
          widget.quiz.id,
        );

        if (importResult.hasErrors) {
          if (mounted) {
            _showErrorDialog(importResult.errors);
          }
        } else {
          int count = 0;
          for (var q in importResult.questions) {
            await _hiveService.addQuestion(q);
            count++;
          }

          // Add choices
          for (var c in importResult.choices) {
            await _hiveService.addChoice(c);
          }

          _loadQuestions();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Successfully imported $count questions')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error importing CSV: $e')));
      }
    }
  }

  void _showErrorDialog(List<String> errors) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Errors'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: errors.length,
            itemBuilder: (context, index) => ListTile(
              leading: const Icon(Icons.error, color: Colors.red),
              title: Text(errors[index]),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _launchQuizWithSet(QuizSet quizSet) {
    final questions = quizSet.questionOrder
        .map((id) => _hiveService.getQuestion(id))
        .whereType<Question>()
        .toList();

    final Map<String, List<dynamic>> questionChoices = {};
    for (var questionId in quizSet.questionOrder) {
      if (quizSet.choiceOrders.containsKey(questionId)) {
        final choiceIds = quizSet.choiceOrders[questionId]!;
        final choices = choiceIds
            .map((id) => _hiveService.getChoice(id))
            .whereType<dynamic>()
            .toList();
        questionChoices[questionId] = choices;
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizIntroScreen(
          quiz: widget.quiz,
          questions: questions,
          questionChoices: questionChoices.map((k, v) => MapEntry(k, v.cast())),
          setName: quizSet.name,
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'Multiple Choice':
        return Colors.blue;
      case 'Identification':
        return Colors.green;
      case 'True or False':
        return Colors.orange;
      case 'Enumeration':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quiz.name),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'import') {
                _importQuestions();
              } else if (value == 'template') {
                _downloadTemplate();
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  value: 'import',
                  child: Row(
                    children: [
                      Icon(Icons.upload_file),
                      SizedBox(width: 8),
                      Text('Import CSV'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'template',
                  child: Row(
                    children: [
                      Icon(Icons.download),
                      SizedBox(width: 8),
                      Text('Download Template'),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: _questions.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.help_outline, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No questions yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to add your first question',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _questions.length,
              itemBuilder: (context, index) {
                final question = _questions[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: _getTypeColor(question.type),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      question.questionText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getTypeColor(
                                question.type,
                              ).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              question.type,
                              style: TextStyle(
                                fontSize: 11,
                                color: _getTypeColor(question.type),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.star, size: 14, color: Colors.amber[700]),
                          const SizedBox(width: 4),
                          Text(
                            '${question.points} pt${question.points != 1 ? 's' : ''}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          if (question.timerSeconds != null) ...[
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.timer,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${question.timerSeconds}s',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ],
                      ),
                    ),
                    trailing: PopupMenuButton(
                      itemBuilder: (context) => [
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
                              Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) {
                        if (value == 'edit') {
                          _navigateToForm(question);
                        } else if (value == 'delete') {
                          _deleteQuestion(question);
                        }
                      },
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: const CopyrightFooter(),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_questions.isNotEmpty) ...[
            FloatingActionButton(
              heroTag: 'start_quiz',
              onPressed: _startQuiz,
              child: const Icon(Icons.play_arrow),
            ),
            const SizedBox(height: 12),
          ],
          FloatingActionButton(
            heroTag: 'add_question',
            onPressed: () => _navigateToForm(),
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
