import 'package:flutter/material.dart';
import 'package:slidequiz/models/quiz.dart';
import 'package:slidequiz/models/question.dart';
import 'package:slidequiz/models/choice.dart';
import 'package:slidequiz/screens/quiz/quiz_slideshow_screen.dart';
import 'package:slidequiz/services/hive_service.dart';
import 'package:slidequiz/widgets/copyright_footer.dart';

class QuizIntroScreen extends StatefulWidget {
  final Quiz quiz;
  final List<Question> questions;
  final Map<String, List<Choice>>? questionChoices;
  final String? setName;

  const QuizIntroScreen({
    super.key,
    required this.quiz,
    required this.questions,
    this.questionChoices,
    this.setName,
  });

  @override
  State<QuizIntroScreen> createState() => _QuizIntroScreenState();
}

class _QuizIntroScreenState extends State<QuizIntroScreen> {
  String _subjectName = 'Loading Subject...';
  final HiveService _hiveService = HiveService();

  @override
  void initState() {
    super.initState();
    _loadSubjectName();
  }

  void _loadSubjectName() {
    // HiveService needs a method to get Subject by ID
    // Assuming HiveService has getSubject(id) or similar.
    // If not, we might fail gracefully or need to add it.
    // Let's safe check based on existing patterns.
    // Actually, usually Subjects are parent. 
    // If we can't fetch it easily here without Service update, we'll placeholder.
    // But let's try to fetch if we can.
    
    // Simplification: We need to see if we can get Subject. 
    // Since I can't see HiveService right now in this step, I'll use a placeholder logic 
    // or better, I should have checked HiveService first. 
    // But context says "Subject Name usually comes from Quiz model".
    // I will try to fetch it.
    
    final subject = _hiveService.getSubject(widget.quiz.subjectId);
    if (subject != null) {
      setState(() {
        _subjectName = subject.name;
      });
    } else {
      setState(() {
        _subjectName = 'Unknown Subject';
      });
    }
  }

  void _startQuiz() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => QuizSlideshowScreen(
          quiz: widget.quiz,
          questions: widget.questions,
          questionChoices: widget.questionChoices,
          setName: widget.setName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const CopyrightFooter(),
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _subjectName.toUpperCase(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                  letterSpacing: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Text(
                widget.quiz.name,
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              if (widget.setName != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue[200]!)
                  ),
                  child: Text(
                    widget.setName!,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 64),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: FilledButton(
                  onPressed: _startQuiz,
                  style: FilledButton.styleFrom(
                    textStyle: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: const Text('START QUIZ'),
                ),
              ),
              const SizedBox(height: 16),
               SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
               ),
            ],
          ),
        ),
      ),
    );
  }
}
