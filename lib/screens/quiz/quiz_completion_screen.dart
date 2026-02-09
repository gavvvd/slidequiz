import 'package:flutter/material.dart';
import 'package:slidequiz/models/quiz.dart';
import 'package:slidequiz/models/question.dart';
import 'package:slidequiz/models/choice.dart';
import 'package:slidequiz/screens/quiz/answer_key_screen.dart';

class QuizCompletionScreen extends StatelessWidget {
  final Quiz quiz;
  final List<Question> questions;
  final Map<String, List<Choice>>? questionChoices;

  const QuizCompletionScreen({
    super.key,
    required this.quiz,
    required this.questions,
    this.questionChoices,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 100,
              color: Colors.green,
            ),
            const SizedBox(height: 24),
            const Text(
              'ANSWERS',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to Answer Key with ShowQuestions = false
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AnswerKeyScreen(
                      questions: questions,
                      questionChoices: questionChoices,
                      showQuestions: true, // Show questions
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.list_alt),
              label: const Text('View Answer List'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                textStyle: const TextStyle(fontSize: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
