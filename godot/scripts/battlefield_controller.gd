extends Node3D

var commander: BattleCommander
var friendly_units: Array[ImperiumBattleUnit] = []
var enemy_units: Array[ImperiumBattleUnit] = []
var selected_index := 0
var status_label: Label
var unit_scene: PackedScene
var combat_clock := 0.0
var siege_progress := 0.0
var siege_won := false
var battle_result_recorded := false
var siege_bar: ProgressBar
var force_label: Label

func _ready() -> void:
	unit_scene = load("res://scenes/battle_unit.tscn")
	commander = BattleCommander.new()
	add_child(commander)
	commander.battle_log.connect(_set_status)
	_build_fort()
	_spawn_armies()
	_build_battle_hud()
	_select_all_units()

func _spawn_armies() -> void:
	var army_size := maxi(1000, int(SaveManager.campaign.get("army", 2500)))
	var squad_count := clampi(int(ceil(float(army_size) / 1000.0)), 3, 8)
	for i in range(squad_count):
		var unit := unit_scene.instantiate() as ImperiumBattleUnit
		unit.name = "Birlik %d" % (i + 1)
		unit.unit_name = unit.name
		unit.strength = 100
		unit.position = Vector3(-7.0 + float(i) * 14.0 / float(maxi(1, squad_count - 1)), 0.1, 6.0 + float(i % 2) * 1.2)
		add_child(unit)
		friendly_units.append(unit)
		var mesh := unit.get_node("Visual") as MeshInstance3D
		var material := StandardMaterial3D.new()
		material.albedo_color = Color("#b68a45")
		mesh.material_override = material
	var enemy_count := clampi(squad_count, 3, 8)
	for i in range(enemy_count):
		var enemy := unit_scene.instantiate() as ImperiumBattleUnit
		enemy.name = "Düşman %d" % (i + 1)
		enemy.unit_name = enemy.name
		enemy.strength = 85
		enemy.position = Vector3(-7.0 + float(i) * 14.0 / float(maxi(1, enemy_count - 1)), 0.1, -8.0 - float(i % 2) * 1.2)
		add_child(enemy)
		enemy_units.append(enemy)
		var mesh := enemy.get_node("Visual") as MeshInstance3D
		var material := StandardMaterial3D.new()
		material.albedo_color = Color("#8b4242")
		mesh.material_override = material
		enemy.receive_order(BattleCommander.Order.MOVE_TO, Vector3(enemy.position.x, 0, 4.2), BattleCommander.Formation.LINE)

func _build_fort() -> void:
	var fort := MeshInstance3D.new()
	fort.name = "Fortress"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(10, 5, 3)
	fort.mesh = mesh
	fort.position = Vector3(0, 2.5, -15)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("#77746b")
	fort.material_override = material
	add_child(fort)

func _physics_process(delta: float) -> void:
	if not siege_won:
		var siege_force := 0
		for unit in friendly_units:
			if is_instance_valid(unit) and unit.strength > 0 and unit.active_order == BattleCommander.Order.SIEGE and unit.global_position.distance_to(Vector3(0, 0, -12)) < 4.0:
				siege_force += 1
		if siege_force > 0:
			siege_progress = minf(100.0, siege_progress + delta * 1.7 * siege_force)
			if is_instance_valid(siege_bar):
				siege_bar.value = siege_progress
			if siege_progress >= 100.0:
				siege_won = true
				SaveManager.campaign["sieges_won"] = int(SaveManager.campaign.get("sieges_won", 0)) + 1
				SaveManager.campaign["treasury"] = int(SaveManager.campaign.get("treasury", 0)) + 150
				SaveManager.save_campaign()
				_set_status("Kuşatma başarılı! Kale ele geçirildi. Hazineye 150 altın eklendi.")
	combat_clock += delta
	if combat_clock < 1.25:
		return
	combat_clock = 0.0
	for enemy in enemy_units:
		if not is_instance_valid(enemy) or enemy.strength <= 0:
			continue
		var target: ImperiumBattleUnit
		var nearest := 99999.0
		for ally in friendly_units:
			if is_instance_valid(ally) and ally.strength > 0:
				var distance := enemy.global_position.distance_to(ally.global_position)
				if distance < nearest:
					nearest = distance
					target = ally
		if target and nearest < 2.5:
			var enemy_damage := 4 if enemy.morale >= 50.0 else 2
			var ally_damage := 4 if target.morale >= 50.0 else 2
			target.apply_losses(enemy_damage)
			enemy.apply_losses(ally_damage)
	_check_battle_result()
	_refresh_force_label()

