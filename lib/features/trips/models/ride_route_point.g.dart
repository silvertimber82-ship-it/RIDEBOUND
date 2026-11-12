// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ride_route_point.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RideRoutePointAdapter extends TypeAdapter<RideRoutePoint> {
  @override
  final int typeId = 2;

  @override
  RideRoutePoint read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RideRoutePoint(
      latitude: fields[0] as double,
      longitude: fields[1] as double,
      timestamp: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, RideRoutePoint obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.latitude)
      ..writeByte(1)
      ..write(obj.longitude)
      ..writeByte(2)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RideRoutePointAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
