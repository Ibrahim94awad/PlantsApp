import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';

import 'data/schema.dart';
import 'domain_exception.dart';
import 'models.dart';

import 'database_platform.dart'
    if (dart.library.js_interop) 'database_platform_web.dart';

export 'domain_exception.dart';
export 'models.dart';

int _now() => DateTime.now().millisecondsSinceEpoch;

/// Single access point to the local SQLite database. Notifies listeners after
/// any mutation so open screens can refresh without reaching into each other.
class AppDatabase extends ChangeNotifier {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();
  Database? _database;

  Database get database {
    final value = _database;
    if (value == null) throw StateError('Database is nog niet geopend.');
    return value;
  }

  Future<void> init({String databaseName = 'plantregistratie_flutter.db'}) async {
    if (_database != null) return;
    await configureDatabasePlatform();
    final path = await applicationDatabasePath(databaseName);
    _database = await openDatabase(
      path,
      version: 4,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) => createSchema(db),
      onUpgrade: (db, oldVersion, newVersion) =>
          upgradeSchema(db, oldVersion, newVersion),
    );
    await _importLegacyDatabase();
    await _seedMissingData();
    await _cleanupDuplicateLines();
  }

  Future<void> _cleanupDuplicateLines() async {
    final ids = await database
        .rawQuery('SELECT DISTINCT inventoryId FROM inventory_distributions');
    final stamp = _now();
    for (final row in ids) {
      final inventoryId = row['inventoryId'] as int;
      await database.transaction((transaction) =>
          _mergeDuplicateLines(transaction, inventoryId, stamp));
    }
  }

  Future<void> _importLegacyDatabase() async {
    if (!canImportLegacyDatabase) return;
    if (await _count('plants') > 0 || await _count('inventory_records') > 0)
      return;
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
      final oldRecords =
          await legacy.query('inventory_records', orderBy: 'createdAt, id');
      await database.transaction((transaction) async {
        for (final table in tables) {
          for (final row in content[table]!) {
            await transaction.insert(table, Map<String, Object?>.from(row),
                conflictAlgorithm: ConflictAlgorithm.ignore);
          }
        }
        for (final row in oldRecords) {
          final keys = [
            row['plantId'],
            row['departmentId'],
            row['lineId'],
            row['sizeId']
          ];
          final match = await transaction.query(
            'inventory_records',
            columns: ['id', 'quantity'],
            where:
                'plantId = ? AND departmentId = ? AND lineId = ? AND sizeId = ?',
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
          batch.insert(
              'plants', {'name': name, 'createdAt': stamp, 'updatedAt': stamp},
              conflictAlgorithm: ConflictAlgorithm.ignore);
        }
      }
      await batch.commit(noResult: true);
    }
    if (await _count('departments') == 0) {
      final text = await rootBundle.loadString('assets/departments.txt');
      final batch = database.batch();
      for (final name in text
          .split(RegExp(r'\r?\n'))
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)) {
        batch.insert('departments',
            {'name': name, 'createdAt': stamp, 'updatedAt': stamp},
            conflictAlgorithm: ConflictAlgorithm.ignore);
      }
      await batch.commit(noResult: true);
    }
    if (await _count('subdepartments') == 0) {
      await database.insert('subdepartments',
          {'name': 'Algemeen', 'createdAt': stamp, 'updatedAt': stamp},
          conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    if (await _count('lines') == 0) {
      final batch = database.batch();
      for (var number = 1; number <= 10; number++) {
        batch.insert('lines', {
          'name': '$number',
          'departmentId': null,
          'createdAt': stamp,
          'updatedAt': stamp
        });
      }
      await batch.commit(noResult: true);
    }
    if (await _count('sizes') == 0) {
      final batch = database.batch();
      for (final entry in {'1L': 250, '2L': 150, '5L': 80}.entries) {
        batch.insert('sizes', {
          'name': entry.key,
          'defaultQuantity': entry.value,
          'createdAt': stamp,
          'updatedAt': stamp
        });
      }
      await batch.commit(noResult: true);
    }
    if (await _count('blocks') == 0) {
      final batch = database.batch();
      for (var i = 1; i <= 10; i++) {
        batch.insert('blocks', {
          'name': i.toString(),
          'multiplier': i,
          'createdAt': stamp,
          'updatedAt': stamp
        });
      }
      await batch.commit(noResult: true);
    }
  }

  Future<List<Choice>> choices(MasterType type, {int? departmentId}) async {
    final where = switch (type) {
      MasterType.lines => departmentId != null
          ? '(departmentId IS NULL OR departmentId = ?)'
          : null,
      _ => null,
    };
    final rows = await database.query(type.table,
        where: where,
        whereArgs: where == null ? null : [departmentId],
        orderBy: 'name COLLATE NOCASE');
    return rows.map((row) {
      final defaultQty =
          row['defaultQuantity'] as int? ?? row['multiplier'] as int?;
      return Choice(row['id'] as int, row['name'] as String,
          defaultQuantity: defaultQty);
    }).toList();
  }

  /// Number of active registrations per sub-department, computed in SQL.
  Future<Map<int, int>> subDepartmentCounts() async {
    final rows = await database.rawQuery(
      'SELECT subDepartmentId, COUNT(*) total FROM inventory_records WHERE isActive = 1 GROUP BY subDepartmentId',
    );
    return {
      for (final row in rows)
        row['subDepartmentId'] as int: (row['total'] as num).toInt(),
    };
  }

  Future<List<InventoryRow>> inventory(String search, InventoryFilter filter,
      {bool includeDistributions = false}) async {
    final where = <String>['r.isActive = 1'];
    if (includeDistributions) where.add('r.quantity > 0');
    final args = <Object?>[];
    final term = search.trim().toLowerCase();
    if (term.isNotEmpty) {
      where.add(
          '(lower(p.name) LIKE ? OR lower(d.name) LIKE ? OR lower(sd.name) LIKE ? OR lower(l.name) LIKE ? OR lower(s.name) LIKE ?)');
      args.addAll(List.filled(5, '%$term%'));
    }
    for (final entry in {
      'r.plantId': filter.plantId,
      'r.departmentId': filter.departmentId,
      'r.subDepartmentId': filter.subDepartmentId,
      'r.lineId': filter.lineId,
      'r.sizeId': filter.sizeId,
    }.entries) {
      if (entry.value != null) {
        where.add('${entry.key} = ?');
        args.add(entry.value);
      }
    }
    final source =
        includeDistributions ? _positionsSource : 'inventory_records';
    final rows = await database.rawQuery('''
      SELECT r.id, p.name plant, d.name department, sd.name subDepartment, l.name line, s.name size,
             r.quantity, r.createdAt, r.updatedAt
      FROM $source r
      JOIN plants p ON p.id = r.plantId
      JOIN departments d ON d.id = r.departmentId
      JOIN subdepartments sd ON sd.id = r.subDepartmentId
      JOIN lines l ON l.id = r.lineId
      JOIN sizes s ON s.id = r.sizeId
      ${where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}'}
      ORDER BY r.updatedAt DESC
    ''', args);
    return rows.map(InventoryRow.fromMap).toList();
  }

  Future<Map<int, List<DistributionRow>>> distributionsForIds(
      List<int> ids) async {
    if (ids.isEmpty) return {};
    final placeholders = List.filled(ids.length, '?').join(',');
    final rows = await database.rawQuery('''
      SELECT dist.id, dist.inventoryId, dist.lineId, dist.sizeId, dist.quantity, l.name line, s.name size
      FROM inventory_distributions dist
      JOIN lines l ON l.id = dist.lineId
      JOIN sizes s ON s.id = dist.sizeId
      WHERE dist.inventoryId IN ($placeholders)
      ORDER BY dist.createdAt, dist.id
    ''', ids);
    final map = <int, List<DistributionRow>>{};
    for (final row in rows) {
      final distribution = DistributionRow.fromMap(row);
      map.putIfAbsent(distribution.inventoryId, () => []).add(distribution);
    }
    return map;
  }

  Future<void> distribute(
      {required int inventoryId,
      required int lineId,
      required int sizeId,
      required int quantity}) async {
    if (quantity <= 0)
      throw const DomainException('Geef een aantal groter dan nul op.');
    final stamp = _now();
    await database.transaction((transaction) async {
      final rows = await transaction.query('inventory_records',
          columns: ['quantity'],
          where: 'id = ? AND isActive = 1',
          whereArgs: [inventoryId],
          limit: 1);
      if (rows.isEmpty)
        throw const DomainException('Registratie niet gevonden.');
      final available = rows.first['quantity'] as int;
      if (quantity > available)
        throw DomainException(
            'Er zijn maar $available planten beschikbaar om te verdelen.');
      await transaction.update(
          'inventory_records',
          {
            'quantity': available - quantity,
            'updatedAt': stamp,
          },
          where: 'id = ?',
          whereArgs: [inventoryId]);
      await transaction.insert('inventory_distributions', {
        'inventoryId': inventoryId,
        'lineId': lineId,
        'sizeId': sizeId,
        'quantity': quantity,
        'createdAt': stamp,
        'updatedAt': stamp,
      });
      await transaction.insert('inventory_history', {
        'inventoryId': inventoryId,
        'changeAmount': -quantity,
        'action': 'distributed',
        'createdAt': stamp,
      });
      await _mergeDuplicateLines(transaction, inventoryId, stamp);
    });
    notifyListeners();
  }

  // Ensures each line appears once per card: splits on the original line merge back,
  // and splits sharing a line are summed.
  Future<void> _mergeDuplicateLines(
      Transaction transaction, int inventoryId, int stamp) async {
    final parentRows = await transaction.query('inventory_records',
        columns: ['lineId', 'quantity'],
        where: 'id = ?',
        whereArgs: [inventoryId],
        limit: 1);
    if (parentRows.isEmpty) return;
    final parentLineId = parentRows.first['lineId'] as int;
    final parentQuantity = parentRows.first['quantity'] as int;
    final dists = await transaction.query('inventory_distributions',
        where: 'inventoryId = ?',
        whereArgs: [inventoryId],
        orderBy: 'createdAt, id');
    final keepByLine = <int, int>{};
    var parentDelta = 0;
    for (final dist in dists) {
      final id = dist['id'] as int;
      final lineId = dist['lineId'] as int;
      final quantity = dist['quantity'] as int;
      if (lineId == parentLineId) {
        parentDelta += quantity;
        await transaction.delete('inventory_distributions',
            where: 'id = ?', whereArgs: [id]);
      } else if (keepByLine.containsKey(lineId)) {
        await transaction.rawUpdate(
            'UPDATE inventory_distributions SET quantity = quantity + ?, updatedAt = ? WHERE id = ?',
            [quantity, stamp, keepByLine[lineId]]);
        await transaction.delete('inventory_distributions',
            where: 'id = ?', whereArgs: [id]);
      } else {
        keepByLine[lineId] = id;
      }
    }
    if (parentDelta != 0) {
      await transaction.update('inventory_records',
          {'quantity': parentQuantity + parentDelta, 'updatedAt': stamp},
          where: 'id = ?', whereArgs: [inventoryId]);
    }
  }

  Future<void> updateDistribution(
      {required int distributionId,
      required int lineId,
      required int quantity}) async {
    if (quantity <= 0)
      throw const DomainException('Geef een aantal groter dan nul op.');
    final stamp = _now();
    await database.transaction((transaction) async {
      final distRows = await transaction.query('inventory_distributions',
          columns: ['inventoryId', 'quantity'],
          where: 'id = ?',
          whereArgs: [distributionId],
          limit: 1);
      if (distRows.isEmpty)
        throw const DomainException('Verdeling niet gevonden.');
      final inventoryId = distRows.first['inventoryId'] as int;
      final oldQuantity = distRows.first['quantity'] as int;
      final parentRows = await transaction.query('inventory_records',
          columns: ['quantity'],
          where: 'id = ? AND isActive = 1',
          whereArgs: [inventoryId],
          limit: 1);
      if (parentRows.isEmpty)
        throw const DomainException('Registratie niet gevonden.');
      final available = parentRows.first['quantity'] as int;
      final delta = quantity - oldQuantity;
      if (delta > available)
        throw DomainException(
            'Er zijn maar ${available + oldQuantity} planten beschikbaar om te verdelen.');
      await transaction.update(
          'inventory_records',
          {
            'quantity': available - delta,
            'updatedAt': stamp,
          },
          where: 'id = ?',
          whereArgs: [inventoryId]);
      await transaction.update(
          'inventory_distributions',
          {
            'lineId': lineId,
            'quantity': quantity,
            'updatedAt': stamp,
          },
          where: 'id = ?',
          whereArgs: [distributionId]);
      await transaction.insert('inventory_history', {
        'inventoryId': inventoryId,
        'changeAmount': -delta,
        'action': 'distributed',
        'createdAt': stamp,
      });
      await _mergeDuplicateLines(transaction, inventoryId, stamp);
    });
    notifyListeners();
  }

  Future<void> removeDistribution(int distributionId) async {
    final stamp = _now();
    await database.transaction((transaction) async {
      final distRows = await transaction.query('inventory_distributions',
          columns: ['inventoryId', 'quantity'],
          where: 'id = ?',
          whereArgs: [distributionId],
          limit: 1);
      if (distRows.isEmpty) return;
      final inventoryId = distRows.first['inventoryId'] as int;
      final quantity = distRows.first['quantity'] as int;
      final parentRows = await transaction.query('inventory_records',
          columns: ['quantity'],
          where: 'id = ?',
          whereArgs: [inventoryId],
          limit: 1);
      if (parentRows.isEmpty) return;
      final available = parentRows.first['quantity'] as int;
      await transaction.update(
          'inventory_records',
          {
            'quantity': available + quantity,
            'updatedAt': stamp,
          },
          where: 'id = ?',
          whereArgs: [inventoryId]);
      await transaction.delete('inventory_distributions',
          where: 'id = ?', whereArgs: [distributionId]);
      await transaction.insert('inventory_history', {
        'inventoryId': inventoryId,
        'changeAmount': quantity,
        'action': 'distributed',
        'createdAt': stamp,
      });
    });
    notifyListeners();
  }

  Future<InventoryRecordData?> record(int id) async {
    final rows = await database.query('inventory_records',
        where: 'id = ? AND isActive = 1', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : InventoryRecordData.fromMap(rows.first);
  }

  Future<InventoryRecordData?> matchingRecord({
    required int plantId,
    required int departmentId,
    required int subDepartmentId,
    required int lineId,
    required int sizeId,
    int? excludingId,
  }) async {
    final rows = await database.query(
      'inventory_records',
      where:
          'plantId = ? AND departmentId = ? AND subDepartmentId = ? AND lineId = ? AND sizeId = ? AND isActive = 1${excludingId == null ? '' : ' AND id != ?'}',
      whereArgs: [
        plantId,
        departmentId,
        subDepartmentId,
        lineId,
        sizeId,
        if (excludingId != null) excludingId
      ],
      limit: 1,
    );
    return rows.isEmpty ? null : InventoryRecordData.fromMap(rows.first);
  }

  Future<SaveResult> saveRecord(
      {int? id,
      required int plantId,
      required int departmentId,
      required int subDepartmentId,
      required int lineId,
      required int sizeId,
      required int quantity}) async {
    final stamp = _now();
    final result = await database.transaction((transaction) async {
      final matches = await transaction.query(
        'inventory_records',
        where:
            'plantId = ? AND departmentId = ? AND subDepartmentId = ? AND lineId = ? AND sizeId = ?${id == null ? '' : ' AND id != ?'}',
        whereArgs: [
          plantId,
          departmentId,
          subDepartmentId,
          lineId,
          sizeId,
          if (id != null) id
        ],
        limit: 1,
      );
      if (id == null && matches.isNotEmpty) {
        final target = matches.first;
        final targetId = target['id'] as int;
        final previous =
            target['isActive'] == 1 ? target['quantity'] as int : 0;
        final total = previous + quantity;
        await transaction.update(
            'inventory_records',
            {
              'quantity': total,
              'isActive': 1,
              'updatedAt': stamp,
            },
            where: 'id = ?',
            whereArgs: [targetId]);
        await transaction.insert('inventory_history', {
          'inventoryId': targetId,
          'changeAmount': quantity,
          'action': 'added',
          'createdAt': stamp,
        });
        return SaveResult(
            id: targetId,
            previousQuantity: previous,
            changeAmount: quantity,
            newQuantity: total,
            merged: true);
      }
      if (id == null) {
        final newId = await transaction.insert('inventory_records', {
          'plantId': plantId,
          'departmentId': departmentId,
          'subDepartmentId': subDepartmentId,
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
        return SaveResult(
            id: newId,
            previousQuantity: 0,
            changeAmount: quantity,
            newQuantity: quantity,
            merged: false);
      }

      if (matches.isNotEmpty) {
        throw const DomainException(
            'Deze voorraadpositie bestaat al. Voeg het aantal via een nieuwe of gekopieerde registratie toe.');
      }
      final sourceRows = await transaction.query('inventory_records',
          where: 'id = ? AND isActive = 1', whereArgs: [id], limit: 1);
      if (sourceRows.isEmpty)
        throw const DomainException('Registratie niet gevonden.');
      final source = sourceRows.first;
      final previous = source['quantity'] as int;
      final positionChanged = source['plantId'] != plantId ||
          source['departmentId'] != departmentId ||
          source['subDepartmentId'] != subDepartmentId ||
          source['lineId'] != lineId ||
          source['sizeId'] != sizeId;
      final difference = quantity - previous;
      await transaction.update(
          'inventory_records',
          {
            'plantId': plantId,
            'departmentId': departmentId,
            'subDepartmentId': subDepartmentId,
            'lineId': lineId,
            'sizeId': sizeId,
            'quantity': quantity,
            'updatedAt': stamp,
          },
          where: 'id = ?',
          whereArgs: [id]);
      if (difference != 0 || positionChanged) {
        await transaction.insert('inventory_history', {
          'inventoryId': id,
          'changeAmount': difference,
          'action': positionChanged ? 'edited' : 'corrected',
          'createdAt': stamp,
        });
      }
      return SaveResult(
          id: id,
          previousQuantity: previous,
          changeAmount: difference,
          newQuantity: quantity,
          merged: false);
    });
    notifyListeners();
    return result;
  }

  Future<void> deleteRecord(int id) async {
    await database.transaction((transaction) async {
      final rows = await transaction.query('inventory_records',
          columns: ['quantity'],
          where: 'id = ? AND isActive = 1',
          whereArgs: [id],
          limit: 1);
      if (rows.isEmpty) return;
      final quantity = rows.first['quantity'] as int;
      final stamp = _now();
      await transaction.update(
          'inventory_records',
          {
            'quantity': 0,
            'isActive': 0,
            'updatedAt': stamp,
          },
          where: 'id = ?',
          whereArgs: [id]);
      await transaction.insert('inventory_history', {
        'inventoryId': id,
        'changeAmount': -quantity,
        'action': 'removed',
        'createdAt': stamp,
      });
    });
    notifyListeners();
  }

  Future<int> inventoryTotal(String search, InventoryFilter filter) async {
    final query = await _stockWhere(search, filter);
    final result =
        await database.rawQuery('''SELECT COALESCE(SUM(r.quantity), 0) total
      FROM $_positionsSource r JOIN plants p ON p.id = r.plantId
      ${query.$1}''', query.$2);
    return (result.first['total'] as num?)?.toInt() ?? 0;
  }

  Future<List<PlantInventoryTotal>> inventoryPlantTotals(
      String search, InventoryFilter filter) async {
    final query = await _stockWhere(search, filter);
    final rows = await database
        .rawQuery('''SELECT r.plantId, p.name plant, SUM(r.quantity) quantity
      FROM $_positionsSource r JOIN plants p ON p.id = r.plantId
      ${query.$1}
      GROUP BY r.plantId, p.name
      ORDER BY p.name COLLATE NOCASE''', query.$2);
    return rows
        .map((row) => PlantInventoryTotal(
              plantId: row['plantId'] as int,
              plant: row['plant'] as String,
              quantity: (row['quantity'] as num).toInt(),
            ))
        .toList();
  }

  static const String _positionsSource = '''(
    SELECT r.id AS id, r.plantId, r.departmentId, r.subDepartmentId, r.lineId, r.sizeId, r.quantity, r.isActive, r.createdAt, r.updatedAt
    FROM inventory_records r WHERE r.isActive = 1
    UNION ALL
    SELECT parent.id AS id, parent.plantId, parent.departmentId, parent.subDepartmentId, dist.lineId, dist.sizeId, dist.quantity, parent.isActive, dist.createdAt, dist.updatedAt
    FROM inventory_distributions dist JOIN inventory_records parent ON parent.id = dist.inventoryId WHERE parent.isActive = 1
  )''';

  Future<(String, List<Object?>)> _stockWhere(
      String search, InventoryFilter filter) async {
    final where = <String>['r.isActive = 1', 'r.quantity > 0'];
    final args = <Object?>[];
    final term = search.trim().toLowerCase();
    if (term.isNotEmpty) {
      where.add('lower(p.name) LIKE ?');
      args.add('%$term%');
    }
    for (final entry in {
      'r.plantId': filter.plantId,
      'r.departmentId': filter.departmentId,
      'r.subDepartmentId': filter.subDepartmentId,
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

  Future<int> addMaster(MasterType type, String name,
      {int defaultQuantity = 0}) async {
    final stamp = _now();
    final id = await database.insert(
        type.table,
        {
          'name': name.trim(),
          if (type == MasterType.lines) 'departmentId': null,
          if (type == MasterType.sizes) 'defaultQuantity': defaultQuantity,
          if (type == MasterType.blocks) 'multiplier': defaultQuantity,
          'createdAt': stamp,
          'updatedAt': stamp,
        },
        conflictAlgorithm: ConflictAlgorithm.abort);
    notifyListeners();
    return id;
  }

  Future<void> updateMaster(MasterType type, int id, String name,
      {int defaultQuantity = 0}) async {
    await database.update(
        type.table,
        {
          'name': name.trim(),
          if (type == MasterType.sizes) 'defaultQuantity': defaultQuantity,
          if (type == MasterType.blocks) 'multiplier': defaultQuantity,
          'updatedAt': _now(),
        },
        where: 'id = ?',
        whereArgs: [id]);
    notifyListeners();
  }

  Future<void> deleteMaster(MasterType type, int id) async {
    final usageSql = switch (type) {
      MasterType.plants =>
        'SELECT COUNT(*) FROM inventory_records WHERE plantId = ?',
      MasterType.departments =>
        'SELECT COUNT(*) FROM inventory_records WHERE departmentId = ? OR lineId IN (SELECT id FROM lines WHERE departmentId = ?)',
      MasterType.subDepartments =>
        'SELECT COUNT(*) FROM inventory_records WHERE subDepartmentId = ?',
      MasterType.lines =>
        'SELECT COUNT(*) FROM inventory_records WHERE lineId = ?',
      MasterType.sizes =>
        'SELECT COUNT(*) FROM inventory_records WHERE sizeId = ?',
      MasterType.blocks => 'SELECT 0',
    };
    final args = type == MasterType.departments ? [id, id] : [id];
    final used =
        Sqflite.firstIntValue(await database.rawQuery(usageSql, args)) ?? 0;
    if (used > 0)
      throw const DomainException(
          'Dit item wordt gebruikt in bestaande registraties en kan niet worden verwijderd.');
    await database.delete(type.table, where: 'id = ?', whereArgs: [id]);
    notifyListeners();
  }
}
