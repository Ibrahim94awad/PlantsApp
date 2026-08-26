import 'package:flutter_test/flutter_test.dart';
import 'package:plantregistratie/database.dart';
import 'package:plantregistratie/database_platform.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late List<Choice> plants;
  late int departmentId;
  late int subDepartmentId;
  late List<Choice> lines;
  late int sizeId;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final path = await applicationDatabasePath('plantregistratie_ops_test.db');
    await databaseFactory.deleteDatabase(path);
    db = AppDatabase.instance;
    await db.init(databaseName: 'plantregistratie_ops_test.db');
    plants = await db.choices(MasterType.plants);
    departmentId = (await db.choices(MasterType.departments)).first.id;
    subDepartmentId = (await db.choices(MasterType.subDepartments)).first.id;
    lines = await db.choices(MasterType.lines);
    sizeId = (await db.choices(MasterType.sizes)).first.id;
  });

  Future<int> createRecord(int plantId, int lineId, int quantity) async {
    final result = await db.saveRecord(
      plantId: plantId,
      departmentId: departmentId,
      subDepartmentId: subDepartmentId,
      lineId: lineId,
      sizeId: sizeId,
      quantity: quantity,
    );
    return result.id;
  }

  test('saveRecord creates, merges duplicates and edits with correct history',
      () async {
    final plantId = plants[0].id;
    final id = await createRecord(plantId, lines[0].id, 100);
    var history = await db.history(id);
    expect(history.single.action, 'created');
    expect(history.single.changeAmount, 100);

    // Second save on the same position merges into the existing record.
    final merged = await db.saveRecord(
      plantId: plantId,
      departmentId: departmentId,
      subDepartmentId: subDepartmentId,
      lineId: lines[0].id,
      sizeId: sizeId,
      quantity: 40,
    );
    expect(merged.merged, isTrue);
    expect(merged.id, id);
    expect((await db.record(id))!.quantity, 140);

    // Editing the same position records a correction of the delta.
    await db.saveRecord(
        id: id,
        plantId: plantId,
        departmentId: departmentId,
        subDepartmentId: subDepartmentId,
        lineId: lines[0].id,
        sizeId: sizeId,
        quantity: 120);
    history = await db.history(id);
    expect(history.first.action, 'corrected');
    expect(history.first.changeAmount, -20);
    expect((await db.record(id))!.quantity, 120);
  });

  test('editing to a new position records an edit', () async {
    final plantId = plants[1].id;
    final id = await createRecord(plantId, lines[0].id, 50);
    await db.saveRecord(
        id: id,
        plantId: plantId,
        departmentId: departmentId,
        subDepartmentId: subDepartmentId,
        lineId: lines[1].id,
        sizeId: sizeId,
        quantity: 50);
    final history = await db.history(id);
    expect(history.first.action, 'edited');
  });

  test('distribute moves quantity to another line and conserves the total',
      () async {
    final plantId = plants[2].id;
    final id = await createRecord(plantId, lines[0].id, 100);
    await db.distribute(
        inventoryId: id, lineId: lines[1].id, sizeId: sizeId, quantity: 30);

    expect((await db.record(id))!.quantity, 70);
    final distributions = (await db.distributionsForIds([id]))[id]!;
    expect(distributions, hasLength(1));
    expect(distributions.single.quantity, 30);
  });

  test('distributing back to the parent line merges into the parent', () async {
    final plantId = plants[3].id;
    final id = await createRecord(plantId, lines[0].id, 100);
    await db.distribute(
        inventoryId: id, lineId: lines[1].id, sizeId: sizeId, quantity: 30);
    await db.distribute(
        inventoryId: id, lineId: lines[0].id, sizeId: sizeId, quantity: 20);

    // The split onto the parent line is folded back into the parent record.
    expect((await db.record(id))!.quantity, 70);
    final distributions = (await db.distributionsForIds([id]))[id]!;
    expect(distributions, hasLength(1));
    expect(distributions.single.line, lines[1].name);
    expect(distributions.single.quantity, 30);
  });

  test('distributions sharing a line are summed', () async {
    final plantId = plants[4].id;
    final id = await createRecord(plantId, lines[0].id, 100);
    await db.distribute(
        inventoryId: id, lineId: lines[1].id, sizeId: sizeId, quantity: 10);
    await db.distribute(
        inventoryId: id, lineId: lines[1].id, sizeId: sizeId, quantity: 15);

    final distributions = (await db.distributionsForIds([id]))[id]!;
    expect(distributions, hasLength(1));
    expect(distributions.single.quantity, 25);
  });

  test('distribute rejects amounts above the available quantity', () async {
    final plantId = plants[5].id;
    final id = await createRecord(plantId, lines[0].id, 40);
    expect(
      () => db.distribute(
          inventoryId: id, lineId: lines[1].id, sizeId: sizeId, quantity: 100),
      throwsA(isA<DomainException>()),
    );
  });

  test('subDepartmentCounts counts active records per sub-department',
      () async {
    final before = (await db.subDepartmentCounts())[subDepartmentId] ?? 0;
    final id = await createRecord(plants[6].id, lines[0].id, 10);
    expect((await db.subDepartmentCounts())[subDepartmentId], before + 1);

    await db.deleteRecord(id);
    expect((await db.subDepartmentCounts())[subDepartmentId], before);
  });
}
