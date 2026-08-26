import 'package:sqflite/sqflite.dart';

/// Creates the full schema for a fresh database (schema version 4).
Future<void> createSchema(Database db) async {
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
  await db.execute('''CREATE TABLE subdepartments(
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
  await db.execute('''CREATE TABLE blocks(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    multiplier INTEGER NOT NULL,
    createdAt INTEGER NOT NULL,
    updatedAt INTEGER NOT NULL)''');
  await db.execute('''CREATE TABLE inventory_records(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    plantId INTEGER NOT NULL,
    departmentId INTEGER NOT NULL,
    subDepartmentId INTEGER NOT NULL,
    lineId INTEGER NOT NULL,
    sizeId INTEGER NOT NULL,
    quantity INTEGER NOT NULL CHECK(quantity >= 0),
    isActive INTEGER NOT NULL DEFAULT 1,
    createdAt INTEGER NOT NULL,
    updatedAt INTEGER NOT NULL,
    FOREIGN KEY(plantId) REFERENCES plants(id) ON DELETE RESTRICT,
    FOREIGN KEY(departmentId) REFERENCES departments(id) ON DELETE RESTRICT,
    FOREIGN KEY(subDepartmentId) REFERENCES subdepartments(id) ON DELETE RESTRICT,
    FOREIGN KEY(lineId) REFERENCES lines(id) ON DELETE RESTRICT,
    FOREIGN KEY(sizeId) REFERENCES sizes(id) ON DELETE RESTRICT)''');
  await db.execute('''CREATE TABLE inventory_history(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    inventoryId INTEGER NOT NULL,
    changeAmount INTEGER NOT NULL,
    action TEXT NOT NULL,
    createdAt INTEGER NOT NULL,
    FOREIGN KEY(inventoryId) REFERENCES inventory_records(id) ON DELETE RESTRICT)''');
  await db.execute('''CREATE TABLE inventory_distributions(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    inventoryId INTEGER NOT NULL,
    lineId INTEGER NOT NULL,
    sizeId INTEGER NOT NULL,
    quantity INTEGER NOT NULL CHECK(quantity > 0),
    createdAt INTEGER NOT NULL,
    updatedAt INTEGER NOT NULL,
    FOREIGN KEY(inventoryId) REFERENCES inventory_records(id) ON DELETE CASCADE,
    FOREIGN KEY(lineId) REFERENCES lines(id) ON DELETE RESTRICT,
    FOREIGN KEY(sizeId) REFERENCES sizes(id) ON DELETE RESTRICT)''');
  for (final column in [
    'plantId',
    'departmentId',
    'subDepartmentId',
    'lineId',
    'sizeId'
  ]) {
    await db.execute(
        'CREATE INDEX index_inventory_$column ON inventory_records($column)');
  }
  await db.execute(
      'CREATE UNIQUE INDEX index_inventory_position ON inventory_records(plantId, departmentId, subDepartmentId, lineId, sizeId)');
  await db.execute(
      'CREATE INDEX index_inventory_active ON inventory_records(isActive)');
  await db.execute(
      'CREATE INDEX index_history_inventory_date ON inventory_history(inventoryId, createdAt DESC)');
  await db.execute(
      'CREATE INDEX index_distribution_inventory ON inventory_distributions(inventoryId)');
  await db
      .execute('CREATE INDEX index_plants_name ON plants(name COLLATE NOCASE)');
}

/// Applies incremental migrations from [oldVersion] to the current schema.
Future<void> upgradeSchema(Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 4) {
    await db.execute('''CREATE TABLE IF NOT EXISTS blocks(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL UNIQUE,
      multiplier INTEGER NOT NULL,
      createdAt INTEGER NOT NULL,
      updatedAt INTEGER NOT NULL)''');
    await db.execute('''CREATE TABLE IF NOT EXISTS inventory_distributions(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      inventoryId INTEGER NOT NULL,
      lineId INTEGER NOT NULL,
      sizeId INTEGER NOT NULL,
      quantity INTEGER NOT NULL CHECK(quantity > 0),
      createdAt INTEGER NOT NULL,
      updatedAt INTEGER NOT NULL,
      FOREIGN KEY(inventoryId) REFERENCES inventory_records(id) ON DELETE CASCADE,
      FOREIGN KEY(lineId) REFERENCES lines(id) ON DELETE RESTRICT,
      FOREIGN KEY(sizeId) REFERENCES sizes(id) ON DELETE RESTRICT)''');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS index_distribution_inventory ON inventory_distributions(inventoryId)');
  }
  if (oldVersion < 3) {
    await db.execute('''CREATE TABLE subdepartments(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL UNIQUE,
      createdAt INTEGER NOT NULL,
      updatedAt INTEGER NOT NULL)''');
    final stamp = DateTime.now().millisecondsSinceEpoch;
    await db.execute(
        'INSERT INTO subdepartments(name, createdAt, updatedAt) VALUES (?, ?, ?)',
        ['Algemeen', stamp, stamp]);
    if (oldVersion < 2) {
      await db.execute(
          'ALTER TABLE inventory_records RENAME TO inventory_records_legacy');
      await db.execute('''CREATE TABLE inventory_records(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        plantId INTEGER NOT NULL,
        departmentId INTEGER NOT NULL,
        subDepartmentId INTEGER NOT NULL,
        lineId INTEGER NOT NULL,
        sizeId INTEGER NOT NULL,
        quantity INTEGER NOT NULL CHECK(quantity >= 0),
        isActive INTEGER NOT NULL DEFAULT 1,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        FOREIGN KEY(plantId) REFERENCES plants(id) ON DELETE RESTRICT,
        FOREIGN KEY(departmentId) REFERENCES departments(id) ON DELETE RESTRICT,
        FOREIGN KEY(subDepartmentId) REFERENCES subdepartments(id) ON DELETE RESTRICT,
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
          plantId, departmentId, subDepartmentId, lineId, sizeId, quantity, isActive, createdAt, updatedAt)
        SELECT plantId, departmentId, (SELECT id FROM subdepartments WHERE name = 'Algemeen' LIMIT 1), lineId, sizeId, SUM(quantity), 1,
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
      for (final column in [
        'plantId',
        'departmentId',
        'subDepartmentId',
        'lineId',
        'sizeId'
      ]) {
        await db.execute(
            'CREATE INDEX index_inventory_$column ON inventory_records($column)');
      }
      await db.execute(
          'CREATE UNIQUE INDEX index_inventory_position ON inventory_records(plantId, departmentId, subDepartmentId, lineId, sizeId)');
      await db.execute(
          'CREATE INDEX index_inventory_active ON inventory_records(isActive)');
      await db.execute(
          'CREATE INDEX index_history_inventory_date ON inventory_history(inventoryId, createdAt DESC)');
    } else {
      await db.execute(
          'ALTER TABLE inventory_records ADD COLUMN subDepartmentId INTEGER NOT NULL DEFAULT 0');
      await db.execute(
          'UPDATE inventory_records SET subDepartmentId = (SELECT id FROM subdepartments WHERE name = ? LIMIT 1)',
          ['Algemeen']);
      await db.execute(
          'CREATE INDEX index_inventory_subDepartmentId ON inventory_records(subDepartmentId)');
      await db.execute('DROP INDEX IF EXISTS index_inventory_position');
      await db.execute(
          'CREATE UNIQUE INDEX index_inventory_position ON inventory_records(plantId, departmentId, subDepartmentId, lineId, sizeId)');
      await db.execute('PRAGMA foreign_key_check');
    }
  }
}
