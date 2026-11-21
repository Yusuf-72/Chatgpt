extends Node3D

const MAP_WIDTH := 22.0
const MAP_DEPTH := 14.0
var provinces: Array = []
var selected: Dictionary = {}
var info_label: Label
var treasury_label: Label
var camera: Camera3D
var province_bodies: Array[StaticBody3D] = []

func _ready() -> void:
	camera = $Camera3D
	_load_data()
	_build_world()
	_build_ui()

func _load_data() -> void:
	var file := FileAccess.open("res://data/provinces_1444.json", FileAccess.READ)
	if file:
		var parsed: Variant = JSON.parse_string(file.get_as_text())
		if parsed is Dictionary:
			provinces = parsed.get("provinces", [])

func _material(color: Color, roughness := 0.92) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material

func _build_world() -> void:
	var water := MeshInstance3D.new()
	var water_mesh := PlaneMesh.new()
	water_mesh.size = Vector2(30, 20)
	water.mesh = water_mesh
	water.position.y = -0.38
	water.material_override = _material(Color("#173e56"))
	add_child(water)

	var seabed := MeshInstance3D.new()
	var seabed_mesh := PlaneMesh.new()
	seabed_mesh.size = Vector2(26, 16)
	seabed.mesh = seabed_mesh
	seabed.position.y = -0.16
	seabed.material_override = _material(Color("#385d48"))
	add_child(seabed)

	# Coastline is built from raised, hand-shaped land plates beneath the province tiles.
	_add_land_plate(Vector3(-5.4, -0.03, -2.2), Vector3(7.8, 0.35, 5.7), Color("#64734c"))
	_add_land_plate(Vector3(4.7, -0.02, 1.8), Vector3(9.5, 0.36, 7.1), Color("#788052"))
	_add_land_plate(Vector3(-0.5, -0.01, -5.4), Vector3(5.5, 0.3, 3.0), Color("#68734c"))

	for province in provinces:
		_add_province(province)
	_add_compass()
	_add_army_tokens()

func _add_land_plate(pos: Vector3, dimensions: Vector3, color: Color) -> void:
	var plate := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	plate.mesh = mesh
	plate.position = pos
	plate.material_override = _material(color)
	add_child(plate)

func _province_position(province: Dictionary) -> Vector3:
	return Vector3((float(province.get("x", 0.5)) - 0.5) * MAP_WIDTH, 0.18, (float(province.get("y", 0.5)) - 0.5) * MAP_DEPTH)

func _add_province(province: Dictionary) -> void:
	var realm := str(province.get("realm", ""))
	var tile_color := Color("#b68a48") if realm == "ottoman" else Color("#9c6470")
	var body := StaticBody3D.new()
	body.name = "Province_" + str(province.get("id", "unknown"))
	body.set_meta("province", province)
	body.position = _province_position(province)
	add_child(body)
	var tile := MeshInstance3D.new()
	var hex := CylinderMesh.new()
	hex.top_radius = 1.55
	hex.bottom_radius = 1.55
	hex.height = 0.28
	hex.radial_segments = 6
	tile.mesh = hex
	tile.rotation_degrees.y = 30
	tile.material_override = _material(tile_color)
	body.add_child(tile)
	var collision := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 1.55
	shape.height = 0.5
	collision.shape = shape
	body.add_child(collision)
	var city := MeshInstance3D.new()
	var tower := CylinderMesh.new()
	tower.top_radius = 0.18
	tower.bottom_radius = 0.26
	tower.height = 0.85
	tower.radial_segments = 8
	city.mesh = tower
	city.position = Vector3(0, 0.48, 0)
	city.material_override = _material(Color("#e9d9b4"))
	body.add_child(city)
	var roof := MeshInstance3D.new()
	var roof_mesh := PrismMesh.new()
	roof_mesh.size = Vector3(0.55, 0.3, 0.55)
	roof.mesh = roof_mesh
	roof.position = Vector3(0, 0.99, 0)
	roof.material_override = _material(Color("#8b4339"))
	body.add_child(roof)
	var label := Label3D.new()
	label.text = str(province.get("name", "Eyalet"))
	label.position = Vector3(0, 1.45, 0.85)
	label.font_size = 34
	label.pixel_size = 0.006
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color("#fff0d2")
	body.add_child(label)
	province_bodies.append(body)

func _add_compass() -> void:
	var marker := MeshInstance3D.new()
	var mesh := ConeMesh.new()
	mesh.height = 1.4
	mesh.bottom_radius = 0.45
	marker.mesh = mesh
	marker.position = Vector3(-11.5, 0.2, -6.8)
	marker.material_override = _material(Color("#d6b36b"))
	add_child(marker)

