import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'quiz_set.g.dart';

@HiveType(typeId: 4)
class QuizSet extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String quizId; // Foreign key to Quiz

  @HiveField(2)
  late String name; // e.g., "Set A", "Set B", "Morning Session"

  @HiveField(3)
  late List<String> questionOrder; // List of question IDs in randomized order

  @HiveField(4)
  late Map<String, List<String>> choiceOrders; // questionId -> List of choice IDs in randomized order

  @HiveField(5)
  late DateTime createdAt;

  QuizSet({
    String? id,
    required this.quizId,
    required this.name,
    required this.questionOrder,
    required this.choiceOrders,
    DateTime? createdAt,
  }) {
    this.id = id ?? const Uuid().v4();
    this.createdAt = createdAt ?? DateTime.now();
  }

  // Copy constructor
  QuizSet.copy(QuizSet other) {
    id = other.id;
    quizId = other.quizId;
    name = other.name;
    questionOrder = List.from(other.questionOrder);
    choiceOrders = Map.from(other.choiceOrders);
    createdAt = other.createdAt;
  }

  @override
  String toString() {
    return 'QuizSet{id: $id, quizId: $quizId, name: $name, questions: ${questionOrder.length}}';
  }
}
