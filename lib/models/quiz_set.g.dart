// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quiz_set.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class QuizSetAdapter extends TypeAdapter<QuizSet> {
  @override
  final int typeId = 4;

  @override
  QuizSet read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return QuizSet(
      id: fields[0] as String?,
      quizId: fields[1] as String,
      name: fields[2] as String,
      questionOrder: (fields[3] as List).cast<String>(),
      choiceOrders: (fields[4] as Map).map((dynamic k, dynamic v) =>
          MapEntry(k as String, (v as List).cast<String>())),
      createdAt: fields[5] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, QuizSet obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.quizId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.questionOrder)
      ..writeByte(4)
      ..write(obj.choiceOrders)
      ..writeByte(5)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuizSetAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
