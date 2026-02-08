import 'package:flutter/material.dart';
import 'package:slidequiz/models/quiz.dart';
import 'package:slidequiz/models/question.dart';
import 'package:slidequiz/models/choice.dart';
import 'package:slidequiz/services/hive_service.dart';
import 'package:slidequiz/widgets/copyright_footer.dart';

class QuestionFormScreen extends StatefulWidget {
  final Quiz quiz;
  final Question? question;

  const QuestionFormScreen({super.key, required this.quiz, this.question});

  @override
  State<QuestionFormScreen> createState() => _QuestionFormScreenState();
}

class _QuestionFormScreenState extends State<QuestionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final _pointsController = TextEditingController(text: '1');
  final _timerController = TextEditingController();
  final HiveService _hiveService = HiveService();

  String _selectedType = Question.typeMultipleChoice;

  // Type specific state
  List<TextEditingController> _choiceControllers = [];
  List<String> _choiceLabels = ['A', 'B', 'C', 'D'];
  int? _correctChoiceIndex; // Checkbox selection for MC

  bool? _isTrueSelected; // For True/False (true=True, false=False)

  List<TextEditingController> _answerListControllers = []; // For Id/Enum
  bool _isOrdered = false; // For Enumeration

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.question != null) {
      final q = widget.question!;
      _questionController.text = q.questionText;
      _pointsController.text = q.points.toString();
      _timerController.text = q.timerSeconds?.toString() ?? '';
      _selectedType = q.type;

      if (_selectedType == Question.typeMultipleChoice) {
        final choices = _hiveService.getChoicesByQuestion(q.id);
        _choiceLabels = choices.map((c) => c.label).toList();
        _choiceControllers = choices
            .map((c) => TextEditingController(text: c.text))
            .toList();

        // Find which choice is correct based on answer
        // Note: answer used to store the Label or Text. Assuming Label for now or Text.
        // Let's matching against text first, then label.
        // Or if answer is "A", check index.
        try {
          final correctIndex = choices.indexWhere(
            (c) => c.text == q.answer || c.label == q.answer,
          );
          if (correctIndex != -1) {
            _correctChoiceIndex = correctIndex;
          }
        } catch (_) {}
      } else if (_selectedType == Question.typeTrueFalse) {
        if (q.answer.toLowerCase() == 'true') _isTrueSelected = true;
        if (q.answer.toLowerCase() == 'false') _isTrueSelected = false;
      } else if (_selectedType == Question.typeIdentification) {
        if (q.acceptedAnswers != null && q.acceptedAnswers!.isNotEmpty) {
          _answerListControllers = q.acceptedAnswers!
              .map((a) => TextEditingController(text: a))
              .toList();
        } else {
          _answerListControllers = [TextEditingController(text: q.answer)];
        }
      } else if (_selectedType == Question.typeEnumeration) {
        _isOrdered = q.isOrdered;
        if (q.acceptedAnswers != null && q.acceptedAnswers!.isNotEmpty) {
          _answerListControllers = q.acceptedAnswers!
              .map((a) => TextEditingController(text: a))
              .toList();
        } else {
          // Fallback if no acceptedAnswers but answer field has something
          _answerListControllers = q.answer
              .split(',')
              .map((a) => TextEditingController(text: a.trim()))
              .toList();
        }
      }
    } else {
      // Defaults for new questions
      _initTypeDefaults();
    }
  }

  void _initTypeDefaults() {
    if (_selectedType == Question.typeMultipleChoice) {
      _choiceControllers = List.generate(4, (_) => TextEditingController());
      _choiceLabels = ['A', 'B', 'C', 'D'];
      _correctChoiceIndex = null;
    } else if (_selectedType == Question.typeIdentification) {
      _answerListControllers = [TextEditingController()];
    } else if (_selectedType == Question.typeEnumeration) {
      _answerListControllers = List.generate(
        2,
        (_) => TextEditingController(),
      ); // Min 2
      _isOrdered = false;
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    _pointsController.dispose();
    _timerController.dispose();
    for (var c in _choiceControllers) {
      c.dispose();
    }
    for (var c in _answerListControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _updateType(String? newType) {
    if (newType == null) return;
    setState(() {
      _selectedType = newType;
      // Reset relevant controllers if switching types completely
      // Ideally keeping question text/points, but resetting answer inputs
      _choiceControllers.clear();
      _answerListControllers.clear();
      _correctChoiceIndex = null;
      _isTrueSelected = null;
      _initTypeDefaults();
    });
  }

  // --- Dynamic List Logic ---
  void _addChoice() {
    if (_choiceControllers.length < 6) {
      setState(() {
        final labels = ['A', 'B', 'C', 'D', 'E', 'F'];
        _choiceLabels.add(labels[_choiceControllers.length]);
        _choiceControllers.add(TextEditingController());
      });
    }
  }

  void _removeChoice(int index) {
    if (_choiceControllers.length > 2) {
      setState(() {
        _choiceControllers[index].dispose();
        _choiceControllers.removeAt(index);
        _choiceLabels.removeAt(index);
        if (_correctChoiceIndex == index) {
          _correctChoiceIndex = null;
        } else if (_correctChoiceIndex != null && _correctChoiceIndex! > index)
          _correctChoiceIndex = _correctChoiceIndex! - 1;

        final labels = ['A', 'B', 'C', 'D', 'E', 'F'];
        _choiceLabels = labels.sublist(0, _choiceControllers.length);
      });
    }
  }

  void _addAnswerInput() {
    setState(() {
      _answerListControllers.add(TextEditingController());
    });
  }

  void _removeAnswerInput(int index) {
    int min = _selectedType == Question.typeEnumeration ? 2 : 1;
    if (_answerListControllers.length > min) {
      setState(() {
        _answerListControllers[index].dispose();
        _answerListControllers.removeAt(index);
      });
    }
  }

  Future<void> _saveQuestion() async {
    if (!_formKey.currentState!.validate()) return;

    // Custom Validation
    String answer = '';
    List<String>? acceptedAnswers;

    if (_selectedType == Question.typeMultipleChoice) {
      final filled = _choiceControllers
          .where((c) => c.text.trim().isNotEmpty)
          .length;
      if (filled < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Multiple choice must have at least 2 valid options'),
          ),
        );
        return;
      }
      if (_correctChoiceIndex == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select the correct answer (check a box)'),
          ),
        );
        return;
      }
      if (_choiceControllers[_correctChoiceIndex!].text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selected answer cannot be empty')),
        );
        return;
      }
      // Answer is the TEXT of the selected choice (or label? using Text for robustness if shuffled)
      // Actually standardizing: use the TEXT for the answer matching logic usually, but here
      // choices are objects. If we shuffle, using Label 'A' is dangerous if 'A' content changes.
      // Let's store the Text of the correct choice.
      answer = _choiceControllers[_correctChoiceIndex!].text.trim();
    } else if (_selectedType == Question.typeTrueFalse) {
      if (_isTrueSelected == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select True or False')),
        );
        return;
      }
      answer = _isTrueSelected! ? 'True' : 'False';
    } else if (_selectedType == Question.typeIdentification) {
      // Filter empty
      acceptedAnswers = _answerListControllers
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .toList();
      if (acceptedAnswers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one valid answer')),
        );
        return;
      }
      answer = acceptedAnswers.first; // Primary answer
    } else if (_selectedType == Question.typeEnumeration) {
      acceptedAnswers = _answerListControllers
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .toList();
      if (acceptedAnswers.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enumeration must have at least 2 answers'),
          ),
        );
        return;
      }
      answer = acceptedAnswers.join(', '); // Comma separated for legacy/display
    }

    final int points = int.parse(_pointsController.text);
    final int? timer = _timerController.text.isNotEmpty
        ? int.parse(_timerController.text)
        : null;

    final question =
        widget.question ??
        Question(
          quizId: widget.quiz.id,
          type: _selectedType,
          questionText: _questionController.text.trim(),
          answer: answer,
        );

    // Update fields
    question.type = _selectedType;
    question.questionText = _questionController.text.trim();
    question.answer = answer; // Main answer string
    question.points = points;
    question.timerSeconds = timer;
    question.acceptedAnswers = acceptedAnswers;
    question.isOrdered = _isOrdered;

    if (widget.question != null) {
      await _hiveService.updateQuestion(question);
      await _hiveService.deleteAllChoicesByQuestion(question.id);
    } else {
      await _hiveService.addQuestion(question);
    }

    // Save Choices
    if (_selectedType == Question.typeMultipleChoice) {
      final newChoices = <Choice>[];
      for (int i = 0; i < _choiceControllers.length; i++) {
        if (_choiceControllers[i].text.trim().isNotEmpty) {
          newChoices.add(
            Choice(
              questionId: question.id,
              label: _choiceLabels[i],
              text: _choiceControllers[i].text.trim(),
              order: i,
            ),
          );
        }
      }
      await _hiveService.addChoices(newChoices);
    }

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.question != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Question' : 'Add Question'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Type dropdown
            DropdownButtonFormField<String>(
              initialValue: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Question Type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Multiple Choice',
                  child: Text('Multiple Choice'),
                ),
                DropdownMenuItem(
                  value: 'Identification',
                  child: Text('Identification'),
                ),
                DropdownMenuItem(
                  value: 'True or False',
                  child: Text('True or False'),
                ),
                DropdownMenuItem(
                  value: 'Enumeration',
                  child: Text('Enumeration'),
                ),
              ],
              onChanged: _updateType,
            ),
            const SizedBox(height: 16),

            // Question Text
            TextFormField(
              controller: _questionController,
              decoration: const InputDecoration(
                labelText: 'Question',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.help_outline),
              ),
              maxLines: 3,
              validator: (val) =>
                  val == null || val.trim().isEmpty ? 'Enter a question' : null,
            ),
            const SizedBox(height: 24),

            // DYNAMIC CONTENT BASED ON TYPE
            if (_selectedType == Question.typeMultipleChoice)
              _buildMultipleChoiceUI(),
            if (_selectedType == Question.typeTrueFalse) _buildTrueFalseUI(),
            if (_selectedType == Question.typeIdentification)
              _buildIdentificationUI(),
            if (_selectedType == Question.typeEnumeration)
              _buildEnumerationUI(),

            const SizedBox(height: 24),

            // Settings (Points, Timer)
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _pointsController,
                    decoration: const InputDecoration(
                      labelText: 'Points',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                        (v == null ||
                            int.tryParse(v) == null ||
                            int.parse(v) < 1)
                        ? 'Min 1'
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _timerController,
                    decoration: const InputDecoration(
                      labelText: 'Timer (sec)',
                      border: OutlineInputBorder(),
                      hintText: 'Optional',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            ElevatedButton.icon(
              onPressed: _saveQuestion,
              icon: const Icon(Icons.save),
              label: const Text('Save Question'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
            const CopyrightFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildMultipleChoiceUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Answer Choices (Select correct answer)',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ..._choiceControllers.asMap().entries.map((entry) {
          final index = entry.key;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Checkbox(
                  value: _correctChoiceIndex == index,
                  onChanged: (val) {
                    setState(
                      () => _correctChoiceIndex = (val == true) ? index : null,
                    );
                  },
                ),
                Expanded(
                  child: TextFormField(
                    controller: entry.value,
                    decoration: InputDecoration(
                      labelText: 'Option ${_choiceLabels[index]}',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                if (_choiceControllers.length > 2)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeChoice(index),
                  ),
              ],
            ),
          );
        }),
        if (_choiceControllers.length < 6)
          TextButton.icon(
            onPressed: _addChoice,
            icon: const Icon(Icons.add),
            label: const Text('Add Option'),
          ),
      ],
    );
  }

  Widget _buildTrueFalseUI() {
    return Column(
      children: [
        const Text(
          'Correct Answer:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            InkWell(
              onTap: () => setState(() => _isTrueSelected = true),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: _isTrueSelected == true
                      ? Colors.green[100]
                      : Colors.grey[100],
                  border: Border.all(
                    color: _isTrueSelected == true ? Colors.green : Colors.grey,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Radio<bool?>(
                      value: true,
                      groupValue: _isTrueSelected,
                      onChanged: (v) => setState(() => _isTrueSelected = v),
                    ),
                    const Text(
                      'True',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            InkWell(
              onTap: () => setState(() => _isTrueSelected = false),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: _isTrueSelected == false
                      ? Colors.red[100]
                      : Colors.grey[100],
                  border: Border.all(
                    color: _isTrueSelected == false ? Colors.red : Colors.grey,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Radio<bool?>(
                      value: false,
                      groupValue: _isTrueSelected,
                      onChanged: (v) => setState(() => _isTrueSelected = v),
                    ),
                    const Text(
                      'False',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIdentificationUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Accepted Answers (Min 1)',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ..._answerListControllers.asMap().entries.map((entry) {
          final index = entry.key;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: entry.value,
                    decoration: InputDecoration(
                      labelText: 'Answer ${index + 1}',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                if (_answerListControllers.length > 1)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeAnswerInput(index),
                  ),
              ],
            ),
          );
        }),
        TextButton.icon(
          onPressed: _addAnswerInput,
          icon: const Icon(Icons.add),
          label: const Text('Add Alternative Answer'),
        ),
      ],
    );
  }

  Widget _buildEnumerationUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Answers (Min 2)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                const Text('In Order?'),
                Switch(
                  value: _isOrdered,
                  onChanged: (v) => setState(() => _isOrdered = v),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._answerListControllers.asMap().entries.map((entry) {
          final index = entry.key;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    '${index + 1}.',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: TextFormField(
                    controller: entry.value,
                    decoration: InputDecoration(
                      labelText: 'Item ${index + 1}',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                if (_answerListControllers.length > 2)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeAnswerInput(index),
                  ),
              ],
            ),
          );
        }),
        TextButton.icon(
          onPressed: _addAnswerInput,
          icon: const Icon(Icons.add),
          label: const Text('Add Answer'),
        ),
      ],
    );
  }
}
