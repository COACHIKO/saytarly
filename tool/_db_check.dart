// One-off: prints the real databases path and the users table contents.
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';

void main() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  final path = await databaseFactory.getDatabasesPath();
  stdout.writeln('databasesPath=$path');
  final dbPath = '$path${Platform.pathSeparator}xo_cafe57.db';
  final f = File(dbPath);
  stdout.writeln('dbPath=$dbPath exists=${f.existsSync()}');
  if (!f.existsSync()) return;
  final db = await databaseFactory.openDatabase(dbPath);
  final users = await db.query('users');
  for (final u in users) {
    stdout.writeln('user ${u['id']}: ${u['username']} / role=${u['role']}');
  }
  final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name");
  stdout.writeln('tables=${tables.map((t) => t['name']).toList().join(', ')}');
  await db.close();
}
