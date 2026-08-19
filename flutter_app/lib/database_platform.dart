import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

const canImportLegacyDatabase = true;

Future<void> configureDatabasePlatform() async {}

Future<String> applicationDatabasePath(String name) async =>
    p.join(await getDatabasesPath(), name);
