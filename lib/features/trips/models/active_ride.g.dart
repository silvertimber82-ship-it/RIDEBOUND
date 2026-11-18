// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'active_ride.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ActiveRideAdapter extends TypeAdapter<ActiveRide> {
  @override
  final int typeId = 5;

  @override
  ActiveRide read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ActiveRide(
      id: fields[0] as String,
      routePoints: (fields[1] as List).cast<RideRoutePoint>(),
      distanceMeters: fields[2] as double,
      elapsedSeconds: fields[3] as int,
      isPaused: fields[4] as bool,
      startedAt: fields[5] as DateTime,
      lastUpdated: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ActiveRide obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.routePoints)
      ..writeByte(2)
      ..write(obj.distanceMeters)
      ..writeByte(3)
      ..write(obj.elapsedSeconds)
      ..writeByte(4)
      ..write(obj.isPaused)
      ..writeByte(5)
      ..write(obj.startedAt)
      ..writeByte(6)
      ..write(obj.lastUpdated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActiveRideAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
