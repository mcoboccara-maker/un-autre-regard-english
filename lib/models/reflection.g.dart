// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reflection.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ReflectionAdapter extends TypeAdapter<Reflection> {
  @override
  final int typeId = 2;

  @override
  Reflection read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Reflection(
      id: fields[0] as String,
      text: fields[1] as String,
      type: fields[2] as ReflectionType,
      emotionalState: fields[3] as EmotionalState,
      createdAt: fields[4] as DateTime,
      selectedApproaches: (fields[5] as List).cast<String>(),
      aiResponses: (fields[6] as Map).cast<String, String>(),
      isFavorite: fields[7] as bool,
      declencheur: fields[8] as String?,
      souhait: fields[9] as String?,
      petitPas: fields[10] as String?,
      intensiteEmotionnelle: fields[11] as int,
      emotionPrincipale: fields[12] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Reflection obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.text)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.emotionalState)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.selectedApproaches)
      ..writeByte(6)
      ..write(obj.aiResponses)
      ..writeByte(7)
      ..write(obj.isFavorite)
      ..writeByte(8)
      ..write(obj.declencheur)
      ..writeByte(9)
      ..write(obj.souhait)
      ..writeByte(10)
      ..write(obj.petitPas)
      ..writeByte(11)
      ..write(obj.intensiteEmotionnelle)
      ..writeByte(12)
      ..write(obj.emotionPrincipale);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReflectionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ReflectionTypeAdapter extends TypeAdapter<ReflectionType> {
  @override
  final int typeId = 3;

  @override
  ReflectionType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ReflectionType.thought;
      case 1:
        return ReflectionType.situation;
      case 2:
        return ReflectionType.existential;
      case 3:
        return ReflectionType.dilemma;
      default:
        return ReflectionType.thought;
    }
  }

  @override
  void write(BinaryWriter writer, ReflectionType obj) {
    switch (obj) {
      case ReflectionType.thought:
        writer.writeByte(0);
        break;
      case ReflectionType.situation:
        writer.writeByte(1);
        break;
      case ReflectionType.existential:
        writer.writeByte(2);
        break;
      case ReflectionType.dilemma:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReflectionTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
