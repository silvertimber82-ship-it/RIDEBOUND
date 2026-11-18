// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip_gear.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TripGearItemAdapter extends TypeAdapter<TripGearItem> {
  @override
  final int typeId = 4;

  @override
  TripGearItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TripGearItem(
      id: fields[0] as String,
      tripId: fields[1] as String,
      sourceGearItemId: fields[2] as String?,
      name: fields[3] as String,
      category: fields[4] as String,
      weightGrams: fields[5] as int?,
      packingLocation: fields[6] as String?,
      notes: fields[7] as String,
      isPacked: fields[8] as bool,
      sortOrder: fields[9] as int,
    );
  }

  @override
  void write(BinaryWriter writer, TripGearItem obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.tripId)
      ..writeByte(2)
      ..write(obj.sourceGearItemId)
      ..writeByte(3)
      ..write(obj.name)
      ..writeByte(4)
      ..write(obj.category)
      ..writeByte(5)
      ..write(obj.weightGrams)
      ..writeByte(6)
      ..write(obj.packingLocation)
      ..writeByte(7)
      ..write(obj.notes)
      ..writeByte(8)
      ..write(obj.isPacked)
      ..writeByte(9)
      ..write(obj.sortOrder);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TripGearItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
