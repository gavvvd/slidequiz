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

  bool _showSplash = false;
  String _subjectName = '';

  // Animation & Audio
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  final AudioPlayer _effectsPlayer = AudioPlayer();
  final AudioPlayer _timerPlayer = AudioPlayer();
  bool _isPlayingEffect = false;
  bool _isPlayingTick = false;

  // Keyboard navigation
  final FocusNode _focusNode = FocusNode();

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

    final subject = _hiveService.getSubject(widget.quiz.subjectId);
    _subjectName = subject?.name ?? 'Unknown Subject';

    _startQuestionSequence();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _effectsPlayer.dispose();
    _timerPlayer.dispose();
    _focusNode.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        _nextSlide();
      } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        _previousSlide();
      }
    }
  }

  void _playEffect(String soundName) async {
    if (_isPlayingEffect) return; // Prevent overlapping calls
    _isPlayingEffect = true;
    try {
      await _effectsPlayer.stop();
      await _effectsPlayer.play(AssetSource('sounds/$soundName'));
    } catch (e) {
      debugPrint('Error playing effect: $e');
    } finally {
      _isPlayingEffect = false;
    }
  }

  void _playTick() async {
    if (_isPlayingTick) return; // Prevent overlapping calls
    _isPlayingTick = true;
    try {
      if (_timerPlayer.state != PlayerState.playing) {
        await _timerPlayer.play(AssetSource('sounds/tick.mp3'));
      }
    } catch (e) {
      debugPrint('Error playing tick: $e');
    } finally {
      _isPlayingTick = false;
    }
  }

  void _startQuestionSequence({bool isPrevious = false}) {
    // Show splash screen first
    setState(() {
      _showSplash = true;
    });
    _playEffect(isPrevious ? 'prev_slide.mp3' : 'next_slide.mp3');

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showSplash = false;
        });
        _startActualQuestion();
      }
    });
  }

  void _startActualQuestion({bool isPrevious = false}) {
    _showAnswer = false;
    final question = _questions[_currentIndex];
    _remainingSeconds = question.timerSeconds ?? widget.quiz.timerSeconds;

    _pulseController.reset();
    _startTimer();

    // Play tick sound and start pulse animation immediately if duration is 10 seconds or less
    if (_remainingSeconds <= 10) {
      _playTick();
      _pulseController.repeat(reverse: true);
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });

        if (_remainingSeconds == 10) {
          _playTick();
          _pulseController.repeat(reverse: true);
        }
      } else {
        _timer?.cancel();
        _pulseController.stop();
        _pulseController.reset();
        _timerPlayer.stop(); // Stop tick sound when time is up
        _nextSlide();
      }
    });
  }

  void _nextSlide() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _startQuestionSequence();
    } else {
      _finishQuiz();
    }
  }

  void _previousSlide() {
    if (_currentIndex > 0) {
      _timerPlayer.stop(); // Stop any ticking first
      setState(() {
        _currentIndex--;
      });
      _startQuestionSequence(isPrevious: true);
    }
  }

  void _finishQuiz() {
    _timer?.cancel();
    _effectsPlayer.stop();
    _timerPlayer.stop();
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

    // Dynamic sizing based on screen and question type
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    double minDimension = screenHeight < screenWidth
        ? screenHeight
        : screenWidth;

    // Font sizes - question size is always priority (large)
    bool isMultipleChoice = question.type == Question.typeMultipleChoice;

    // Question font is always big
    double questionFontSize = minDimension * 0.07;

    // Choices are smaller to give room for the question
    double choiceFontSize = minDimension * 0.03;

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: _showSplash
            ? SafeArea(
                child: Column(
                  children: [
                    // Splash content - centered
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Question ${_currentIndex + 1}',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber[100],
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.amber[400]!),
                              ),
                              child: Text(
                                '${question.points} ${question.points == 1 ? 'point' : 'points'}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber[800],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
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
                                  fontSize: 16,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              _subjectName,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              widget.quiz.name,
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w900,
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (widget.setName != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.blue[200]!),
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
                          ],
                        ),
                      ),
                    ),
                    // Bottom Controls - same as question view
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
                            const SizedBox(width: 88),
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
              )
            : SafeArea(
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
                              'Question ${_currentIndex + 1}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber[600],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '${question.points} ${question.points == 1 ? 'pt' : 'pts'}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Main Content Area (Question + Choices) - adapts to screen, scrolls only if overflow
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            physics: const ClampingScrollPhysics(),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints.maxHeight,
                              ),
                              child: IntrinsicHeight(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: screenWidth * 0.04,
                                    vertical: screenHeight * 0.02,
                                  ),
                                  child: Column(
                                    children: [
                                      // Question Box - takes flexible space based on question type
                                      Flexible(
                                        flex: isMultipleChoice ? 2 : 3,
                                        fit: FlexFit.tight,
                                        child: Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 8,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: _getTypeColor(
                                                    question.type,
                                                  ).withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                  border: Border.all(
                                                    color: _getTypeColor(
                                                      question.type,
                                                    ).withOpacity(0.5),
                                                  ),
                                                ),
                                                child: Text(
                                                  question.type.toUpperCase(),
                                                  style: TextStyle(
                                                    color: _getTypeColor(
                                                      question.type,
                                                    ),
                                                    fontWeight: FontWeight.bold,
                                                    fontSize:
                                                        minDimension * 0.018,
                                                    letterSpacing: 1.2,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                height: screenHeight * 0.02,
                                              ),
                                              FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: ConstrainedBox(
                                                  constraints: BoxConstraints(
                                                    maxWidth: screenWidth * 0.9,
                                                  ),
                                                  child: Text(
                                                    question.questionText,
                                                    style: TextStyle(
                                                      fontSize:
                                                          questionFontSize,
                                                      fontWeight:
                                                          FontWeight.w900,
                                                      height: 1.2,
                                                      color: Colors.black,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      SizedBox(height: screenHeight * 0.02),

                                      // Choices Area - takes remaining space
                                      Flexible(
                                        flex: isMultipleChoice ? 3 : 2,
                                        fit: FlexFit.tight,
                                        child: _showAnswer
                                            ? _buildAnswerDisplay(
                                                question,
                                                choiceFontSize,
                                              )
                                            : _buildChoicesForType(
                                                question,
                                                choiceFontSize,
                                              ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
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
        return Center();
    }
  }

  Widget _buildMultipleChoiceDisplay(Question question, double fontSize) {
    final choices = _questionChoices[question.id] ?? [];
    final labels = ['A', 'B', 'C', 'D', 'E', 'F'];

    // Check if any choice text is too long (threshold: 30 characters)
    final bool hasLongText = choices.any((c) => c.text.length > 50);

    // Use 4x1 column layout if text is long, otherwise 2x2 grid
    if (hasLongText || choices.length > 4) {
      // 4 rows x 1 column layout - content-fitted, minimal gaps
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: List.generate(choices.length, (index) {
          final choice = choices[index];
          final displayLabel = labels[index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: _buildChoiceItem(choice, displayLabel, fontSize),
          );
        }),
      );
    } else {
      // 2 rows x 2 columns grid layout - content-fitted, minimal gaps
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // First row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (choices.isNotEmpty)
                Flexible(
                  child: _buildChoiceItem(choices[0], labels[0], fontSize),
                ),
              if (choices.length > 1) ...[
                const SizedBox(width: 12),
                Flexible(
                  child: _buildChoiceItem(choices[1], labels[1], fontSize),
                ),
              ],
            ],
          ),
          // Second row
          if (choices.length > 2) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: _buildChoiceItem(choices[2], labels[2], fontSize),
                ),
                if (choices.length > 3) ...[
                  const SizedBox(width: 12),
                  Flexible(
                    child: _buildChoiceItem(choices[3], labels[3], fontSize),
                  ),
                ],
              ],
            ),
          ],
        ],
      );
    }
  }

  Widget _buildChoiceItem(Choice choice, String label, double fontSize) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
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
            padding: EdgeInsets.symmetric(
              horizontal: fontSize * 0.3,
              vertical: fontSize * 0.3,
            ),
            child: Row(
              children: [
                Container(
                  width: fontSize * 1.8,
                  height: fontSize * 1.8,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    label,
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: fontSize * 1.1,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      choice.text,
                      style: TextStyle(
                        fontSize: fontSize * 1.4,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrueFalseDisplay(double fontSize) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // True option
            Container(
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.green, width: 2),
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
                  onTap: () {},
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: fontSize * 1.5,
                      vertical: fontSize * 0.5,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: fontSize * 1.8,
                          height: fontSize * 1.8,
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.check,
                            color: Colors.green,
                            size: fontSize * 1.2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'True',
                          style: TextStyle(
                            fontSize: fontSize * 1.4,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // False option
            Container(
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.red, width: 2),
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
                  onTap: () {},
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: fontSize * 1.5,
                      vertical: fontSize * 0.5,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: fontSize * 1.8,
                          height: fontSize * 1.8,
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.close,
                            color: Colors.red,
                            size: fontSize * 1.2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'False',
                          style: TextStyle(
                            fontSize: fontSize * 1.4,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
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
