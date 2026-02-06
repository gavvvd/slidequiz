import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'question.g.dart';

@HiveType(typeId: 1)
class Question extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String quizId;

  @HiveField(2)
  late String type;

  @HiveField(3)
  late String questionText;

  @HiveField(4)
  late String answer;

  @HiveField(5)
  late int points;

  @HiveField(6)
  int? timerSeconds;

  @HiveField(7)
  late DateTime createdAt;

  @HiveField(8)
  late DateTime updatedAt;

  @HiveField(9)
  List<String>? acceptedAnswers;

  @HiveField(10)
  bool isOrdered;

  Question({
    String? id,
    required this.quizId,
    required this.type,
    required this.questionText,
    required this.answer,
    this.points = 1,
    this.timerSeconds,
    this.acceptedAnswers,
    this.isOrdered = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    this.id = id ?? const Uuid().v4();
    this.createdAt = createdAt ?? DateTime.now();
    this.updatedAt = updatedAt ?? DateTime.now();
  }

  void updateTimestamp() {
    updatedAt = DateTime.now();
  }

  // Helper code to check answers based on type
  bool checkAnswer(dynamic input) {
    if (type == typeMultipleChoice) {
      return input.toString() == answer;
    } else if (type == typeTrueFalse) {
      return input.toString().toLowerCase() == answer.toLowerCase();
    } else if (type == typeIdentification) {
      // Check if input matches any of the accepted answers
      if (acceptedAnswers != null && acceptedAnswers!.isNotEmpty) {
        return acceptedAnswers!.any((a) => a.trim().toLowerCase() == input.toString().trim().toLowerCase());
      }
      return input.toString().trim().toLowerCase() == answer.trim().toLowerCase();
    } else if (type == typeEnumeration) {
      // Input is expected to be a List<String> or comma-separated string
      List<String> userAnswers;
      if (input is List) {
        userAnswers = input.map((e) => e.toString().trim().toLowerCase()).toList();
      } else {
        userAnswers = input.toString().split(',').map((e) => e.trim().toLowerCase()).toList();
      }

      final correctAnswers = (acceptedAnswers ?? []).map((e) => e.trim().toLowerCase()).toList();
      
      if (correctAnswers.isEmpty) return false;

      if (isOrdered) {
        // Must match exact order
        if (userAnswers.length != correctAnswers.length) return false;
        for (int i = 0; i < correctAnswers.length; i++) {
          if (userAnswers[i] != correctAnswers[i]) return false;
        }
        return true;
      } else {
        // Any order - check if all required answers are present
        // Depending on strictness, we might require exact match of set
        // Usually enumeration implies getting all items.
        final userSet = userAnswers.toSet();
        final correctSet = correctAnswers.toSet();
        return userSet.containsAll(correctSet) && correctSet.containsAll(userSet);
      }
    }
    return false;
  }

  // Question type constants
  static const String typeMultipleChoice = 'Multiple Choice';
  static const String typeIdentification = 'Identification';
  static const String typeTrueFalse = 'True or False';
  static const String typeEnumeration = 'Enumeration';
}
