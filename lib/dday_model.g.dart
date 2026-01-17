// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dday_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DDayModelAdapter extends TypeAdapter<DDayModel> {
  @override
  final int typeId = 0;

  @override
  DDayModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DDayModel(
      name: fields[0] as String,
      startDate: fields[1] as DateTime,
      endDate: fields[2] as DateTime,
      colorIndex: fields[3] as int,
      isWidgetDark: fields[4] as bool? ?? true,
    );
  }

  @override
  void write(BinaryWriter writer, DDayModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.startDate)
      ..writeByte(2)
      ..write(obj.endDate)
      ..writeByte(3)
      ..write(obj.colorIndex)
      ..writeByte(4)
      ..write(obj.isWidgetDark);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DDayModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
