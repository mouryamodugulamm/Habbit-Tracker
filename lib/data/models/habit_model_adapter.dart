import 'package:hive/hive.dart';

import 'package:habit_tracker/data/models/habit_model.dart';

/// Custom TypeAdapter for [HabitModel] with backward-compatible defaults for
/// older Hive data (missing isArchived, frequencyIndex, customWeekdays).
/// Register this in main.dart instead of the generated HabitModelAdapter so
/// that re-running build_runner does not break reading existing boxes.
class HabitModelCompatAdapter extends TypeAdapter<HabitModel> {
  @override
  final int typeId = 0;

  @override
  HabitModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    final msList = (fields[2] as List?)?.cast<int>() ?? [];
    final notesRaw = (fields[10] as List?)?.cast<String>();
    return HabitModel(
      modelId: fields[0] as String,
      modelName: fields[1] as String,
      completedDatesMs: msList,
      createdAtMs: fields[3] as int?,
      reminderMinutesSinceMidnight: fields[4] as int?,
      iconIndex: fields[5] as int?,
      isArchived: fields[6] as bool? ?? false,
      category: fields[7] as String?,
      frequencyIndex: fields[8] as int? ?? 0,
      customWeekdays: (fields[9] as List?)?.cast<int>() ?? [],
      completionNotes: notesRaw,
      targetCountPerDay: fields[11] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, HabitModel obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.modelId)
      ..writeByte(1)
      ..write(obj.modelName)
      ..writeByte(2)
      ..write(obj.completedDatesMs)
      ..writeByte(3)
      ..write(obj.createdAtMs)
      ..writeByte(4)
      ..write(obj.reminderMinutesSinceMidnight)
      ..writeByte(5)
      ..write(obj.iconIndex)
      ..writeByte(6)
      ..write(obj.isArchived)
      ..writeByte(7)
      ..write(obj.category)
      ..writeByte(8)
      ..write(obj.frequencyIndex)
      ..writeByte(9)
      ..write(obj.customWeekdays)
      ..writeByte(10)
      ..write(obj.completionNotes ?? <String>[])
      ..writeByte(11)
      ..write(obj.targetCountPerDay);
  }
}
