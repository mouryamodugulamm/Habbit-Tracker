import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker/data/services/backup_service.dart';
import 'package:habit_tracker/presentation/providers/goal_providers.dart';
import 'package:habit_tracker/presentation/providers/habit_providers.dart';
import 'package:share_plus/share_plus.dart';

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(
    habitRepository: ref.watch(habitRepositoryProvider),
    goalRepository: ref.watch(goalRepositoryProvider),
  );
});

/// Export all habits and completions to a JSON file and share it (e.g. save to device or cloud).
/// Uses XFile.fromData so no dart:io or file system path is required.
/// Returns error message on failure, null on success.
Future<String?> exportBackup(WidgetRef ref) async {
  try {
    final service = ref.read(backupServiceProvider);
    final json = await service.exportToJson();
    final bytes = Uint8List.fromList(utf8.encode(json));
    await Share.shareXFiles(
      [
        XFile.fromData(
          bytes,
          name: 'habit_tracker_backup.json',
          mimeType: 'application/json',
        ),
      ],
      subject: 'Habit Tracker backup',
      text: 'Backup of all habits and completions. Restore from Profile → Backup / restore.',
    );
    return null;
  } catch (e) {
    return e.toString();
  }
}

/// Result of restore: [success], [cancelled], or [error] with message.
sealed class RestoreResult {}

class RestoreSuccess extends RestoreResult {}

class RestoreCancelled extends RestoreResult {}

class RestoreError extends RestoreResult {
  RestoreError(this.message);
  final String message;
}

/// Restore from a picked JSON file. Clears current data and loads the backup.
/// Uses file bytes (withData) so no dart:io File path is required.
Future<RestoreResult> restoreBackup(WidgetRef ref) async {
  try {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return RestoreCancelled();
    final platformFile = result.files.single;
    final bytes = platformFile.bytes;
    if (bytes == null || bytes.isEmpty) {
      return RestoreError('Could not read file contents');
    }
    final json = utf8.decode(bytes);
    final service = ref.read(backupServiceProvider);
    await service.restoreFromJson(json);
    await ref.read(habitNotifierProvider.notifier).loadHabits();
    await ref.read(goalNotifierProvider.notifier).loadGoals();
    return RestoreSuccess();
  } catch (e) {
    return RestoreError(e.toString());
  }
}