func _add_army_tokens() -> void:
	for p in [Vector3(-3.7, 0.35, -1.6), Vector3(2.2, 0.35, 0.8)]:
		var token := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.38
		mesh.bottom_radius = 0.38
		mesh.height = 0.7
		mesh.radial_segments = 8
		token.mesh = mesh
		token.position = p
		token.material_override = _material(Color("#d9b45f"))
		add_child(token)
		var flag := MeshInstance3D.new()
		var flag_mesh := BoxMesh.new()
		flag_mesh.size = Vector3(0.8, 0.42, 0.06)
		flag.mesh = flag_mesh
		flag.position = p + Vector3(0.38, 0.42, 0)
		flag.material_override = _material(Color("#8c2929"))
		add_child(flag)

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := PanelContainer.new()
	panel.position = Vector2(18, 18)
	panel.custom_minimum_size = Vector2(350, 0)
	layer.add_child(panel)
	var layout := VBoxContainer.new()
	panel.add_child(layout)
	var title := Label.new()
	title.text = "IMPERIUM  •  3D SEFER HARİTASI"
	title.add_theme_font_size_override("font_size", 20)
	layout.add_child(title)
	var realm := str(SaveManager.campaign.get("realm", "Osmanlı İmparatorluğu"))
	var ruler := str(SaveManager.campaign.get("ruler", "Hükümdar"))
	var heading := Label.new()
	heading.text = realm + "  |  " + ruler
	layout.add_child(heading)
	treasury_label = Label.new()
	layout.add_child(treasury_label)
	info_label = Label.new()
	info_label.custom_minimum_size.y = 120
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_label.text = "Eyalet seçmek için haritadaki altıgen bölgeye dokun."
	layout.add_child(info_label)
	var tax := Button.new()
	tax.text = "Seçili eyaletten vergi al"
	tax.pressed.connect(_collect_tax)
	layout.add_child(tax)
	var row := HBoxContainer.new()
	layout.add_child(row)
	var palace := Button.new()
	palace.text = "Saray görünümüne dön"
	palace.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/palace.tscn"))
	row.add_child(palace)
	var battle := Button.new()
	battle.text = "Savaş alanı"
	battle.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/battlefield.tscn"))
	row.add_child(battle)
	_refresh_treasury()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_select_from_screen(event.position)
	elif event is InputEventScreenTouch and event.pressed:
		_select_from_screen(event.position)
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_tree().change_scene_to_file("res://scenes/palace.tscn")

func _select_from_screen(screen_position: Vector2) -> void:
	var origin := camera.project_ray_origin(screen_position)
	var direction := camera.project_ray_normal(screen_position)
	var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * 100.0)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return
	var collider: Object = hit.get("collider")
	if collider is StaticBody3D and collider.has_meta("province"):
		selected = collider.get_meta("province")
		info_label.text = "%s\nArazi: %s\nNüfus: %s\nGünlük vergi: %s altın\nGarnizon: %s" % [
			selected.get("name", "Eyalet"), selected.get("terrain", "?"),
			selected.get("population", 0), selected.get("tax", 0), selected.get("garrison", 0)
		]

func _collect_tax() -> void:
	if selected.is_empty():
		info_label.text = "Önce haritadan bir eyalet seç."
		return
	var realm_id := str(SaveManager.campaign.get("realm_id", "ottoman"))
	if str(selected.get("realm", "")) != realm_id:
		info_label.text = "Bu eyalet senin devletine bağlı değil."
		return
	var month_key := str(SaveManager.campaign.get("date", "1444-01-01")).substr(0, 7)
	var province_id := str(selected.get("id", ""))
	var collected: Dictionary = SaveManager.campaign.get("tax_collected", {})
	var months: Dictionary = collected.get(province_id, {})
	if str(months.get(month_key, "")) == "yes":
		info_label.text = "Bu eyaletin vergisi bu ay zaten tahsil edildi."
		return
	var amount := int(selected.get("tax", 0))
	if amount <= 0:
		return
	SaveManager.campaign["treasury"] = int(SaveManager.campaign.get("treasury", 0)) + amount
	months[month_key] = "yes"
	collected[province_id] = months
	SaveManager.campaign["tax_collected"] = collected
	info_label.text += "\n\nAylık vergi tahsil edildi: %d altın." % amount
	_refresh_treasury()
	SaveManager.save_campaign()

func _refresh_treasury() -> void:
	if treasury_label:
		treasury_label.text = "Hazine: %d altın" % int(SaveManager.campaign.get("treasury", 0))
