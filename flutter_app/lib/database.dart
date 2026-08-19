import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';

import 'database_platform.dart'
    if (dart.library.js_interop) 'database_platform_web.dart';

int _now() => DateTime.now().millisecondsSinceEpoch;

class Choice {
  const Choice(this.id, this.name, {this.defaultQuantity});
  final int id;
  final String name;
  final int? defaultQuantity;
}

class InventoryRow {
  const InventoryRow({
    required this.id,
    required this.plant,
    required this.department,
    required this.line,
    required this.size,
    required this.quantity,
    required this.createdAt,
    required this.updatedAt,
  });

  factory InventoryRow.fromMap(Map<String, Object?> map) => InventoryRow(
        id: map['id'] as int,
        plant: map['plant'] as String,
        department: map['department'] as String,
        line: map['line'] as String,
        size: map['size'] as String,
        quantity: map['quantity'] as int,
        createdAt: map['createdAt'] as int,
        updatedAt: map['updatedAt'] as int,
      );

  final int id;
  final String plant;
  final String department;
  final String line;
  final String size;
  final int quantity;
  final int createdAt;
  final int updatedAt;
}

class InventoryRecordData {
  const InventoryRecordData({
    required this.id,
    required this.plantId,
    required this.departmentId,
    required this.lineId,
    required this.sizeId,
    required this.quantity,
    required this.createdAt,
    required this.updatedAt,
  });

  factory InventoryRecordData.fromMap(Map<String, Object?> map) => InventoryRecordData(
        id: map['id'] as int,
        plantId: map['plantId'] as int,
        departmentId: map['departmentId'] as int,
        lineId: map['lineId'] as int,
        sizeId: map['sizeId'] as int,
        quantity: map['quantity'] as int,
        createdAt: map['createdAt'] as int,
        updatedAt: map['updatedAt'] as int,
      );

  final int id;
  final int plantId;
  final int departmentId;
  final int lineId;
  final int sizeId;
  final int quantity;
  final int createdAt;
  final int updatedAt;
}

class SaveResult {
  const SaveResult({
    required this.id,
    required this.previousQuantity,
    required this.changeAmount,
    required this.newQuantity,
    required this.merged,
  });

  final int id;
  final int previousQuantity;
  final int changeAmount;
  final int newQuantity;
  final bool merged;
}

class InventoryHistoryEntry {
  const InventoryHistoryEntry({
    required this.id,
    required this.changeAmount,
    required this.action,
    required this.createdAt,
  });

  factory InventoryHistoryEntry.fromMap(Map<String, Object?> map) =>
      InventoryHistoryEntry(
        id: map['id'] as int,
        changeAmount: map['changeAmount'] as int,
        action: map['action'] as String,
        createdAt: map['createdAt'] as int,
      );

  final int id;
  final int changeAmount;
  final String action;
  final int createdAt;
}

class PlantInventoryTotal {
  const PlantInventoryTotal({
    required this.plantId,
    required this.plant,
    required this.quantity,
  });

  final int plantId;
  final String plant;
  final int quantity;
}

class InventoryFilter {
  const InventoryFilter({this.plantId, this.departmentId, this.lineId, this.sizeId});

  final int? plantId;
  final int? departmentId;
  final int? lineId;
  final int? sizeId;

  int get activeCount => [plantId, departmentId, lineId, sizeId].where((id) => id != null).length;

  InventoryFilter copyWith({int? plantId, int? departmentId, int? lineId, int? sizeId}) => InventoryFilter(
        plantId: plantId ?? this.plantId,
        departmentId: departmentId ?? this.departmentId,
        lineId: lineId ?? this.lineId,
        sizeId: sizeId ?? this.sizeId,
      );
}

enum MasterType { plants, departments, lines, sizes }

extension MasterTypeText on MasterType {
  String get label => switch (this) {
        MasterType.plants => 'Planten',
        MasterType.departments => 'Afdelingen',
        MasterType.lines => 'Lijnen',
        MasterType.sizes => 'Maten',
      };