func _check_battle_result() -> void:
	if battle_result_recorded:
		return
	var alive_friends := 0
	var alive_enemies := 0
	for unit in friendly_units:
		if is_instance_valid(unit) and unit.strength > 0:
			alive_friends += 1
	for unit in enemy_units:
		if is_instance_valid(unit) and unit.strength > 0:
			alive_enemies += 1
	if alive_enemies == 0:
		battle_result_recorded = true
		SaveManager.campaign["battles_won"] = int(SaveManager.campaign.get("battles_won", 0)) + 1
		SaveManager.campaign["treasury"] = int(SaveManager.campaign.get("treasury", 0)) + 100
		var conquered := _claim_war_province()
		SaveManager.save_campaign()
		if not conquered.is_empty():
			_set_status("Zafer! %s eyaleti fethedildi. Hazineye 100 altın eklendi." % conquered)
		else:
			_set_status("Zafer! Düşman kuvvetleri dağıtıldı. Hazineye 100 altın eklendi.")
	elif alive_friends == 0:
		battle_result_recorded = true
		SaveManager.campaign["battles_lost"] = int(SaveManager.campaign.get("battles_lost", 0)) + 1
		SaveManager.campaign["stability"] = maxi(0, int(SaveManager.campaign.get("stability", 75)) - 5)
		SaveManager.save_campaign()
		_set_status("Yenilgi. Ordun dağıldı; devlet istikrarı düştü.")

func _claim_war_province() -> String:
	var target_realm := str(SaveManager.campaign.get("war_target_realm", ""))
	if target_realm.is_empty():
		return ""
	var file := FileAccess.open("res://data/scenario_1440.json", FileAccess.READ)
	if file == null:
		return ""
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return ""
	var provinces: Array = parsed.get("provinces", [])
	var owners: Dictionary = SaveManager.campaign.get("province_owners", {})
	var best_province: Dictionary = {}
	for province in provinces:
		if str(province.get("realm", "")) == target_realm and not owners.has(str(province.get("id", ""))):
			if best_province.is_empty() or int(province.get("tax", 0)) > int(best_province.get("tax", 0)):
				best_province = province
	if best_province.is_empty():
		return ""
	var province_id := str(best_province.get("id", ""))
	owners[province_id] = str(SaveManager.campaign.get("realm_id", "ottoman"))
	SaveManager.campaign["province_owners"] = owners
	SaveManager.campaign["war_target_realm"] = ""
	SaveManager.campaign["war_target_name"] = ""
	SaveManager.campaign["stability"] = mini(100, int(SaveManager.campaign.get("stability", 75)) + 5)
	return str(best_province.get("name", "Eyalet"))

