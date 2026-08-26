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
    required this.subDepartment,
    required this.line,
    required this.size,
    required this.quantity,
    required this.createdAt,
    required this.updatedAt,
    this.sequenceNumber,
  });

  factory InventoryRow.fromMap(Map<String, Object?> map) => InventoryRow(
        id: map['id'] as int,
        plant: map['plant'] as String,
        department: map['department'] as String,
        subDepartment: map['subDepartment'] as String,
        line: map['line'] as String,
        size: map['size'] as String,
        quantity: map['quantity'] as int,
        createdAt: map['createdAt'] as int,
        updatedAt: map['updatedAt'] as int,
        sequenceNumber: map['sequenceNumber'] as int?,
      );

  InventoryRow copyWith({int? sequenceNumber}) => InventoryRow(
        id: id,
        plant: plant,
        department: department,
        subDepartment: subDepartment,
        line: line,
        size: size,
        quantity: quantity,
        createdAt: createdAt,
        updatedAt: updatedAt,
        sequenceNumber: sequenceNumber ?? this.sequenceNumber,
      );

  final int id;
  final String plant;
  final String department;
  final String subDepartment;
  final String line;
  final String size;
  final int quantity;
  final int createdAt;
  final int updatedAt;
  final int? sequenceNumber;
}

class InventoryRecordData {
  const InventoryRecordData({
    required this.id,
    required this.plantId,
    required this.departmentId,
    required this.subDepartmentId,
    required this.lineId,
    required this.sizeId,
    required this.quantity,
    required this.createdAt,
    required this.updatedAt,
  });

  factory InventoryRecordData.fromMap(Map<String, Object?> map) =>
      InventoryRecordData(
        id: map['id'] as int,
        plantId: map['plantId'] as int,
        departmentId: map['departmentId'] as int,
        subDepartmentId: map['subDepartmentId'] as int,
        lineId: map['lineId'] as int,
        sizeId: map['sizeId'] as int,
        quantity: map['quantity'] as int,
        createdAt: map['createdAt'] as int,
        updatedAt: map['updatedAt'] as int,
      );

  final int id;
  final int plantId;
  final int departmentId;
  final int subDepartmentId;
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

class DistributionRow {
  const DistributionRow({
    required this.id,
    required this.inventoryId,
    required this.lineId,
    required this.sizeId,
    required this.line,
    required this.size,
    required this.quantity,
  });

  factory DistributionRow.fromMap(Map<String, Object?> map) => DistributionRow(
        id: map['id'] as int,
        inventoryId: map['inventoryId'] as int,
        lineId: map['lineId'] as int,
        sizeId: map['sizeId'] as int,
        line: map['line'] as String,
        size: map['size'] as String,
        quantity: map['quantity'] as int,
      );

  final int id;
  final int inventoryId;
  final int lineId;
  final int sizeId;
  final String line;
  final String size;
  final int quantity;
}

/// Sentinel used by [InventoryFilter.copyWith] to distinguish "leave unchanged"
/// from "set to null", so individual filters can be cleared.
const Object _unset = Object();

class InventoryFilter {
  const InventoryFilter(
      {this.plantId,
      this.departmentId,
      this.subDepartmentId,
      this.lineId,
      this.sizeId});

  final int? plantId;
  final int? departmentId;
  final int? subDepartmentId;
  final int? lineId;
  final int? sizeId;

  int get activeCount => [
        plantId,
        departmentId,
        subDepartmentId,
        lineId,
        sizeId
      ].where((id) => id != null).length;

  InventoryFilter copyWith({
    Object? plantId = _unset,
    Object? departmentId = _unset,
    Object? subDepartmentId = _unset,
    Object? lineId = _unset,
    Object? sizeId = _unset,
  }) =>
      InventoryFilter(
        plantId: identical(plantId, _unset) ? this.plantId : plantId as int?,
        departmentId: identical(departmentId, _unset)
            ? this.departmentId
            : departmentId as int?,
        subDepartmentId: identical(subDepartmentId, _unset)
            ? this.subDepartmentId
            : subDepartmentId as int?,
        lineId: identical(lineId, _unset) ? this.lineId : lineId as int?,
        sizeId: identical(sizeId, _unset) ? this.sizeId : sizeId as int?,
      );
}

enum MasterType { plants, departments, subDepartments, lines, sizes, blocks }

extension MasterTypeText on MasterType {
  String get label => switch (this) {
        MasterType.plants => 'Planten',
        MasterType.departments => 'Afdelingen',
        MasterType.subDepartments => 'Onderafdelingen',
        MasterType.lines => 'Lijnen',
        MasterType.sizes => 'Maten',
        MasterType.blocks => 'Blokken',
      };

  String get table => switch (this) {
        MasterType.plants => 'plants',
        MasterType.departments => 'departments',
        MasterType.subDepartments => 'subdepartments',
        MasterType.lines => 'lines',
        MasterType.sizes => 'sizes',
        MasterType.blocks => 'blocks',
      };
}
