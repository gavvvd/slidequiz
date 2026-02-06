import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'subject.g.dart';

@HiveType(typeId: 0)
class Subject extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late String description;

  @HiveField(3)
  late DateTime createdAt;

  @HiveField(4)
  late DateTime updatedAt;

  Subject({
    String? id,
    required this.name,
    this.description = '',
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
