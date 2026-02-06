import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'quiz.g.dart';

@HiveType(typeId: 2)
class Quiz extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String subjectId;

  @HiveField(2)
  late String name;

  @HiveField(3)
  late String description;

  @HiveField(4)
  late bool randomizeQuestions;

  @HiveField(5)
  late bool randomizeChoices;

  @HiveField(6)
  late int timerSeconds;

  @HiveField(7)
  late DateTime createdAt;

  @HiveField(8)
  late DateTime updatedAt;

  @HiveField(9)
  late bool showAnswerKey;

  Quiz({
    String? id,
    required this.subjectId,
    required this.name,
    this.description = '',
    this.randomizeQuestions = false,
    this.randomizeChoices = false,
    this.timerSeconds = 60,
    this.showAnswerKey = true,
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
}