  String get table => switch (this) {
        MasterType.plants => 'plants',
        MasterType.departments => 'departments',
        MasterType.lines => 'lines',
        MasterType.sizes => 'sizes',
      };
}

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();
  Database? _database;

  Database get database {
    final value = _database;
    if (value == null) throw StateError('Database is nog niet geopend.');
    return value;
  }

  Future<void> init() async {
    if (_database != null) return;
    await configureDatabasePlatform();
    final path = await applicationDatabasePath('plantregistratie_flutter.db');
    _database = await openDatabase(
      path,
      version: 2,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) async {
        await db.execute('''CREATE TABLE plants(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE,
          createdAt INTEGER NOT NULL,
          updatedAt INTEGER NOT NULL)''');
        await db.execute('''CREATE TABLE departments(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE,
          createdAt INTEGER NOT NULL,
          updatedAt INTEGER NOT NULL)''');
        await db.execute('''CREATE TABLE lines(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          departmentId INTEGER,
          createdAt INTEGER NOT NULL,
          updatedAt INTEGER NOT NULL,
          FOREIGN KEY(departmentId) REFERENCES departments(id) ON DELETE RESTRICT)''');
        await db.execute('''CREATE TABLE sizes(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE,
          defaultQuantity INTEGER NOT NULL,
          createdAt INTEGER NOT NULL,
          updatedAt INTEGER NOT NULL)''');
        await db.execute('''CREATE TABLE inventory_records(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          plantId INTEGER NOT NULL,
          departmentId INTEGER NOT NULL,
          lineId INTEGER NOT NULL,
          sizeId INTEGER NOT NULL,
          quantity INTEGER NOT NULL CHECK(quantity >= 0),
          isActive INTEGER NOT NULL DEFAULT 1,
          createdAt INTEGER NOT NULL,
          updatedAt INTEGER NOT NULL,
          FOREIGN KEY(plantId) REFERENCES plants(id) ON DELETE RESTRICT,
          FOREIGN KEY(departmentId) REFERENCES departments(id) ON DELETE RESTRICT,
          FOREIGN KEY(lineId) REFERENCES lines(id) ON DELETE RESTRICT,
          FOREIGN KEY(sizeId) REFERENCES sizes(id) ON DELETE RESTRICT)''');
        await db.execute('''CREATE TABLE inventory_history(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          inventoryId INTEGER NOT NULL,
          changeAmount INTEGER NOT NULL,
          action TEXT NOT NULL,
          createdAt INTEGER NOT NULL,
          FOREIGN KEY(inventoryId) REFERENCES inventory_records(id) ON DELETE RESTRICT)''');
        for (final column in ['plantId', 'departmentId', 'lineId', 'sizeId']) {
          await db.execute('CREATE INDEX index_inventory_$column ON inventory_records($column)');
        }
        await db.execute('CREATE UNIQUE INDEX index_inventory_position ON inventory_records(plantId, departmentId, lineId, sizeId)');
        await db.execute('CREATE INDEX index_inventory_active ON inventory_records(isActive)');
        await db.execute('CREATE INDEX index_history_inventory_date ON inventory_history(inventoryId, createdAt DESC)');
        await db.execute('CREATE INDEX index_plants_name ON plants(name COLLATE NOCASE)');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE inventory_records RENAME TO inventory_records_legacy');
          await db.execute('''CREATE TABLE inventory_records(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            plantId INTEGER NOT NULL,
            departmentId INTEGER NOT NULL,
            lineId INTEGER NOT NULL,
            sizeId INTEGER NOT NULL,
            quantity INTEGER NOT NULL CHECK(quantity >= 0),
            isActive INTEGER NOT NULL DEFAULT 1,
            createdAt INTEGER NOT NULL,
            updatedAt INTEGER NOT NULL,
            FOREIGN KEY(plantId) REFERENCES plants(id) ON DELETE RESTRICT,
            FOREIGN KEY(departmentId) REFERENCES departments(id) ON DELETE RESTRICT,
            FOREIGN KEY(lineId) REFERENCES lines(id) ON DELETE RESTRICT,
            FOREIGN KEY(sizeId) REFERENCES sizes(id) ON DELETE RESTRICT)''');
          await db.execute('''CREATE TABLE inventory_history(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            inventoryId INTEGER NOT NULL,
            changeAmount INTEGER NOT NULL,
            action TEXT NOT NULL,
            createdAt INTEGER NOT NULL,
            FOREIGN KEY(inventoryId) REFERENCES inventory_records(id) ON DELETE RESTRICT)''');
          await db.execute('''INSERT INTO inventory_records(
              plantId, departmentId, lineId, sizeId, quantity, isActive, createdAt, updatedAt)
            SELECT plantId, departmentId, lineId, sizeId, SUM(quantity), 1,
                   MIN(createdAt), MAX(updatedAt)
            FROM inventory_records_legacy
            GROUP BY plantId, departmentId, lineId, sizeId''');
          await db.execute('''INSERT INTO inventory_history(
              inventoryId, changeAmount, action, createdAt)
            SELECT current.id, legacy.quantity,
              CASE WHEN legacy.id = (
                SELECT earliest.id FROM inventory_records_legacy earliest
                WHERE earliest.plantId = legacy.plantId
                  AND earliest.departmentId = legacy.departmentId
                  AND earliest.lineId = legacy.lineId
                  AND earliest.sizeId = legacy.sizeId
                ORDER BY earliest.createdAt, earliest.id LIMIT 1
              ) THEN 'created' ELSE 'added' END,
              legacy.createdAt
            FROM inventory_records_legacy legacy
            JOIN inventory_records current
              ON current.plantId = legacy.plantId
             AND current.departmentId = legacy.departmentId
             AND current.lineId = legacy.lineId
             AND current.sizeId = legacy.sizeId''');
          await db.execute('DROP TABLE inventory_records_legacy');
          for (final column in ['plantId', 'departmentId', 'lineId', 'sizeId']) {
            await db.execute('CREATE INDEX index_inventory_$column ON inventory_records($column)');
          }
          await db.execute('CREATE UNIQUE INDEX index_inventory_position ON inventory_records(plantId, departmentId, lineId, sizeId)');
          await db.execute('CREATE INDEX index_inventory_active ON inventory_records(isActive)');
          await db.execute('CREATE INDEX index_history_inventory_date ON inventory_history(inventoryId, createdAt DESC)');
        }
      },
    );
    await _importLegacyDatabase();
    await _seedMissingData();
  }

  Future<void> _importLegacyDatabase() async {
    if (!canImportLegacyDatabase) return;
    if (await _count('plants') > 0 || await _count('inventory_records') > 0) return;
    final legacyPath = await applicationDatabasePath('plantregistratie.db');
    if (!await databaseExists(legacyPath)) return;
    Database? legacy;
    try {
      legacy = await openDatabase(legacyPath, readOnly: true);
      final tables = ['plants', 'departments', 'lines', 'sizes'];
      final content = <String, List<Map<String, Object?>>>{};
      for (final table in tables) {
        content[table] = await legacy.query(table);
      }
      final oldRecords = await legacy.query('inventory_records', orderBy: 'createdAt, id');
      await database.transaction((transaction) async {
        for (final table in tables) {
          for (final row in content[table]!) {
            await transaction.insert(table, Map<String, Object?>.from(row), conflictAlgorithm: ConflictAlgorithm.ignore);
          }
        }
        for (final row in oldRecords) {
          final keys = [row['plantId'], row['departmentId'], row['lineId'], row['sizeId']];
          final match = await transaction.query(
            'inventory_records',
            columns: ['id', 'quantity'],
            where: 'plantId = ? AND departmentId = ? AND lineId = ? AND sizeId = ?',
            whereArgs: keys,
            limit: 1,
          );
          final quantity = row['quantity'] as int;
          final createdAt = row['createdAt'] as int;
          late final int inventoryId;
          late final String action;
          if (match.isEmpty) {
            inventoryId = await transaction.insert('inventory_records', {
              'plantId': row['plantId'],
              'departmentId': row['departmentId'],
              'lineId': row['lineId'],
              'sizeId': row['sizeId'],
              'quantity': quantity,
              'isActive': 1,
              'createdAt': createdAt,
              'updatedAt': row['updatedAt'] ?? createdAt,
            });
            action = 'created';
          } else {
            inventoryId = match.first['id'] as int;
            await transaction.rawUpdate(
              'UPDATE inventory_records SET quantity = quantity + ?, updatedAt = ? WHERE id = ?',
              [quantity, row['updatedAt'] ?? createdAt, inventoryId],
            );
            action = 'added';
          }
          await transaction.insert('inventory_history', {
            'inventoryId': inventoryId,
            'changeAmount': quantity,
            'action': action,
            'createdAt': createdAt,
          });
        }
      });
    } on DatabaseException {
      // Een ontbrekende of oudere legacy-database blokkeert de nieuwe installatie niet.
    } finally {
      await legacy?.close();
    }
  }

  Future<int> _count(String table) async {
    final result = await database.rawQuery('SELECT COUNT(*) total FROM $table');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> _seedMissingData() async {
    final stamp = _now();
    if (await _count('plants') == 0) {
      final text = await rootBundle.loadString('assets/plants.csv');
      final batch = database.batch();
      for (final raw in text.split(RegExp(r'\r?\n')).skip(1)) {
        var name = raw.trim();
        if (name.startsWith('"') && name.endsWith('"') && name.length >= 2) {
          name = name.substring(1, name.length - 1).replaceAll('""', '"');
        }
        if (name.isNotEmpty) {
          batch.insert('plants', {'name': name, 'createdAt': stamp, 'updatedAt': stamp}, conflictAlgorithm: ConflictAlgorithm.ignore);
        }
      }
      await batch.commit(noResult: true);
    }
    if (await _count('departments') == 0) {
      final text = await rootBundle.loadString('assets/departments.txt');
      final batch = database.batch();
      for (final name in text.split(RegExp(r'\r?\n')).map((value) => value.trim()).where((value) => value.isNotEmpty)) {
        batch.insert('departments', {'name': name, 'createdAt': stamp, 'updatedAt': stamp}, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
      await batch.commit(noResult: true);
    }
    if (await _count('lines') == 0) {
      final batch = database.batch();
      for (var number = 1; number <= 50; number++) {
        batch.insert('lines', {'name': 'Lijn $number', 'departmentId': null, 'createdAt': stamp, 'updatedAt': stamp});
      }
      await batch.commit(noResult: true);
    }
    if (await _count('sizes') == 0) {
      final batch = database.batch();
      for (final entry in {'1L': 250, '2L': 150, '5L': 80}.entries) {
        batch.insert('sizes', {'name': entry.key, 'defaultQuantity': entry.value, 'createdAt': stamp, 'updatedAt': stamp});
      }
      await batch.commit(noResult: true);
    }
  }

  Future<List<Choice>> choices(MasterType type, {int? departmentId}) async {
    final where = type == MasterType.lines && departmentId != null ? '(departmentId IS NULL OR departmentId = ?)' : null;
    final rows = await database.query(type.table, where: where, whereArgs: where == null ? null : [departmentId], orderBy: 'name COLLATE NOCASE');
    return rows.map((row) => Choice(row['id'] as int, row['name'] as String, defaultQuantity: row['defaultQuantity'] as int?)).toList();
  }

  Future<List<InventoryRow>> inventory(String search, InventoryFilter filter) async {
    final where = <String>['r.isActive = 1'];
    final args = <Object?>[];
    final term = search.trim().toLowerCase();
    if (term.isNotEmpty) {
      where.add('(lower(p.name) LIKE ? OR lower(d.name) LIKE ? OR lower(l.name) LIKE ? OR lower(s.name) LIKE ?)');
      args.addAll(List.filled(4, '%$term%'));
    }
    for (final entry in {
      'r.plantId': filter.plantId,
      'r.departmentId': filter.departmentId,
      'r.lineId': filter.lineId,
      'r.sizeId': filter.sizeId,
    }.entries) {
      if (entry.value != null) {
        where.add('${entry.key} = ?');
        args.add(entry.value);
      }
    }
    final rows = await database.rawQuery('''
      SELECT r.id, p.name plant, d.name department, l.name line, s.name size,
             r.quantity, r.createdAt, r.updatedAt
      FROM inventory_records r
      JOIN plants p ON p.id = r.plantId
      JOIN departments d ON d.id = r.departmentId
      JOIN lines l ON l.id = r.lineId
      JOIN sizes s ON s.id = r.sizeId
      ${where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}'}
      ORDER BY r.updatedAt DESC
    ''', args);
    return rows.map(InventoryRow.fromMap).toList();
  }

  Future<InventoryRecordData?> record(int id) async {
    final rows = await database.query('inventory_records', where: 'id = ? AND isActive = 1', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : InventoryRecordData.fromMap(rows.first);
  }

  Future<InventoryRecordData?> matchingRecord({
    required int plantId,
    required int departmentId,
    required int lineId,
    required int sizeId,
    int? excludingId,
  }) async {
    final rows = await database.query(
      'inventory_records',
      where: 'plantId = ? AND departmentId = ? AND lineId = ? AND sizeId = ? AND isActive = 1${excludingId == null ? '' : ' AND id != ?'}',
      whereArgs: [plantId, departmentId, lineId, sizeId, if (excludingId != null) excludingId],
      limit: 1,
    );
    return rows.isEmpty ? null : InventoryRecordData.fromMap(rows.first);
  }

  Future<SaveResult> saveRecord({int? id, required int plantId, required int departmentId, required int lineId, required int sizeId, required int quantity}) async {
    final stamp = _now();
    return database.transaction((transaction) async {
      final matches = await transaction.query(
        'inventory_records',
        where: 'plantId = ? AND departmentId = ? AND lineId = ? AND sizeId = ?${id == null ? '' : ' AND id != ?'}',
        whereArgs: [plantId, departmentId, lineId, sizeId, if (id != null) id],
        limit: 1,
      );
      if (id == null && matches.isNotEmpty) {
        final target = matches.first;
        final targetId = target['id'] as int;
        final previous = target['isActive'] == 1 ? target['quantity'] as int : 0;
        final total = previous + quantity;
        await transaction.update('inventory_records', {
          'quantity': total,
          'isActive': 1,
          'updatedAt': stamp,
        }, where: 'id = ?', whereArgs: [targetId]);
        await transaction.insert('inventory_history', {
          'inventoryId': targetId,
          'changeAmount': quantity,
          'action': 'added',
          'createdAt': stamp,
        });
        return SaveResult(id: targetId, previousQuantity: previous, changeAmount: quantity, newQuantity: total, merged: true);
      }
      if (id == null) {
        final newId = await transaction.insert('inventory_records', {
          'plantId': plantId,
          'departmentId': departmentId,
          'lineId': lineId,
          'sizeId': sizeId,
          'quantity': quantity,
          'isActive': 1,
          'createdAt': stamp,
          'updatedAt': stamp,
        });
        await transaction.insert('inventory_history', {
          'inventoryId': newId,
          'changeAmount': quantity,
          'action': 'created',
          'createdAt': stamp,
        });
        return SaveResult(id: newId, previousQuantity: 0, changeAmount: quantity, newQuantity: quantity, merged: false);
      }

      if (matches.isNotEmpty) {
        throw StateError('Deze voorraadpositie bestaat al. Voeg het aantal via een nieuwe of gekopieerde registratie toe.');
      }
      final sourceRows = await transaction.query('inventory_records', where: 'id = ? AND isActive = 1', whereArgs: [id], limit: 1);
      if (sourceRows.isEmpty) throw StateError('Registratie niet gevonden.');
      final source = sourceRows.first;
      final previous = source['quantity'] as int;
      final positionChanged = source['plantId'] != plantId || source['departmentId'] != departmentId || source['lineId'] != lineId || source['sizeId'] != sizeId;
      final difference = quantity - previous;
      await transaction.update('inventory_records', {
        'plantId': plantId,
        'departmentId': departmentId,
        'lineId': lineId,
        'sizeId': sizeId,
        'quantity': quantity,
        'updatedAt': stamp,
      }, where: 'id = ?', whereArgs: [id]);
      if (difference != 0 || positionChanged) {
        await transaction.insert('inventory_history', {
          'inventoryId': id,
          'changeAmount': difference,
          'action': positionChanged ? 'edited' : 'corrected',
          'createdAt': stamp,
        });
      }
      return SaveResult(id: id, previousQuantity: previous, changeAmount: difference, newQuantity: quantity, merged: false);
    });
  }

  Future<void> deleteRecord(int id) async {
    await database.transaction((transaction) async {
      final rows = await transaction.query('inventory_records', columns: ['quantity'], where: 'id = ? AND isActive = 1', whereArgs: [id], limit: 1);
      if (rows.isEmpty) return;
      final quantity = rows.first['quantity'] as int;
      final stamp = _now();
      await transaction.update('inventory_records', {
        'quantity': 0,
        'isActive': 0,
        'updatedAt': stamp,
      }, where: 'id = ?', whereArgs: [id]);
      await transaction.insert('inventory_history', {
        'inventoryId': id,
        'changeAmount': -quantity,
        'action': 'removed',
        'createdAt': stamp,
      });
    });
  }

  Future<int> inventoryTotal(String search, InventoryFilter filter) async {
    final query = await _stockWhere(search, filter);
    final result = await database.rawQuery('''SELECT COALESCE(SUM(r.quantity), 0) total
      FROM inventory_records r JOIN plants p ON p.id = r.plantId
      ${query.$1}''', query.$2);
    return (result.first['total'] as num?)?.toInt() ?? 0;
  }

  Future<List<PlantInventoryTotal>> inventoryPlantTotals(String search, InventoryFilter filter) async {
    final query = await _stockWhere(search, filter);
    final rows = await database.rawQuery('''SELECT r.plantId, p.name plant, SUM(r.quantity) quantity
      FROM inventory_records r JOIN plants p ON p.id = r.plantId
      ${query.$1}
      GROUP BY r.plantId, p.name
      ORDER BY p.name COLLATE NOCASE''', query.$2);
    return rows.map((row) => PlantInventoryTotal(
      plantId: row['plantId'] as int,
      plant: row['plant'] as String,
      quantity: (row['quantity'] as num).toInt(),
    )).toList();
  }

  Future<(String, List<Object?>)> _stockWhere(String search, InventoryFilter filter) async {
    final where = <String>['r.isActive = 1'];
    final args = <Object?>[];
    final term = search.trim().toLowerCase();
    if (term.isNotEmpty) {
      where.add('lower(p.name) LIKE ?');
      args.add('%$term%');
    }
    for (final entry in {
      'r.plantId': filter.plantId,
      'r.departmentId': filter.departmentId,
      'r.lineId': filter.lineId,
      'r.sizeId': filter.sizeId,
    }.entries) {
      if (entry.value != null) {
        where.add('${entry.key} = ?');
        args.add(entry.value);
      }
    }
    return ('WHERE ${where.join(' AND ')}', args);
  }

  Future<List<InventoryHistoryEntry>> history(int inventoryId) async {
    final rows = await database.query(
      'inventory_history',
      where: 'inventoryId = ?',
      whereArgs: [inventoryId],
      orderBy: 'createdAt DESC, id DESC',
    );
    return rows.map(InventoryHistoryEntry.fromMap).toList();
  }

  Future<int> addMaster(MasterType type, String name, {int defaultQuantity = 0}) {
    final stamp = _now();
    return database.insert(type.table, {
      'name': name.trim(),
      if (type == MasterType.lines) 'departmentId': null,
      if (type == MasterType.sizes) 'defaultQuantity': defaultQuantity,
      'createdAt': stamp,
      'updatedAt': stamp,
    }, conflictAlgorithm: ConflictAlgorithm.abort);
  }

  Future<void> updateMaster(MasterType type, int id, String name, {int defaultQuantity = 0}) => database.update(type.table, {
        'name': name.trim(),
        if (type == MasterType.sizes) 'defaultQuantity': defaultQuantity,
        'updatedAt': _now(),
      }, where: 'id = ?', whereArgs: [id]);

  Future<void> deleteMaster(MasterType type, int id) async {
    final usageSql = switch (type) {
      MasterType.plants => 'SELECT COUNT(*) FROM inventory_records WHERE plantId = ?',
      MasterType.departments => 'SELECT COUNT(*) FROM inventory_records WHERE departmentId = ? OR lineId IN (SELECT id FROM lines WHERE departmentId = ?)',
      MasterType.lines => 'SELECT COUNT(*) FROM inventory_records WHERE lineId = ?',
      MasterType.sizes => 'SELECT COUNT(*) FROM inventory_records WHERE sizeId = ?',
    };
    final args = type == MasterType.departments ? [id, id] : [id];
    final used = Sqflite.firstIntValue(await database.rawQuery(usageSql, args)) ?? 0;
    if (used > 0) throw StateError('Dit item wordt gebruikt in bestaande registraties en kan niet worden verwijderd.');
    await database.delete(type.table, where: 'id = ?', whereArgs: [id]);
  }
}
