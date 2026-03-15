// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SessionEntryAdapter extends TypeAdapter<SessionEntry> {
  @override
  final typeId = 1;

  @override
  SessionEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SessionEntry(
      sourceId: fields[0] as String,
      timestamp: fields[1] as DateTime,
      showDate: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, SessionEntry obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.sourceId)
      ..writeByte(1)
      ..write(obj.timestamp)
      ..writeByte(2)
      ..write(obj.showDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
