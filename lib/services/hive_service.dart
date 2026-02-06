import 'package:hive_flutter/hive_flutter.dart';
import 'package:slidequiz/models/subject.dart';
import 'package:slidequiz/models/quiz.dart';
import 'package:slidequiz/models/question.dart';
import 'package:slidequiz/models/choice.dart';
import 'package:slidequiz/models/quiz_set.dart';

class HiveService {
  static final HiveService _instance = HiveService._internal();
  factory HiveService() => _instance;
  HiveService._internal();

  static const String _subjectsBoxName = 'subjects';
  static const String _quizzesBoxName = 'quizzes';
  static const String _questionsBoxName = 'questions';
  static const String _choicesBoxName = 'choices';
  static const String _quizSetsBoxName = 'quiz_sets';

  late Box<Subject> _subjectsBox;
  late Box<Quiz> _quizzesBox;
  late Box<Question> _questionsBox;
  late Box<Choice> _choicesBox;
  late Box<QuizSet> _quizSetsBox;

  // Initialize Hive and open boxes
  Future<void> init() async {
    await Hive.initFlutter();

    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(SubjectAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(QuestionAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(QuizAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(ChoiceAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(QuizSetAdapter());
    }

    // Open boxes
    _subjectsBox = await Hive.openBox<Subject>(_subjectsBoxName);
    _quizzesBox = await Hive.openBox<Quiz>(_quizzesBoxName);
    _questionsBox = await Hive.openBox<Question>(_questionsBoxName);
    _choicesBox = await Hive.openBox<Choice>(_choicesBoxName);
    _quizSetsBox = await Hive.openBox<QuizSet>(_quizSetsBoxName);
  }

  // Subject CRUD operations
  Future<void> addSubject(Subject subject) async {
    await _subjectsBox.put(subject.id, subject);
  }

  Future<void> updateSubject(Subject subject) async {
    subject.updateTimestamp();
    await _subjectsBox.put(subject.id, subject);
  }

  Future<void> deleteSubject(String id) async {
    // Delete all quizzes associated with this subject (cascade)
    final quizzes = getQuizzesBySubject(id);
    for (var quiz in quizzes) {
      await deleteQuiz(quiz.id);
    }
    // Delete the subject
    await _subjectsBox.delete(id);
  }

  Subject? getSubject(String id) {
    return _subjectsBox.get(id);
  }

  List<Subject> getAllSubjects() {
    return _subjectsBox.values.toList();
  }

  // Quiz CRUD operations
  Future<void> addQuiz(Quiz quiz) async {
    await _quizzesBox.put(quiz.id, quiz);
  }

  Future<void> updateQuiz(Quiz quiz) async {
    quiz.updateTimestamp();
    await _quizzesBox.put(quiz.id, quiz);
  }

  Future<void> deleteQuiz(String id) async {
    // Delete all quiz sets associated with this quiz (cascade)
    final quizSets = getQuizSetsByQuiz(id);
    for (var quizSet in quizSets) {
      await deleteQuizSet(quizSet.id);
    }
    // Delete all questions associated with this quiz (cascade)
    final questions = getQuestionsByQuiz(id);
    for (var question in questions) {
      await deleteQuestion(question.id);
    }
    // Delete the quiz
    await _quizzesBox.delete(id);
  }

  Quiz? getQuiz(String id) {
    return _quizzesBox.get(id);
  }

  List<Quiz> getAllQuizzes() {
    return _quizzesBox.values.toList();
  }

  List<Quiz> getQuizzesBySubject(String subjectId) {
    return _quizzesBox.values
        .where((quiz) => quiz.subjectId == subjectId)
        .toList();
  }

  // Question CRUD operations
  Future<void> addQuestion(Question question) async {
    await _questionsBox.put(question.id, question);
  }

  Future<void> updateQuestion(Question question) async {
    question.updateTimestamp();
    await _questionsBox.put(question.id, question);
  }

  Future<void> deleteQuestion(String id) async {
    // Delete all choices associated with this question (cascade)
    final choices = getChoicesByQuestion(id);
    for (var choice in choices) {
      await _choicesBox.delete(choice.id);
    }
    // Delete the question
    await _questionsBox.delete(id);
  }

  Question? getQuestion(String id) {
    return _questionsBox.get(id);
  }

  List<Question> getAllQuestions() {
    return _questionsBox.values.toList();
  }

  List<Question> getQuestionsByQuiz(String quizId) {
    return _questionsBox.values
        .where((question) => question.quizId == quizId)
        .toList();
  }

  // Choice CRUD operations
  Future<void> addChoice(Choice choice) async {
    await _choicesBox.put(choice.id, choice);
  }

  Future<void> updateChoice(Choice choice) async {
    await _choicesBox.put(choice.id, choice);
  }

  Future<void> deleteChoice(String id) async {
    await _choicesBox.delete(id);
  }

  Choice? getChoice(String id) {
    return _choicesBox.get(id);
  }

  List<Choice> getAllChoices() {
    return _choicesBox.values.toList();
  }

  List<Choice> getChoicesByQuestion(String questionId) {
    return _choicesBox.values
        .where((choice) => choice.questionId == questionId)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  // Batch operations
  Future<void> addQuestions(List<Question> questions) async {
    final Map<String, Question> questionsMap = {
      for (var question in questions) question.id: question
    };
    await _questionsBox.putAll(questionsMap);
  }

  Future<void> addChoices(List<Choice> choices) async {
    final Map<String, Choice> choicesMap = {
      for (var choice in choices) choice.id: choice
    };
    await _choicesBox.putAll(choicesMap);
  }

  Future<void> deleteAllQuestionsByQuiz(String quizId) async {
    final questions = getQuestionsByQuiz(quizId);
    for (var question in questions) {
      await deleteQuestion(question.id);
    }
  }

  Future<void> deleteAllChoicesByQuestion(String questionId) async {
    final choices = getChoicesByQuestion(questionId);
    for (var choice in choices) {
      await _choicesBox.delete(choice.id);
    }
  }

  // QuizSet CRUD operations
  Future<void> addQuizSet(QuizSet quizSet) async {
    await _quizSetsBox.put(quizSet.id, quizSet);
  }

  Future<void> updateQuizSet(QuizSet quizSet) async {
    await _quizSetsBox.put(quizSet.id, quizSet);
  }

  Future<void> deleteQuizSet(String id) async {
    await _quizSetsBox.delete(id);
  }

  QuizSet? getQuizSet(String id) {
    return _quizSetsBox.get(id);
  }

  List<QuizSet> getAllQuizSets() {
    return _quizSetsBox.values.toList();
  }

  List<QuizSet> getQuizSetsByQuiz(String quizId) {
    return _quizSetsBox.values
        .where((quizSet) => quizSet.quizId == quizId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Most recent first
  }

  // Generate a new quiz set with randomization applied
  QuizSet generateQuizSet({
    required Quiz quiz,
    required String name,
  }) {
    // Get all questions for this quiz
    var questions = getQuestionsByQuiz(quiz.id);
    
    // Apply question randomization if enabled
    if (quiz.randomizeQuestions) {
      questions.shuffle();
    }
    
    // Store question order
    final questionOrder = questions.map((q) => q.id).toList();
    
    // Store choice orders for each multiple choice question
    final Map<String, List<String>> choiceOrders = {};
    
    for (var question in questions) {
      if (question.type == Question.typeMultipleChoice) {
        var choices = getChoicesByQuestion(question.id);
        
        // Apply choice randomization if enabled
        if (quiz.randomizeChoices) {
          choices.shuffle();
        }
        
        choiceOrders[question.id] = choices.map((c) => c.id).toList();
      }
    }
    
    return QuizSet(
      quizId: quiz.id,
      name: name,
      questionOrder: questionOrder,
      choiceOrders: choiceOrders,
    );
  }

  // Close boxes
  Future<void> close() async {
    await _subjectsBox.close();
    await _quizzesBox.close();
    await _questionsBox.close();
    await _choicesBox.close();
    await _quizSetsBox.close();
  }
}