func _build_battle_hud() -> void:
	var hud := CanvasLayer.new()
	add_child(hud)
	var mobile_ui := OS.has_feature("mobile")
	var panel := PanelContainer.new()
	if mobile_ui:
		panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
		panel.offset_left = 8
		panel.offset_top = 8
		panel.offset_right = -8
		panel.offset_bottom = 360
	else:
		panel.position = Vector2(16, 16)
		panel.size = Vector2(560, 390)
	hud.add_child(panel)
	var layout := VBoxContainer.new()
	if mobile_ui:
		var battle_scroll := ScrollContainer.new()
		battle_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		battle_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		panel.add_child(battle_scroll)
		battle_scroll.add_child(layout)
	else:
		panel.add_child(layout)
	var title := Label.new()
	title.text = "MEYDAN MUHAREBESİ — ORDU KOMUTASI"
	title.add_theme_font_size_override("font_size", 20)
	layout.add_child(title)
	status_label = Label.new()
	status_label.text = "Birlik seç veya tüm orduyu seç. Altın birlikler senin, kızıllar düşman."
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(status_label)
	force_label = Label.new()
	layout.add_child(force_label)
	var selection: Container = GridContainer.new() if mobile_ui else HBoxContainer.new()
	if mobile_ui:
		(selection as GridContainer).columns = 3
	layout.add_child(selection)
	for i in range(friendly_units.size()):
		var button := Button.new()
		button.text = "Birlik %d" % (i + 1)
		button.pressed.connect(_select_unit.bind(i))
		selection.add_child(button)
	var all_button := Button.new()
	all_button.text = "Tüm ordu"
	all_button.pressed.connect(_select_all_units)
	selection.add_child(all_button)
	var formations: Container = GridContainer.new() if mobile_ui else HBoxContainer.new()
	if mobile_ui:
		(formations as GridContainer).columns = 2
	layout.add_child(formations)
	_add_command_button(formations, "Hat", func(): commander.set_formation(BattleCommander.Formation.LINE))
	_add_command_button(formations, "Kol", func(): commander.set_formation(BattleCommander.Formation.COLUMN))
	_add_command_button(formations, "Kama", func(): commander.set_formation(BattleCommander.Formation.WEDGE))
	_add_command_button(formations, "Kare", func(): commander.set_formation(BattleCommander.Formation.SQUARE))
	var orders: Container = GridContainer.new() if mobile_ui else HBoxContainer.new()
	if mobile_ui:
		(orders as GridContainer).columns = 2
	layout.add_child(orders)
	_add_command_button(orders, "İlerle", func(): commander.issue_order(BattleCommander.Order.ADVANCE))
	_add_command_button(orders, "Hücum", _charge_nearest_enemy)
	_add_command_button(orders, "Tut", func(): commander.issue_order(BattleCommander.Order.HOLD))
	_add_command_button(orders, "Çekil", func(): commander.issue_order(BattleCommander.Order.RETREAT))
	var siege := Button.new()
	siege.text = "Seçili birliklerle kuşat"
	siege.pressed.connect(func(): commander.issue_order(BattleCommander.Order.SIEGE, Vector3(0, 0, -12)))
	layout.add_child(siege)
	siege_bar = ProgressBar.new()
	siege_bar.min_value = 0
	siege_bar.max_value = 100
	siege_bar.value = 0
	layout.add_child(siege_bar)
	if mobile_ui:
		for control in layout.get_children():
			if control is Container:
				for child in control.get_children():
					if child is Button:
						child.custom_minimum_size = Vector2(0, 44)
						child.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var back := Button.new()
	back.text = "Saray'a dön"
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/palace.tscn"))
	layout.add_child(back)
	_refresh_force_label()

func _add_command_button(parent: Control, caption: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = caption
	button.pressed.connect(callback)
	parent.add_child(button)

func _select_unit(index: int) -> void:
	if index < 0 or index >= friendly_units.size() or not is_instance_valid(friendly_units[index]):
		return
	selected_index = index
	commander.select_unit(friendly_units[index])
	_set_status("Seçili birlik: %s — kuvvet: %d" % [friendly_units[index].name, friendly_units[index].strength])

func _select_all_units() -> void:
	var living: Array[Node3D] = []
	for unit in friendly_units:
		if is_instance_valid(unit) and unit.strength > 0:
			living.append(unit)
	commander.select_all(living)
	_set_status("%d birlik seçildi. Verdiğin emir tüm seçili birliklere uygulanır." % living.size())

func _charge_nearest_enemy() -> void:
	var target: ImperiumBattleUnit
	var nearest := 99999.0
	var reference := Vector3.ZERO
	if is_instance_valid(commander.selected_unit):
		reference = commander.selected_unit.global_position
	for enemy in enemy_units:
		if is_instance_valid(enemy) and enemy.strength > 0:
			var distance := reference.distance_to(enemy.global_position)
			if distance < nearest:
				nearest = distance
				target = enemy
	if target:
		commander.issue_order(BattleCommander.Order.CHARGE, target.global_position)
	else:
		_set_status("Hücum edilecek düşman kalmadı.")

func _refresh_force_label() -> void:
	if not is_instance_valid(force_label):
		return
	var friendly_strength := 0
	var enemy_strength := 0
	for unit in friendly_units:
		if is_instance_valid(unit):
			friendly_strength += maxi(0, unit.strength)
	for unit in enemy_units:
		if is_instance_valid(unit):
			enemy_strength += maxi(0, unit.strength)
	force_label.text = "Senin kuvvetin: %d  |  Düşman kuvveti: %d  |  Kuşatma: %d%%" % [friendly_strength, enemy_strength, int(siege_progress)]

func _set_status(message: String) -> void:
	if is_instance_valid(status_label):
		status_label.text = message
