// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'emotional_state.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EmotionalStateAdapter extends TypeAdapter<EmotionalState> {
  @override
  final int typeId = 0;

  @override
  EmotionalState read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EmotionalState(
      emotions: (fields[0] as Map).cast<String, EmotionLevel>(),
      timestamp: fields[1] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, EmotionalState obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.emotions)
      ..writeByte(1)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmotionalStateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class EmotionLevelAdapter extends TypeAdapter<EmotionLevel> {
  @override
  final int typeId = 1;

  @override
  EmotionLevel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EmotionLevel(
      level: fields[0] as int,
      nuances: (fields[1] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, EmotionLevel obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.level)
      ..writeByte(1)
      ..write(obj.nuances);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmotionLevelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
