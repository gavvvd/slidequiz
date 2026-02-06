import 'package:flutter/material.dart';
import 'package:slidequiz/models/subject.dart';
import 'package:slidequiz/services/hive_service.dart';
import 'package:slidequiz/screens/subjects/subject_form_screen.dart';
import 'package:slidequiz/screens/quizzes/quiz_list_screen.dart';
import 'package:slidequiz/widgets/copyright_footer.dart';

class SubjectListScreen extends StatefulWidget {
  const SubjectListScreen({super.key});

  @override
  State<SubjectListScreen> createState() => _SubjectListScreenState();
}

class _SubjectListScreenState extends State<SubjectListScreen> {
  final HiveService _hiveService = HiveService();
  List<Subject> _subjects = [];

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  void _loadSubjects() {
    setState(() {
      _subjects = _hiveService.getAllSubjects();
    });
  }

  Future<void> _deleteSubject(Subject subject) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Subject'),
        content: Text('Are you sure you want to delete "${subject.name}"? This will also delete all associated quizzes and questions.'),
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
      await _hiveService.deleteSubject(subject.id);
      _loadSubjects();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${subject.name} deleted')),
        );
      }
    }
  }

  Future<void> _navigateToForm([Subject? subject]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubjectFormScreen(subject: subject),
      ),
    );

    if (result == true) {
      _loadSubjects();
    }
  }

  void _navigateToQuizzes(Subject subject) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizListScreen(subject: subject),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const CopyrightFooter(),
      appBar: AppBar(
        title: const Text('Subjects'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _subjects.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.school_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No subjects yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to add your first subject',
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
              itemCount: _subjects.length,
              itemBuilder: (context, index) {
                final subject = _subjects[index];
                final quizCount = _hiveService.getQuizzesBySubject(subject.id).length;

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
                        Icons.school,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      subject.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (subject.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(subject.description),
                        ],
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.quiz, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              '$quizCount quiz${quizCount != 1 ? 'zes' : ''}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
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
                              Text('Delete', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) {
                        if (value == 'edit') {
                          _navigateToForm(subject);
                        } else if (value == 'delete') {
                          _deleteSubject(subject);
                        }
                      },
                    ),
                    onTap: () => _navigateToQuizzes(subject),
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
