// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'show.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ShowAdapter extends TypeAdapter<Show> {
  @override
  final int typeId = 1;

  @override
  Show read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Show(
      name: fields[0] as String,
      artist: fields[1] as String,
      date: fields[2] as String,
      venue: fields[3] as String,
      location: fields[4] as String,
      sources: (fields[5] as List).cast<Source>(),
      hasFeaturedTrack: fields[6] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Show obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.artist)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.venue)
      ..writeByte(4)
      ..write(obj.location)
      ..writeByte(5)
      ..write(obj.sources)
      ..writeByte(6)
      ..write(obj.hasFeaturedTrack);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShowAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
