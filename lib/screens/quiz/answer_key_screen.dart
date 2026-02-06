import 'package:flutter/material.dart';
import 'package:slidequiz/models/question.dart';
import 'package:slidequiz/models/choice.dart';
import 'package:slidequiz/widgets/copyright_footer.dart';

class AnswerKeyScreen extends StatelessWidget {
  final List<Question> questions;
  final bool showQuestions;
  final Map<String, List<Choice>>? questionChoices;

  const AnswerKeyScreen({
    super.key,
    required this.questions,
    this.questionChoices,
    this.showQuestions = true,
  });

  @override
  Widget build(BuildContext context) {
    // Dynamic sizing for TV
    double screenHeight = MediaQuery.of(context).size.height;
    double questionFontSize = screenHeight * 0.04;
    double choiceFontSize = screenHeight * 0.03;
    double answerFontSize = screenHeight * 0.035;
    double metaFontSize = screenHeight * 0.025;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenHeight * 0.02,
                vertical: screenHeight * 0.02,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Answer Key',
                    style: TextStyle(
                      fontSize: screenHeight * 0.04,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.check),
                    label: const Text('Done'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: screenHeight * 0.02),
                itemCount: questions.length,
                itemBuilder: (context, index) {
                  final question = questions[index];
                  final choices = questionChoices?[question.id] ?? [];
                  final labels = ['A', 'B', 'C', 'D', 'E', 'F'];

                  return Card(
                    margin: EdgeInsets.only(bottom: screenHeight * 0.02),
                    elevation: 4,
                    child: Padding(
                      padding: EdgeInsets.all(screenHeight * 0.025),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Question number and type
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Text(
                                  'Question ${index + 1}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: metaFontSize,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: _getTypeColor(question.type).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Text(
                                  question.type,
                                  style: TextStyle(
                                    color: _getTypeColor(question.type),
                                    fontSize: metaFontSize,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Row(
                                children: [
                                  Icon(Icons.star, size: metaFontSize * 1.5, color: Colors.amber[700]),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${question.points} pt${question.points != 1 ? 's' : ''}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: metaFontSize,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: screenHeight * 0.02),

                          // Question text
                          if (showQuestions) ...[
                            Text(
                              question.questionText,
                              style: TextStyle(
                                fontSize: questionFontSize,
                                fontWeight: FontWeight.w600,
                                height: 1.3,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.02),
                          ],

                          // Choices for multiple choice
                          if (question.type == Question.typeMultipleChoice && choices.isNotEmpty) ...[
                            Text(
                              'Choices:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                                fontSize: choiceFontSize,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.01),
                            ...choices.asMap().entries.map((entry) {
                              final choiceIndex = entry.key;
                              final choice = entry.value;
                              final displayLabel = labels[choiceIndex];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  '$displayLabel. ${choice.text}',
                                  style: TextStyle(
                                    fontSize: choiceFontSize,
                                    color: Colors.black87,
                                  ),
                                ),
                              );
                            }),
                            SizedBox(height: screenHeight * 0.02),
                          ],

                          // Answer
                          Container(
                            padding: EdgeInsets.all(screenHeight * 0.02),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green, width: 2),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: answerFontSize * 1.5,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Answer: ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                    fontSize: answerFontSize,
                                  ),
                                ),
                                Expanded(
                                  child: Builder(
                                    builder: (context) {
                                      String displayText = question.answer;
                                      
                                      if (question.type == Question.typeMultipleChoice && choices.isNotEmpty) {
                                        // Try to match answer with a choice to get the letter
                                        int index = choices.indexWhere((c) => c.text.trim() == question.answer.trim());
                                        if (index != -1 && index < labels.length) {
                                          displayText = '${labels[index]}. ${question.answer}';
                                        }
                                      }
                                      
                                      return Text(
                                        displayText,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: answerFontSize,
                                          color: Colors.black,
                                        ),
                                      );
                                    }
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const CopyrightFooter(),
          ],
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
}
