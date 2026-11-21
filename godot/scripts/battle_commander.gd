extends Node
class_name BattleCommander

signal order_issued(order_name: String, target: Vector3)
signal battle_log(message: String)

enum Order { ADVANCE, HOLD, CHARGE, RETREAT, MOVE_TO, SIEGE }
enum Formation { LINE, COLUMN, WEDGE, SQUARE }

var selected_unit: Node3D
var selected_units: Array[Node3D] = []
var current_formation: Formation = Formation.LINE
var orders_issued: int = 0

func select_unit(unit: Node3D) -> void:
	selected_units.clear()
	if is_instance_valid(unit):
		selected_units.append(unit)
	selected_unit = unit
	battle_log.emit("Birlik seçildi: %s" % unit.name)

func select_all(units: Array[Node3D]) -> void:
	selected_units.clear()
	for unit in units:
		if is_instance_valid(unit):
			selected_units.append(unit)
	selected_unit = selected_units[0] if not selected_units.is_empty() else null
	battle_log.emit("%d birlik birlikte seçildi." % selected_units.size())

func set_formation(formation: Formation) -> void:
	current_formation = formation
	for unit in selected_units:
		if is_instance_valid(unit) and unit.has_method("set_formation"):
			unit.set_formation(formation)
	battle_log.emit("Düzen değiştirildi: %s (%d birlik)" % [Formation.keys()[formation], selected_units.size()])

func issue_order(order: Order, target: Vector3 = Vector3.ZERO) -> bool:
	var valid_units: Array[Node3D] = []
	for unit in selected_units:
		if is_instance_valid(unit):
			valid_units.append(unit)
	selected_units = valid_units
	if selected_units.is_empty():
		battle_log.emit("Önce komuta edilecek birliği seçin.")
		return false
	var names := ["İLERLE", "MEVZİYİ KORU", "HÜCUM", "GERİ ÇEKİL", "HEDEFE İLERLE", "KUŞATMAYA GEÇ"]
	var order_name: String = names[order]
	for unit in selected_units:
		if unit.has_method("receive_order"):
			unit.receive_order(order, target, current_formation)
	orders_issued += 1
	order_issued.emit(order_name, target)
	battle_log.emit("%d birliğe %s emri verildi." % [selected_units.size(), order_name])
	return true
