import 'package:flutter/material.dart';
import 'package:slidequiz/models/subject.dart';
import 'package:slidequiz/services/hive_service.dart';
import 'package:slidequiz/screens/subjects/subject_form_screen.dart';
import 'package:slidequiz/screens/quizzes/quiz_list_screen.dart';
import 'package:intl/intl.dart';

class SubjectGrid extends StatefulWidget {
  const SubjectGrid({super.key});

  @override
  State<SubjectGrid> createState() => _SubjectGridState();
}

class _SubjectGridState extends State<SubjectGrid> {
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
      // Sort by most recent update
      _subjects.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    });
  }

  void _addSubject() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SubjectFormScreen()),
    );
    _loadSubjects();
  }

  void _editSubject(Subject subject) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubjectFormScreen(subject: subject),
      ),
    );
    _loadSubjects();
  }

  void _deleteSubject(Subject subject) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Subject'),
        content: Text('Are you sure you want to delete "${subject.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _confirmDelete(subject.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(String id) async {
    await _hiveService.deleteSubject(id);
    _loadSubjects();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Subjects'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _subjects.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'No subjects yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _addSubject,
                    icon: const Icon(Icons.add),
                    label: const Text('Create Subject'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _subjects.length,
              itemBuilder: (context, index) {
                final subject = _subjects[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: _buildSubjectCard(subject),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addSubject,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSubjectCard(Subject subject) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => QuizListScreen(subject: subject),
            ),
          ).then((_) => _loadSubjects());
        },
        child: SizedBox(
          height: 120,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 100,
                color: Theme.of(context).primaryColor,
                alignment: Alignment.center,
                child: Text(
                  subject.name.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    fontSize: 40,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              subject.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          PopupMenuButton(
                            padding: EdgeInsets.zero,
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('Edit'),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete'),
                              ),
                            ],
                            onSelected: (value) {
                              if (value == 'edit') {
                                _editSubject(subject);
                              } else if (value == 'delete') {
                                _deleteSubject(subject);
                              }
                            },
                            child: const Icon(Icons.more_horiz),
                          ),
                        ],
                      ),
                      if (subject.description.isNotEmpty)
                        Text(
                          subject.description,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const Spacer(),
                      Text(
                        'Updated: ${DateFormat.yMMMd().format(subject.updatedAt)}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
