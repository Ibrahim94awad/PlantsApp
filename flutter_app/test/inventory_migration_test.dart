import 'package:flutter_test/flutter_test.dart';
import 'package:plantregistratie/database.dart';
import 'package:plantregistratie/database_platform.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('migreert dubbele registraties veilig naar voorraad en geschiedenis', () async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final path = await applicationDatabasePath('plantregistratie_flutter.db');
    await databaseFactory.deleteDatabase(path);

    final legacy = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('CREATE TABLE plants(id INTEGER PRIMARY KEY, name TEXT NOT NULL UNIQUE, createdAt INTEGER NOT NULL, updatedAt INTEGER NOT NULL)');
        await db.execute('CREATE TABLE departments(id INTEGER PRIMARY KEY, name TEXT NOT NULL UNIQUE, createdAt INTEGER NOT NULL, updatedAt INTEGER NOT NULL)');
        await db.execute('CREATE TABLE lines(id INTEGER PRIMARY KEY, name TEXT NOT NULL, departmentId INTEGER, createdAt INTEGER NOT NULL, updatedAt INTEGER NOT NULL)');
        await db.execute('CREATE TABLE sizes(id INTEGER PRIMARY KEY, name TEXT NOT NULL UNIQUE, defaultQuantity INTEGER NOT NULL, createdAt INTEGER NOT NULL, updatedAt INTEGER NOT NULL)');
        await db.execute('''CREATE TABLE inventory_records(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          plantId INTEGER NOT NULL,
          departmentId INTEGER NOT NULL,
          lineId INTEGER NOT NULL,
          sizeId INTEGER NOT NULL,
          quantity INTEGER NOT NULL,
          createdAt INTEGER NOT NULL,
          updatedAt INTEGER NOT NULL)''');
      },
    );
    const firstStamp = 1000;
    await legacy.insert('plants', {'id': 1, 'name': 'Osmanthus burkwoodii', 'createdAt': firstStamp, 'updatedAt': firstStamp});
    await legacy.insert('departments', {'id': 1, 'name': 'A6', 'createdAt': firstStamp, 'updatedAt': firstStamp});
    await legacy.insert('lines', {'id': 1, 'name': 'Lijn 1', 'departmentId': null, 'createdAt': firstStamp, 'updatedAt': firstStamp});
    await legacy.insert('sizes', {'id': 1, 'name': '2L', 'defaultQuantity': 150, 'createdAt': firstStamp, 'updatedAt': firstStamp});
    for (final entry in [(150, 1000), (150, 2000), (56, 3000)]) {
      await legacy.insert('inventory_records', {
        'plantId': 1,
        'departmentId': 1,
        'lineId': 1,
        'sizeId': 1,
        'quantity': entry.$1,
        'createdAt': entry.$2,
        'updatedAt': entry.$2,
      });
    }
    await legacy.close();

    final appDatabase = AppDatabase.instance;
    await appDatabase.init();
    expect(await appDatabase.inventoryTotal('', const InventoryFilter()), 356);
    final rows = await appDatabase.inventory('', const InventoryFilter());
    expect(rows, hasLength(1));
    expect(rows.single.quantity, 356);
    final migratedHistory = await appDatabase.history(rows.single.id);
    expect(migratedHistory, hasLength(3));
    expect(migratedHistory.map((entry) => entry.changeAmount).reduce((a, b) => a + b), 356);
    expect(migratedHistory.where((entry) => entry.action == 'created'), hasLength(1));

    await appDatabase.saveRecord(plantId: 1, departmentId: 1, lineId: 1, sizeId: 1, quantity: 44);
    expect(await appDatabase.inventoryTotal('', const InventoryFilter()), 400);
    expect(await appDatabase.history(rows.single.id), hasLength(4));

    await appDatabase.deleteRecord(rows.single.id);
    expect(await appDatabase.inventory('', const InventoryFilter()), isEmpty);
    final completeHistory = await appDatabase.history(rows.single.id);
    expect(completeHistory, hasLength(5));
    expect(completeHistory.map((entry) => entry.changeAmount).reduce((a, b) => a + b), 0);
  });
}
