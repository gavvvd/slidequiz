import 'package:hive/hive.dart';

part 'user_profile.g.dart';

@HiveType(typeId: 5) // Ensuring unique typeId (Subject is 0, Question 1, etc.)
class UserProfile extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  bool useBiometrics;

  @HiveField(2)
  bool hasPin;

  UserProfile({
    required this.name,
    this.useBiometrics = false,
    this.hasPin = false,
  });
}
