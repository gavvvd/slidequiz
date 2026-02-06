// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'question.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class QuestionAdapter extends TypeAdapter<Question> {
  @override
  final int typeId = 1;

  @override
  Question read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Question(
      id: fields[0] as String?,
      quizId: fields[1] as String,
      type: fields[2] as String,
      questionText: fields[3] as String,
      answer: fields[4] as String,
      points: fields[5] as int,
      timerSeconds: fields[6] as int?,
      acceptedAnswers: (fields[9] as List?)?.cast<String>(),
      isOrdered: fields[10] as bool? ?? false,
      createdAt: fields[7] as DateTime?,
      updatedAt: fields[8] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Question obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.quizId)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.questionText)
      ..writeByte(4)
      ..write(obj.answer)
      ..writeByte(5)
      ..write(obj.points)
      ..writeByte(6)
      ..write(obj.timerSeconds)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.updatedAt)
      ..writeByte(9)
      ..write(obj.acceptedAnswers)
      ..writeByte(10)
      ..write(obj.isOrdered);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuestionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
