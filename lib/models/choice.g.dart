// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'choice.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ChoiceAdapter extends TypeAdapter<Choice> {
  @override
  final int typeId = 3;

  @override
  Choice read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Choice(
      id: fields[0] as String?,
      questionId: fields[1] as String,
      label: fields[2] as String,
      text: fields[3] as String,
      order: fields[4] as int,
      createdAt: fields[5] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Choice obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.questionId)
      ..writeByte(2)
      ..write(obj.label)
      ..writeByte(3)
      ..write(obj.text)
      ..writeByte(4)
      ..write(obj.order)
      ..writeByte(5)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChoiceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
