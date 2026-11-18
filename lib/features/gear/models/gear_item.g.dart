// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gear_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GearItemAdapter extends TypeAdapter<GearItem> {
  @override
  final int typeId = 3;

  @override
  GearItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GearItem(
      id: fields[0] as String,
      name: fields[1] as String,
      category: fields[2] as String,
      weightGrams: fields[3] as int?,
      defaultPackingLocation: fields[4] as String?,
      notes: fields[5] as String,
      createdAt: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, GearItem obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.weightGrams)
      ..writeByte(4)
      ..write(obj.defaultPackingLocation)
      ..writeByte(5)
      ..write(obj.notes)
      ..writeByte(6)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GearItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
