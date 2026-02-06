import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'choice.g.dart';

@HiveType(typeId: 3)
class Choice extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String questionId;

  @HiveField(2)
  late String label;

  @HiveField(3)
  late String text;

  @HiveField(4)
  late int order;

  @HiveField(5)
  late DateTime createdAt;

  Choice({
    String? id,
    required this.questionId,
    required this.label,
    required this.text,
    this.order = 0,
    DateTime? createdAt,
  }) {
    this.id = id ?? const Uuid().v4();
    this.createdAt = createdAt ?? DateTime.now();
  }
}
