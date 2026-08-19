import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

const canImportLegacyDatabase = false;

Future<void> configureDatabasePlatform() async {
  databaseFactory = databaseFactoryFfiWeb;
}

Future<String> applicationDatabasePath(String name) async => name;
