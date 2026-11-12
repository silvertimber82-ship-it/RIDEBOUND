// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TripAdapter extends TypeAdapter<Trip> {
  @override
  final int typeId = 0;


  @override
  Trip read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    return Trip(
      id: fields[0] as String,
      name: fields[1] as String,
      startLocation: fields[2] as String,
      endLocation: fields[3] as String,
      notes: fields[4] as String,
      createdDate: fields[5] as DateTime,
      isFavorite: (fields[6] as bool?) ?? false,
      startDate: fields[7] as DateTime?,
      endDate: fields[8] as DateTime?,
      manualDistanceMiles: (fields[9] as num?)?.toDouble() ?? 0.0,
      startOdometer: (fields[10] as num?)?.toDouble(),
      endOdometer: (fields[11] as num?)?.toDouble(),
      photoPaths: ((fields[12] as List?) ?? []).cast<String>(),
      journalEntries:
      ((fields[13] as List?) ?? []).cast<JournalEntry>(),
      routePoints:
      ((fields[14] as List?) ?? []).cast<RideRoutePoint>(),
      recordedDistanceMiles:
      (fields[15] as num?)?.toDouble() ?? 0.0,
      durationSeconds: (fields[16] as num?)?.toInt() ?? 0,
      trackingCompleted: (fields[17] as bool?) ?? false,
      status: (fields[18] as String?) ?? 'planned',
    );
  }


  @override
  void write(BinaryWriter writer, Trip obj) {
    writer
      ..writeByte(19)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.startLocation)
      ..writeByte(3)
      ..write(obj.endLocation)
      ..writeByte(4)
      ..write(obj.notes)
      ..writeByte(5)
      ..write(obj.createdDate)
      ..writeByte(6)
      ..write(obj.isFavorite)
      ..writeByte(7)
      ..write(obj.startDate)
      ..writeByte(8)
      ..write(obj.endDate)
      ..writeByte(9)
      ..write(obj.manualDistanceMiles)
      ..writeByte(10)
      ..write(obj.startOdometer)
      ..writeByte(11)
      ..write(obj.endOdometer)
      ..writeByte(12)
      ..write(obj.photoPaths)
      ..writeByte(13)
      ..write(obj.journalEntries)
      ..writeByte(14)
      ..write(obj.routePoints)
      ..writeByte(15)
      ..write(obj.recordedDistanceMiles)
      ..writeByte(16)
      ..write(obj.durationSeconds)
      ..writeByte(17)
      ..write(obj.trackingCompleted)
      ..writeByte(18)
      ..write(obj.status);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TripAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
