import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:slidequiz/models/quiz.dart';
import 'package:slidequiz/models/question.dart';
import 'package:slidequiz/models/choice.dart';
import 'package:slidequiz/screens/quiz/answer_key_screen.dart';
import 'package:slidequiz/services/hive_service.dart';
import 'package:slidequiz/screens/quiz/quiz_completion_screen.dart';

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

class _QuizSlideshowScreenState extends State<QuizSlideshowScreen>
    with TickerProviderStateMixin {
  final HiveService _hiveService = HiveService();
  late List<Question> _questions;
  late Map<String, List<Choice>> _questionChoices;
  int _currentIndex = 0;
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _showAnswer = false;

  // Animation & Audio
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

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

    _startQuestion();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _audioPlayer.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _playSound(String soundName) async {
    // try {
    //   await _audioPlayer.play(AssetSource('sounds/$soundName'));
    // } catch (e) {
    //   debugPrint('Error playing sound: $e');
    // }
  }

  void _startQuestion() {
    _showAnswer = false;
    final question = _questions[_currentIndex];
    _remainingSeconds = question.timerSeconds ?? widget.quiz.timerSeconds;

    _pulseController.reset();
    _startTimer();
    _playSound('next_slide.mp3');
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });

        if (_remainingSeconds <= 10) {
          _playSound('tick.mp3');
          _pulseController.repeat(reverse: true);
        }
      } else {
        _timer?.cancel();
        _pulseController.stop();
        _pulseController.reset();
        _nextSlide();
      }
    });
  }

  void _nextSlide() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _startQuestion();
    } else {
      _finishQuiz();
    }
  }

  void _previousSlide() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _startQuestion();
      });
      _playSound('prev_slide.mp3');
    }
  }

  void _finishQuiz() {
    _timer?.cancel();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => QuizCompletionScreen(
          quiz: widget.quiz,
          questions: widget.questions,
          questionChoices: widget.questionChoices,
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
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
    if (widget.questions.isEmpty) return const Scaffold();

    final question = _questions[_currentIndex];

    // Dynamic sizing helper
    double screenHeight = MediaQuery.of(context).size.height;
    double questionFontSize = screenHeight * 0.04;
    double choiceFontSize = screenHeight * 0.025;
    double numberFontSize = screenHeight * 0.025;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Timer Progress Bar
            LinearProgressIndicator(
              value: widget.quiz.timerSeconds > 0
                  ? _remainingSeconds / widget.quiz.timerSeconds
                  : 0,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                _remainingSeconds <= 10 ? Colors.red : Colors.blue,
              ),
              minHeight: 8,
            ),

            // Header / Controls
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Center(
                      child: AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _remainingSeconds <= 10
                                ? _pulseAnimation.value
                                : 1.0,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.timer,
                                  size: 40,
                                  color: _remainingSeconds <= 10
                                      ? Colors.red
                                      : Colors.blue,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _formatTime(_remainingSeconds),
                                  style: TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                    color: _remainingSeconds <= 10
                                        ? Colors.red
                                        : Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getTypeColor(question.type),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${_currentIndex + 1} / ${_questions.length}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Main Content Area (Question + Choices)
            Expanded(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(screenHeight * 0.02),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Question Box
                    Expanded(
                      flex: 2,
                      child: Center(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: _getTypeColor(
                                    question.type,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: _getTypeColor(
                                      question.type,
                                    ).withOpacity(0.5),
                                  ),
                                ),
                                child: Text(
                                  question.type.toUpperCase(),
                                  style: TextStyle(
                                    color: _getTypeColor(question.type),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                question.questionText,
                                style: TextStyle(
                                  fontSize: questionFontSize * 1.2,
                                  fontWeight: FontWeight.w900,
                                  height: 1.2,
                                  color: Colors.black,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.02),

                    // Choices Area
                    Expanded(
                      flex: 3,
                      child: _showAnswer
                          ? _buildAnswerDisplay(question, screenHeight * 0.035)
                          : _buildChoicesForType(question, choiceFontSize),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Controls
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[100],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Previous
                  if (_currentIndex > 0)
                    ElevatedButton.icon(
                      onPressed: _previousSlide,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Prev'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                    )
                  else
                    const SizedBox(
                      width: 88,
                    ), // Spacer to keep Next button consistently placed if Prev is missing
                  // Answer Key Button (Center)
                  if (widget.quiz.showAnswerKey)
                    TextButton.icon(
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
                      icon: const Icon(Icons.vpn_key),
                      label: const Text('Key'),
                    ),

                  // Next
                  ElevatedButton.icon(
                    onPressed: _nextSlide,
                    icon: Icon(
                      _currentIndex == _questions.length - 1
                          ? Icons.check
                          : Icons.arrow_forward,
                    ),
                    label: Text(
                      _currentIndex == _questions.length - 1
                          ? 'Finish'
                          : 'Next',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChoicesForType(Question question, double fontSize) {
    switch (question.type) {
      case Question.typeMultipleChoice:
        return _buildMultipleChoiceDisplay(question, fontSize);
      case Question.typeTrueFalse:
        return _buildTrueFalseDisplay(fontSize);
      case Question.typeIdentification:
      case Question.typeEnumeration:
      default:
        return Center(
          child: Text(
            'Provide the answer',
            style: TextStyle(
              fontSize: fontSize * 1.5,
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
        );
    }
  }

  Widget _buildMultipleChoiceDisplay(Question question, double fontSize) {
    final choices = _questionChoices[question.id] ?? [];
    final labels = ['A', 'B', 'C', 'D', 'E', 'F'];

    // 2-Column Grid with fixed row height
    // List View for choices
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: choices.length,
      itemBuilder: (context, index) {
        final choice = choices[index];
        final displayLabel = labels[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                // Choice selection logic would go here if interactive
              },
              child: Padding(
                padding: EdgeInsets.all(fontSize * 0.8),
                child: Row(
                  children: [
                    Container(
                      width: fontSize * 2.5,
                      height: fontSize * 2.5,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        displayLabel,
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: fontSize * 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        choice.text,
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTrueFalseDisplay(double fontSize) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(
              vertical: fontSize * 0.8,
            ), // Dynamic padding
            decoration: BoxDecoration(
              color: Colors.green[50],
              border: Border.all(color: Colors.green),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              'True',
              style: TextStyle(
                fontSize: fontSize * 2,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(
              vertical: fontSize * 0.8,
            ), // Dynamic padding
            decoration: BoxDecoration(
              color: Colors.red[50],
              border: Border.all(color: Colors.red),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              'False',
              style: TextStyle(
                fontSize: fontSize * 2,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnswerDisplay(Question question, double fontSize) {
    if (question.type == 'Enumeration') {
      final answers = question.answer.split(RegExp(r'[\n,]'));
      return ListView(
        children: answers.map((ans) {
          if (ans.trim().isEmpty) return const SizedBox.shrink();
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              ans.trim(),
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          );
        }).toList(),
      );
    }

    String displayAnswer = question.answer;

    if (question.type == Question.typeMultipleChoice) {
      final choices = _questionChoices[question.id] ?? [];
      final labels = ['A', 'B', 'C', 'D', 'E', 'F'];
      try {
        final matchIndex = choices.indexWhere((c) => c.text == question.answer);
        if (matchIndex != -1) {
          displayAnswer = '${labels[matchIndex]}. ${question.answer}';
        }
      } catch (e) {
        // Fallback to just answer text
      }
    }

    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Correct Answer:',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              displayAnswer,
              style: TextStyle(
                fontSize: fontSize * 1.5,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
