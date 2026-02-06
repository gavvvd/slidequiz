import 'dart:async';
import 'package:flutter/material.dart';
import 'package:slidequiz/models/quiz.dart';
import 'package:slidequiz/models/question.dart';
import 'package:slidequiz/models/choice.dart';
import 'package:slidequiz/screens/quiz/answer_key_screen.dart';
import 'package:slidequiz/services/hive_service.dart';
import 'package:slidequiz/screens/quiz/quiz_completion_screen.dart';
import 'package:slidequiz/widgets/copyright_footer.dart';

class QuizSlideshowScreen extends StatefulWidget {
  final Quiz quiz;
  final List<Question> questions;
  final Map<String, List<Choice>>? questionChoices; 
  final String? setName; 

  const QuizSlideshowScreen({
    super.key,
    required this.quiz,
    required this.questions,
    this.questionChoices,
    this.setName,
  });

  @override
  State<QuizSlideshowScreen> createState() => _QuizSlideshowScreenState();
}

class _QuizSlideshowScreenState extends State<QuizSlideshowScreen> {
  final HiveService _hiveService = HiveService();
  late List<Question> _questions;
  late Map<String, List<Choice>> _questionChoices;
  int _currentIndex = 0;
  Timer? _timer;
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _initializeQuiz();
  }

  void _initializeQuiz() {
    _questions = List.from(widget.questions);
    
    if (widget.questionChoices != null) {
      _questionChoices = widget.questionChoices!;
    } else {
      _questionChoices = {};

      if (widget.quiz.randomizeQuestions) {
        _questions.shuffle();
      }

      for (var question in _questions) {
        if (question.type == Question.typeMultipleChoice ||
            question.type == Question.typeIdentification) {
          var choices = _hiveService.getChoicesByQuestion(question.id);
          
          if (widget.quiz.randomizeChoices) {
            choices.shuffle();
          }
          
          _questionChoices[question.id] = choices;
        }
      }
    }

    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    final question = _questions[_currentIndex];
    _remainingSeconds = question.timerSeconds ?? widget.quiz.timerSeconds;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        timer.cancel();
        if (_currentIndex < _questions.length - 1) {
          _nextQuestion();
        } else {
          _finishQuiz();
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _previousQuestion() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _startTimer();
      });
    }
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _startTimer();
      });
    }
  }



  void _finishQuiz() {
    _timer?.cancel();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => QuizCompletionScreen(
          questions: widget.questions,
          questionChoices: widget.questionChoices,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic sizing helper
    double screenHeight = MediaQuery.of(context).size.height;
    double questionFontSize = screenHeight * 0.05; // 5% of screen height
    double choiceFontSize = screenHeight * 0.035; // 3.5% of screen height
    double numberFontSize = screenHeight * 0.03; // 3% of screen height
    
    // Define the current question for use in the UI
    final question = _questions[_currentIndex];

    return Scaffold(
      bottomNavigationBar: const CopyrightFooter(),
      appBar: AppBar(
        title: Text(widget.setName != null 
            ? '${widget.quiz.name} - ${widget.setName}'
            : '${widget.quiz.name} Quiz'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.visibility),
            tooltip: 'Answer Key',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AnswerKeyScreen(
                    questions: _questions,
                    questionChoices: _questionChoices,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Timer
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(screenHeight * 0.02),
            color: _remainingSeconds <= 10 ? Colors.red[100] : Colors.blue[50],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.timer,
                  color: _remainingSeconds <= 10 ? Colors.red : Colors.blue,
                  size: screenHeight * 0.04,
                ),
                const SizedBox(width: 8),
                Text(
                  _formatTime(_remainingSeconds),
                  style: TextStyle(
                    fontSize: screenHeight * 0.04,
                    fontWeight: FontWeight.bold,
                    color: _remainingSeconds <= 10 ? Colors.red : Colors.blue,
                  ),
                ),
              ],
            ),
          ),

          // Main Content Area (Question + Choices)
          Expanded(
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(screenHeight * 0.03),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   // Header Row: Question Number + Type Badge
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       Text(
                         'Question ${_currentIndex + 1} of ${_questions.length}',
                         style: TextStyle(
                           fontSize: numberFontSize,
                           fontWeight: FontWeight.bold,
                           color: Colors.grey[700],
                         ),
                       ),
                       Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _getTypeColor(question.type),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          question.type,
                          style: TextStyle(
                            color: Colors.white, 
                            fontWeight: FontWeight.bold, 
                            fontSize: numberFontSize * 0.6,
                          ),
                        ),
                      ),
                     ],
                   ),
                   SizedBox(height: screenHeight * 0.02),

                   // Question Text Container - Consumes remaining space
                   Expanded(
                     child: Container(
                       alignment: Alignment.center, // Center text vertically
                       decoration: BoxDecoration(
                         color: Colors.grey[50], // Subtle background to show container
                         borderRadius: BorderRadius.circular(16),
                       ),
                       padding: EdgeInsets.all(screenHeight * 0.02),
                       child: SingleChildScrollView( 
                         child: Text(
                           question.questionText,
                           textAlign: TextAlign.center,
                           style: TextStyle(
                             fontSize: questionFontSize, 
                             fontWeight: FontWeight.bold,
                             height: 1.3,
                             color: Colors.black,
                           ),
                         ),
                       ),
                     ),
                   ),
                   SizedBox(height: screenHeight * 0.03),

                   // Choices Area
                   _buildAnswerDisplay(question, choiceFontSize),
                ],
              ),
            ),
          ),
          
          // Navigation buttons ...


          // Navigation buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                if (_currentIndex > 0)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _previousQuestion,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Previous'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                if (_currentIndex > 0) const SizedBox(width: 16),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _currentIndex < _questions.length - 1
                        ? _nextQuestion
                        : _finishQuiz,
                    icon: Icon(
                      _currentIndex < _questions.length - 1
                          ? Icons.arrow_forward
                          : Icons.check,
                    ),
                    label: Text(
                      _currentIndex < _questions.length - 1
                          ? 'Next'
                          : 'Finish',
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerDisplay(Question question, double fontSize) {
    // Return widget that fits in the layout below question
    switch (question.type) {
      case 'Multiple Choice':
        return _buildMultipleChoiceDisplay(question, fontSize);
      case 'True or False':
        return _buildTrueFalseDisplay(fontSize);
      case 'Identification':
        return _buildIdentificationDisplay(question);
      case 'Enumeration':
        return _buildEnumerationDisplay(fontSize);
      default:
        return const SizedBox();
    }
  }

  Widget _buildMultipleChoiceDisplay(Question question, double fontSize) {
    final choices = _questionChoices[question.id] ?? [];
    final labels = ['A', 'B', 'C', 'D', 'E', 'F'];

    // 2-Column Grid
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, 
        childAspectRatio: 2.5, 
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: choices.length,
      itemBuilder: (context, index) {
        final choice = choices[index];
        final displayLabel = labels[index];
        
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: fontSize * 3, // Proportional width for letter box
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  displayLabel,
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: fontSize * 1.5,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    choice.text,
                    style: TextStyle(
                      fontSize: fontSize, 
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTrueFalseDisplay(double fontSize) {
    return SizedBox(
      height: fontSize * 6, // Scale height relative to font
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.green[50],
                border: Border.all(color: Colors.green),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text('True', style: TextStyle(fontSize: fontSize * 2, fontWeight: FontWeight.bold, color: Colors.green)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.red[50],
                border: Border.all(color: Colors.red),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text('False', style: TextStyle(fontSize: fontSize * 2, fontWeight: FontWeight.bold, color: Colors.red)),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildIdentificationDisplay(Question question) {
    // User requested empty/minimal display for Identification?
    return const SizedBox();
  }

  Widget _buildEnumerationDisplay(double fontSize) {
     return Container(
       padding: EdgeInsets.all(fontSize),
       decoration: BoxDecoration(
         color: Colors.purple[50],
         borderRadius: BorderRadius.circular(8),
       ),
       child: Row(
         children: [
            Icon(Icons.format_list_numbered, color: Colors.purple, size: fontSize * 2),
            SizedBox(width: 12),
            Expanded(
              child: Text('Students will provide multiple answers', 
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: fontSize)
              ),
            ),
         ],
       ),
     );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
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
