import 'dart:io';
import 'package:flutter/material.dart';

import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' hide Context, context;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../data/db_helper.dart';
import '../core/localization_service.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool _isLoading = false;

  Future<void> _backupData() async {
    setState(() => _isLoading = true);
    try {
      // Ensure DB is initialized
      await DatabaseHelper.instance.database;

      final directory = await getApplicationDocumentsDirectory();
      final dbPath = await getDatabasesPath(); // System DB path

      final pathsToCheck = [
        join(directory.path, 'amr_billing.db'), // Expected path
        join(dbPath, 'amr_billing.db'), // Fallback 1
        join(dbPath, 'amr_database.db'), // Fallback 2 (old name)
      ];

      File? dbFile;
      for (final p in pathsToCheck) {
        final f = File(p);
        if (await f.exists()) {
          dbFile = f;
          break;
        }
      }

      if (dbFile != null) {
        await Share.shareXFiles([XFile(dbFile.path)], text: 'AMR Backup');
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Database not found')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Backup Failed: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveToDevice() async {
    final loc = Provider.of<LocalizationService>(context, listen: false);
    setState(() => _isLoading = true);
    try {
      await DatabaseHelper.instance.database;

      final directory = await getApplicationDocumentsDirectory();
      final dbPath = await getDatabasesPath();

      final pathsToCheck = [
        join(directory.path, 'amr_billing.db'),
        join(dbPath, 'amr_billing.db'),
        join(dbPath, 'amr_database.db'),
      ];

      File? dbFile;
      for (final p in pathsToCheck) {
        final f = File(p);
        if (await f.exists()) {
          dbFile = f;
          break;
        }
      }

      if (dbFile != null) {
        final bytes = await dbFile.readAsBytes();
        String? outputFile = await FilePicker.platform.saveFile(
          dialogTitle: 'Please select where to save the backup',
          fileName: 'amr_backup_${DateTime.now().millisecondsSinceEpoch}.db',
          bytes: bytes,
        );

        if (outputFile != null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.translate('save_success'))),
          );
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Database not found')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Save Failed: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _restoreData() async {
    setState(() => _isLoading = true);
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null) {
        File file = File(result.files.single.path!);
        final directory = await getApplicationDocumentsDirectory();
        final dbPath = await getDatabasesPath();

        final pathsToCheck = [
          join(directory.path, 'amr_billing.db'),
          join(dbPath, 'amr_billing.db'),
          join(dbPath, 'amr_database.db'),
        ];

        String targetPath = pathsToCheck[0]; // Default
        for (final p in pathsToCheck) {
          if (await File(p).exists()) {
            targetPath = p;
            break;
          }
        }

        // Close DB before overwriting
        await DatabaseHelper.instance.close();

        await file.copy(targetPath);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Restore Successful. Please restart the app for changes to take effect.',
            ),
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Restore Failed: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<LocalizationService>(context);
    return Scaffold(
      appBar: AppBar(title: Text(loc.translate('backup_restore'))),
      body: Center(
        child: _isLoading
            ? CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.backup, size: 80, color: Colors.blue),
                  SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _backupData,
                    icon: Icon(Icons.share),
                    label: Text(loc.translate('backup_data')),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 15,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _saveToDevice,
                    icon: Icon(Icons.save_alt),
                    label: Text(loc.translate('save_to_device')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 15,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _restoreData,
                    icon: Icon(Icons.download),
                    label: Text(loc.translate('restore_data')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 15,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      loc.translate('restore_warning'),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
