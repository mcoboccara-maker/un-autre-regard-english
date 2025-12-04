// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserProfileAdapter extends TypeAdapter<UserProfile> {
  @override
  final int typeId = 4;

  @override
  UserProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserProfile(
      email: fields[0] as String?,
      password: fields[1] as String?,
      age: fields[2] as int?,
      situationFamiliale: fields[3] as String?,
      healthEnergy: fields[4] as String?,
      contraintes: fields[5] as String?,
      valeurs: fields[6] as String?,
      ressources: fields[7] as String?,
      contraintesRecurrentes: fields[8] as String?,
      religionsSelectionnees: (fields[9] as List).cast<String>(),
      courantsLitteraires: (fields[10] as List).cast<String>(),
      approchesPsychologiques: (fields[11] as List).cast<String>(),
      tonalitePrefere: fields[12] as String?,
      ouJenSuis: fields[13] as String?,
      ceQuiPese: fields[14] as String?,
      ceQuiTient: fields[15] as String?,
      lastUpdated: fields[16] as DateTime,
      isCompleted: fields[17] as bool,
      historique30JoursResume: fields[18] as String?,
      philosophesSelectionnes: (fields[19] as List).cast<String>(),
      courantsPhilosophiques: (fields[20] as List).cast<String>(),
      orientationCompleted: fields[21] as bool,
      orientationDate: fields[22] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, UserProfile obj) {
    writer
      ..writeByte(23)
      ..writeByte(0)
      ..write(obj.email)
      ..writeByte(1)
      ..write(obj.password)
      ..writeByte(2)
      ..write(obj.age)
      ..writeByte(3)
      ..write(obj.situationFamiliale)
      ..writeByte(4)
      ..write(obj.healthEnergy)
      ..writeByte(5)
      ..write(obj.contraintes)
      ..writeByte(6)
      ..write(obj.valeurs)
      ..writeByte(7)
      ..write(obj.ressources)
      ..writeByte(8)
      ..write(obj.contraintesRecurrentes)
      ..writeByte(9)
      ..write(obj.religionsSelectionnees)
      ..writeByte(10)
      ..write(obj.courantsLitteraires)
      ..writeByte(11)
      ..write(obj.approchesPsychologiques)
      ..writeByte(12)
      ..write(obj.tonalitePrefere)
      ..writeByte(13)
      ..write(obj.ouJenSuis)
      ..writeByte(14)
      ..write(obj.ceQuiPese)
      ..writeByte(15)
      ..write(obj.ceQuiTient)
      ..writeByte(16)
      ..write(obj.lastUpdated)
      ..writeByte(17)
      ..write(obj.isCompleted)
      ..writeByte(18)
      ..write(obj.historique30JoursResume)
      ..writeByte(19)
      ..write(obj.philosophesSelectionnes)
      ..writeByte(20)
      ..write(obj.courantsPhilosophiques)
      ..writeByte(21)
      ..write(obj.orientationCompleted)
      ..writeByte(22)
      ..write(obj.orientationDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
