extends Node3D

var dialogue_layer: CanvasLayer
var dialogue_title: Label
var dialogue_text: Label
var dialogue_choices: VBoxContainer
var battle_commander: BattleCommander
var map_panel: PanelContainer
var succession_panel: PanelContainer
var map_detail: Label
var treasury_label: Label
var date_label: Label
var provinces: Array = []
var selected_province: Dictionary = {}
var is_mobile := false
var army_label: Label
var historical_realms: Array = []
var historical_rulers: Array = []

func _ready() -> void:
	is_mobile = OS.has_feature("mobile")
	var has_saved_campaign := SaveManager.load_campaign()
	battle_commander = BattleCommander.new()
	battle_commander.name = "BattleCommander"
	add_child(battle_commander)
	_load_provinces()
	_load_historical_catalog()
	_build_palace_details()
	_build_courtyard_details()
	_build_dialogue_ui()
	_build_campaign_hud()
	_add_ambassador()
	_refresh_campaign_hud()
	if not has_saved_campaign:
		_show_campaign_setup()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_M:
			_toggle_map()
		elif event.keycode == KEY_B:
			_open_battlefield()

func _load_provinces() -> void:
	var file := FileAccess.open("res://data/provinces_1444.json", FileAccess.READ)
	if file == null:
		push_error("Eyalet verisi bulunamadı.")
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		provinces = parsed.get("provinces", [])

func _add_ambassador() -> void:
	var scene := load("res://scenes/ambassador.tscn") as PackedScene
	if scene:
		add_child(scene.instantiate())

func _build_dialogue_ui() -> void:
	dialogue_layer = CanvasLayer.new()
	dialogue_layer.name = "DialogueLayer"
	add_child(dialogue_layer)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	panel.position = Vector2(-300, -300)
	panel.size = Vector2(600, 270)
	dialogue_layer.add_child(panel)
	var layout := VBoxContainer.new()
	panel.add_child(layout)
	dialogue_title = Label.new()
	dialogue_title.add_theme_font_size_override("font_size", 24)
	layout.add_child(dialogue_title)
	dialogue_text = Label.new()
	dialogue_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_text.custom_minimum_size.y = 65
	layout.add_child(dialogue_text)
	dialogue_choices = VBoxContainer.new()
	layout.add_child(dialogue_choices)
	panel.visible = false
	panel.name = "DialoguePanel"
	dialogue_layer.set_meta("panel", panel)

func _build_campaign_hud() -> void:
	var hud := $HUD
	var top := HBoxContainer.new()
	top.position = Vector2(20, 65)
	top.add_theme_constant_override("separation", 12)
	hud.add_child(top)
	date_label = Label.new()
	date_label.add_theme_font_size_override("font_size", 18)
	top.add_child(date_label)
	treasury_label = Label.new()
	treasury_label.add_theme_font_size_override("font_size", 18)
	top.add_child(treasury_label)
	army_label = Label.new()
	army_label.add_theme_font_size_override("font_size", 18)
	top.add_child(army_label)
	var map_button := Button.new()
	map_button.text = "Harita [M]"
	map_button.pressed.connect(_toggle_map)
	top.add_child(map_button)
	var world_map_button := Button.new()
	world_map_button.text = "3D Dünya Haritası"
	world_map_button.pressed.connect(_open_world_map)
	top.add_child(world_map_button)
	var advance_button := Button.new()
	advance_button.text = "1 Gün"
	advance_button.pressed.connect(_advance_day)
	top.add_child(advance_button)
	var month_button := Button.new()
	month_button.text = "1 Ay İlerle"
	month_button.pressed.connect(_advance_month)
	top.add_child(month_button)
	var diplomacy_button := Button.new()
	diplomacy_button.text = "Diplomasi"
	diplomacy_button.pressed.connect(_open_diplomacy)
	top.add_child(diplomacy_button)
	var recruit_button := Button.new()
	recruit_button.text = "Asker Al"
	recruit_button.pressed.connect(_recruit_army)
	top.add_child(recruit_button)
	var battle_button := Button.new()
	battle_button.text = "Savaş Alanı [B]"
	battle_button.pressed.connect(_open_battlefield)
	top.add_child(battle_button)
	var setup_button := Button.new()
	setup_button.text = "Hükümdar / Tarih"
	setup_button.pressed.connect(_show_campaign_setup)
	top.add_child(setup_button)
	var succession_button := Button.new()
	succession_button.text = "Halefiyet"
	succession_button.pressed.connect(_show_succession)
	top.add_child(succession_button)
	var save_button := Button.new()
	save_button.text = "Kaydet"
	save_button.pressed.connect(_save_game)
	top.add_child(save_button)

	map_panel = PanelContainer.new()
	map_panel.position = Vector2(25, 115)
	map_panel.size = Vector2(720, 530)
	hud.add_child(map_panel)
	map_panel.visible = false
	succession_panel = PanelContainer.new()
	succession_panel.position = Vector2(380, 230)
	succession_panel.size = Vector2(460, 230)
	hud.add_child(succession_panel)
	succession_panel.visible = false
	var succession_layout := VBoxContainer.new()
	succession_panel.add_child(succession_layout)
	var succession_title := Label.new()
	succession_title.text = "HÜKÜMDARIN VEFATI — HANEDAN KARARI"
	succession_title.add_theme_font_size_override("font_size", 20)
	succession_layout.add_child(succession_title)
	var succession_info := Label.new()
	succession_info.text = "Yeni hükümdarla devam edebilir veya seferi bitirebilirsin."
	succession_layout.add_child(succession_info)
	var heir_button := Button.new()
	heir_button.text = "Varisle devam et"
	heir_button.pressed.connect(_continue_as_heir)
	succession_layout.add_child(heir_button)
	var end_button := Button.new()
	end_button.text = "Seferi bitir"
	end_button.pressed.connect(_end_campaign)
	succession_layout.add_child(end_button)
	var columns := HBoxContainer.new()
	map_panel.add_child(columns)
	var left := VBoxContainer.new()
	left.custom_minimum_size.x = 420
	columns.add_child(left)
	var heading := Label.new()
	heading.text = "1444 EYALET HARİTASI"
	heading.add_theme_font_size_override("font_size", 20)
	left.add_child(heading)
	var map_view := Control.new()
	map_view.name = "ProvinceMap"
	map_view.custom_minimum_size = Vector2(410, 440)
	map_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_view.set_script(load("res://scripts/province_map.gd"))
	map_view.call("set_provinces", provinces)
	map_view.connect("province_clicked", _select_province_by_id)
	left.add_child(map_view)
	var right := VBoxContainer.new()
	columns.add_child(right)
	map_detail = Label.new()
	map_detail.custom_minimum_size = Vector2(250, 180)
	map_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(map_detail)
	var tax_button := Button.new()
	tax_button.text = "Vergi tahsil et"
	tax_button.pressed.connect(_collect_tax)
	right.add_child(tax_button)
	var recruit_province_button := Button.new()
	recruit_province_button.text = "Bu eyalete 500 asker al (250 altın)"
	recruit_province_button.pressed.connect(_recruit_selected_province)
	right.add_child(recruit_province_button)
	var close_button := Button.new()
	close_button.text = "Haritayı kapat"
	close_button.pressed.connect(_toggle_map)
	right.add_child(close_button)
	if not provinces.is_empty():
		_select_province(provinces[0])
	_build_campaign_setup(hud)
	if is_mobile:
		_build_touch_controls(hud)

func _load_historical_catalog() -> void:
	var file := FileAccess.open("res://data/historical_seed.json", FileAccess.READ)
	if file == null:
		push_error("Tarihî katalog bulunamadı.")
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		historical_realms = parsed.get("realms", [])
		historical_rulers = parsed.get("rulers", [])

func _build_campaign_setup(hud: CanvasLayer) -> void:
	var panel := PanelContainer.new()
	panel.name = "CampaignSetup"
	panel.position = Vector2(300, 120)
	panel.size = Vector2(600, 480)
	hud.add_child(panel)
	var layout := VBoxContainer.new()
	panel.add_child(layout)
	var title := Label.new()
	title.text = "SEFERİNİ BELİRLE"
	title.add_theme_font_size_override("font_size", 24)
	layout.add_child(title)
	var note := Label.new()
	note.text = "Çevrimdışı tarihî katalog • Hükümdarın saltanat yılları seçilebilir."
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(note)
	var realm_label := Label.new()
	realm_label.text = "Medeniyet / Devlet"
	layout.add_child(realm_label)
	var realm := OptionButton.new()
	realm.name = "RealmChoice"
	for realm_data in historical_realms:
		realm.add_item(str(realm_data.get("name", "Bilinmeyen devlet")))
		realm.set_item_metadata(realm.item_count - 1, str(realm_data.get("id", "")))
	layout.add_child(realm)
	var ruler_label := Label.new()
	ruler_label.text = "Hükümdar"
	layout.add_child(ruler_label)
	var ruler := OptionButton.new()
	ruler.name = "RulerChoice"
	layout.add_child(ruler)
	var year_label := Label.new()
	year_label.text = "Başlangıç yılı"
	layout.add_child(year_label)
	var year := SpinBox.new()
	year.name = "YearChoice"
	year.step = 1
	year.allow_greater = false
	year.allow_lesser = false
	layout.add_child(year)
	var dynasty := CheckBox.new()
	dynasty.name = "DynastyChoice"
	dynasty.text = "Hanedan değişiminde oyuna devam et"
	dynasty.button_pressed = true
	layout.add_child(dynasty)
	var map_note := Label.new()
	map_note.text = "Not: 3D eyalet haritası şu anda 1444 Anadolu ve Balkanlar verisini kullanır."
	map_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(map_note)
	var start := Button.new()
	start.text = "Seferi başlat"
	start.pressed.connect(_apply_campaign_setup.bind(panel))
	layout.add_child(start)
	realm.item_selected.connect(_on_realm_selected.bind(realm, ruler, year))
	ruler.item_selected.connect(_on_ruler_selected.bind(ruler, year))
	if realm.item_count > 0:
		realm.select(0)
		_refresh_ruler_choices(realm, ruler, year)
	panel.visible = false

func _apply_campaign_setup(panel: PanelContainer) -> void:
	var realm_choice := panel.find_child("RealmChoice", true, false) as OptionButton
	var ruler_choice := panel.find_child("RulerChoice", true, false) as OptionButton
	var year_choice := panel.find_child("YearChoice", true, false) as SpinBox
	var dynasty_choice := panel.find_child("DynastyChoice", true, false) as CheckBox
	if realm_choice == null or ruler_choice == null or year_choice == null or dynasty_choice == null:
		_show_notice("Sefer ayarları yüklenemedi.")
		return
	if realm_choice.selected < 0 or ruler_choice.selected < 0:
		_show_notice("Önce devlet ve hükümdar seç.")
		return
	var realm_id := str(realm_choice.get_item_metadata(realm_choice.selected))
	var ruler_data: Dictionary = ruler_choice.get_item_metadata(ruler_choice.selected)
	var ruler_id := str(ruler_data.get("id", ""))
	var realm_name := str(realm_choice.get_item_text(realm_choice.selected))
	var ruler_name := str(ruler_data.get("name", ruler_choice.get_item_text(ruler_choice.selected)))
	var year := int(year_choice.value)
	var new_relations: Dictionary = {}
	for realm_data in historical_realms:
		var other_id := str(realm_data.get("id", ""))
		if other_id != realm_id:
			new_relations[str(realm_data.get("name", "Komşu devlet"))] = 0
	SaveManager.campaign = {
		"date": "%04d-01-01" % year,
		"realm": realm_name,
		"realm_id": realm_id,
		"ruler": ruler_name,
		"ruler_id": ruler_id,
		"treasury": 1200,
		"stability": 75,
		"army": 2500,
		"trade_income": 0,
		"trade_agreements": 0,
		"alliances": 0,
		"treaties": {},
		"relations": new_relations,
		"dynasty_continuation": dynasty_choice.button_pressed,
		"succession_resolved": false,
		"ended": false,
		"battles_won": 0,
		"battles_lost": 0,
		"sieges_won": 0,
		"tax_collected": {}
	}
	panel.visible = false
	if succession_panel:
		succession_panel.visible = false
	_refresh_campaign_hud()
	_save_game()
	if not is_mobile:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_realm_selected(_index: int, realm: OptionButton, ruler: OptionButton, year: SpinBox) -> void:
	_refresh_ruler_choices(realm, ruler, year)

func _refresh_ruler_choices(realm: OptionButton, ruler: OptionButton, year: SpinBox) -> void:
	ruler.clear()
	if realm.selected < 0:
		return
	var realm_id := str(realm.get_item_metadata(realm.selected))
	for ruler_data in historical_rulers:
		if str(ruler_data.get("realm", "")) == realm_id:
			ruler.add_item(str(ruler_data.get("name", "Bilinmeyen hükümdar")))
			ruler.set_item_metadata(ruler.item_count - 1, ruler_data)
	if ruler.item_count > 0:
		ruler.select(0)
		_apply_ruler_year_range(ruler, year)

func _on_ruler_selected(_index: int, ruler: OptionButton, year: SpinBox) -> void:
	_apply_ruler_year_range(ruler, year)

func _apply_ruler_year_range(ruler: OptionButton, year: SpinBox) -> void:
	if ruler.selected < 0:
		return
	var ruler_data: Dictionary = ruler.get_item_metadata(ruler.selected)
	var reign_start := int(ruler_data.get("reign_start", 1300))
	var reign_end := int(ruler_data.get("reign_end", reign_start))
	year.min_value = reign_start
	year.max_value = maxi(reign_start, reign_end)
	year.value = clampi(int(year.value), reign_start, maxi(reign_start, reign_end))

func _show_campaign_setup() -> void:
	var panel := $HUD/CampaignSetup
	panel.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _build_touch_controls(hud: CanvasLayer) -> void:
	var controls := HBoxContainer.new()
	controls.name = "TouchControls"
	controls.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	controls.position = Vector2(-360, -180)
	controls.size = Vector2(340, 150)
	controls.add_theme_constant_override("separation", 8)
	hud.add_child(controls)
	var directions := GridContainer.new()
	directions.columns = 3
	controls.add_child(directions)
	var blank1 := Control.new()
	directions.add_child(blank1)
	_add_hold_button(directions, "▲", "move_forward")
	var blank2 := Control.new()
	directions.add_child(blank2)
	_add_hold_button(directions, "◀", "move_left")
	_add_hold_button(directions, "▼", "move_back")
	_add_hold_button(directions, "▶", "move_right")
	var actions := VBoxContainer.new()
	controls.add_child(actions)
	_add_hold_button(actions, "Koş", "sprint")
	var interact := Button.new()
	interact.text = "Etkileşim"
	interact.custom_minimum_size = Vector2(105, 55)
	interact.pressed.connect(_mobile_interact)
	actions.add_child(interact)

func _add_hold_button(parent: Control, caption: String, action: String) -> void:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(62, 55)
	button.button_down.connect(func(): Input.action_press(action))
	button.button_up.connect(func(): Input.action_release(action))
	parent.add_child(button)

func _mobile_interact() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_method("mobile_interact"):
		player.mobile_interact()

func _open_world_map() -> void:
	SaveManager.save_campaign()
	get_tree().change_scene_to_file("res://scenes/world_map.tscn")

func _build_palace_details() -> void:
	var stone := _palace_material(Color("#8b7960"))
	var dark_stone := _palace_material(Color("#40372e"))
	var gold := _palace_material(Color("#b58a43"), 0.48)
	var red := _palace_material(Color("#762e2c"))
	var carpet := _palace_material(Color("#6d272b"))
	var columns := [-8.0, 8.0]
	for x in columns:
		for z in [-7.0, -2.0, 3.0, 8.0]:
			_palace_cylinder("Mermer Sütun", Vector3(x, 3.0, z), 0.42, 6.0, stone)
			_palace_box("Sütun Kaidesi", Vector3(x, 0.28, z), Vector3(1.05, 0.55, 1.05), gold)
			_palace_box("Sütun Başlığı", Vector3(x, 6.12, z), Vector3(1.05, 0.35, 1.05), gold)
	for z in [-7.5, -2.5, 2.5, 7.5]:
		_palace_box("Duvar Meşalesi", Vector3(-9.2, 3.0, z), Vector3(0.35, 0.75, 0.35), gold)
		var flame := OmniLight3D.new()
		flame.light_color = Color("#ffad55")
		flame.light_energy = 0.65
		flame.omni_range = 5.0
		flame.position = Vector3(-8.9, 3.7, z)
		add_child(flame)
		_palace_box("Duvar Meşalesi", Vector3(9.2, 3.0, z), Vector3(0.35, 0.75, 0.35), gold)
		var flame_right := OmniLight3D.new()
		flame_right.light_color = Color("#ffad55")
		flame_right.light_energy = 0.65
		flame_right.omni_range = 5.0
		flame_right.position = Vector3(8.9, 3.7, z)
		add_child(flame_right)
	_palace_box("Ana Halı", Vector3(0, 0.025, 1.0), Vector3(8.5, 0.045, 11.0), carpet)
	_palace_box("Halı Altın Bordür", Vector3(0, 0.055, 1.0), Vector3(8.0, 0.025, 10.5), gold)
	_palace_box("Halı İç Desen", Vector3(0, 0.075, 1.0), Vector3(7.55, 0.02, 10.0), carpet)
	_palace_box("Elçi Görüşme Masası", Vector3(4.0, 0.8, 2.0), Vector3(3.0, 0.22, 1.8), dark_stone)
	for x in [2.8, 5.2]:
		for z in [1.4, 2.6]:
			_palace_box("Masa Ayağı", Vector3(x, 0.4, z), Vector3(0.22, 0.8, 0.22), gold)
	for z in [-9.0, 9.0]:
		_palace_box("Duvar Sancağı", Vector3(0, 4.5, z), Vector3(2.2, 3.0, 0.12), red)
		_palace_box("Sancak Direği", Vector3(0, 6.1, z), Vector3(2.8, 0.12, 0.12), gold)
	_palace_cylinder("Avize Zinciri", Vector3(0, 6.2, 0), 0.08, 1.2, gold)
	_palace_cylinder("Avize Gövdesi", Vector3(0, 5.55, 0), 0.75, 0.22, gold)
	for i in range(8):
		var angle := TAU * float(i) / 8.0
		var candle_pos := Vector3(cos(angle) * 1.15, 5.45, sin(angle) * 1.15)
		_palace_cylinder("Avize Kolu", candle_pos, 0.07, 0.65, gold)
		var glow := OmniLight3D.new()
		glow.light_color = Color("#ffd18a")
		glow.light_energy = 0.35
		glow.omni_range = 3.0
		glow.position = candle_pos + Vector3(0, 0.35, 0)
		add_child(glow)
	_palace_box("Taht Sol Kol", Vector3(-1.25, 1.4, -8.0), Vector3(0.35, 1.5, 1.3), gold)
	_palace_box("Taht Sağ Kol", Vector3(1.25, 1.4, -8.0), Vector3(0.35, 1.5, 1.3), gold)
	_palace_box("Taht Sırtlığı", Vector3(0, 2.6, -8.55), Vector3(2.4, 0.25, 0.25), gold)
	var ambient := OmniLight3D.new()
	ambient.light_color = Color("#e7bd82")
	ambient.light_energy = 0.45
	ambient.omni_range = 18.0
	ambient.position = Vector3(0, 5.5, 0)
	add_child(ambient)

func _build_courtyard_details() -> void:
	var path_material := _palace_material(Color("#b6a17b"))
	var grass_material := _palace_material(Color("#435b3b"))
	var fountain_material := _palace_material(Color("#687d82"), 0.35)
	var tree_material := _palace_material(Color("#355b38"))
	var gold := _palace_material(Color("#b58a43"), 0.48)
	_palace_box("Avlu Taş Yolu", Vector3(0, 0.02, 37), Vector3(4.2, 0.06, 22), path_material)
	_palace_box("Avlu Çimliği Sol", Vector3(-9.0, 0.015, 37), Vector3(12.0, 0.04, 18), grass_material)
	_palace_box("Avlu Çimliği Sağ", Vector3(9.0, 0.015, 37), Vector3(12.0, 0.04, 18), grass_material)
	_palace_cylinder("Mermer Havuz", Vector3(0, 0.25, 37), 2.5, 0.5, fountain_material)
	_palace_cylinder("Havuz İç Suyu", Vector3(0, 0.51, 37), 2.0, 0.04, _palace_material(Color("#477d91"), 0.2))
	_palace_cylinder("Fıskiye Kaidesi", Vector3(0, 0.9, 37), 0.35, 0.75, gold)
	for x in [-13.0, -8.0, 8.0, 13.0]:
		for z in [30.0, 43.0]:
			_palace_cylinder("Servi Ağacı Gövdesi", Vector3(x, 1.1, z), 0.28, 2.2, _palace_material(Color("#594331")))
			var crown := MeshInstance3D.new()
			var crown_mesh := SphereMesh.new()
			crown_mesh.radius = 1.15
			crown_mesh.height = 2.3
			crown.mesh = crown_mesh
			crown.position = Vector3(x, 2.8, z)
			crown.material_override = tree_material
			$Room.add_child(crown)
	for x in [-5.5, 5.5]:
		_palace_box("Avlu Fener Kaidesi", Vector3(x, 0.45, 34), Vector3(0.65, 0.9, 0.65), gold)
		var lamp := OmniLight3D.new()
		lamp.light_color = Color("#ffd08b")
		lamp.light_energy = 0.8
		lamp.omni_range = 7.0
		lamp.position = Vector3(x, 2.0, 34)
		add_child(lamp)

func _palace_material(color: Color, metallic := 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.78
	material.metallic = metallic
	return material

func _palace_box(label: String, pos: Vector3, dimensions: Vector3, material: Material) -> void:
	var instance := MeshInstance3D.new()
	instance.name = label
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	instance.mesh = mesh
	instance.position = pos
	instance.material_override = material
	$Room.add_child(instance)

func _palace_cylinder(label: String, pos: Vector3, radius: float, height: float, material: Material) -> void:
	var instance := MeshInstance3D.new()
	instance.name = label
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius * 1.12
	mesh.height = height
	mesh.radial_segments = 12
	instance.mesh = mesh
	instance.position = pos
	instance.material_override = material
	$Room.add_child(instance)

func _toggle_map() -> void:
	map_panel.visible = not map_panel.visible
	if not is_mobile:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if map_panel.visible else Input.MOUSE_MODE_CAPTURED

func _select_province_by_id(province_id: String) -> void:
	for province in provinces:
		if str(province.get("id", "")) == province_id:
			_select_province(province)
			return

func _select_province(province: Dictionary) -> void:
	selected_province = province
	map_detail.text = "%s\n\nNüfus: %s\nVergi geliri: %s altın/gün\nErzak: %s\nGarnizon: %s\nArazi: %s" % [
		province.get("name", "?"), str(province.get("population", 0)),
		str(province.get("tax", 0)), str(province.get("food", 0)),
		str(province.get("garrison", 0)), str(province.get("terrain", "?"))
	]

func _collect_tax() -> void:
	if selected_province.is_empty():
		return
	var realm_id := str(SaveManager.campaign.get("realm_id", "ottoman"))
	if str(selected_province.get("realm", "")) != realm_id:
		_show_notice("Bu eyalet senin devletine bağlı değil. Vergi tahsil edemezsin.")
		return
	var current_date := str(SaveManager.campaign.get("date", "1444-01-01"))
	var month_key := current_date.substr(0, 7)
	var province_id := str(selected_province.get("id", ""))
	var collected: Dictionary = SaveManager.campaign.get("tax_collected", {})
	var province_months: Dictionary = collected.get(province_id, {})
	if str(province_months.get(month_key, "")) == "yes":
		_show_notice("Bu eyaletin vergisi bu ay zaten tahsil edildi.")
		return
	var income := int(selected_province.get("tax", 0))
	if income <= 0:
		return
	SaveManager.campaign["treasury"] = int(SaveManager.campaign.get("treasury", 0)) + income
	province_months[month_key] = "yes"
	collected[province_id] = province_months
	SaveManager.campaign["tax_collected"] = collected
	_refresh_campaign_hud()
	map_detail.text += "\n\nAylık vergi tahsil edildi: %d altın." % income
	_save_game()

func _advance_day() -> void:
	if bool(SaveManager.campaign.get("ended", false)):
		return
	var current := Time.get_datetime_dict_from_datetime_string(str(SaveManager.campaign.get("date", "1444-11-10")), false)
	var stamp := Time.get_unix_time_from_datetime_dict(current) + 86400
	var next_date := Time.get_datetime_dict_from_unix_time(stamp)
	SaveManager.campaign["date"] = "%04d-%02d-%02d" % [next_date.year, next_date.month, next_date.day]
	var daily_income := 10
	var realm_id := str(SaveManager.campaign.get("realm_id", "ottoman"))
	for province in provinces:
		if str(province.get("realm", "")) == realm_id:
			daily_income += int(province.get("tax", 0))
	daily_income += int(SaveManager.campaign.get("trade_income", 0))
	SaveManager.campaign["treasury"] = int(SaveManager.campaign.get("treasury", 0)) + daily_income
	_refresh_campaign_hud()
	_check_succession()

func _advance_month() -> void:
	if bool(SaveManager.campaign.get("ended", false)):
		return
	for i in range(30):
		_advance_day()
	var army_size := int(SaveManager.campaign.get("army", 2500))
	var wages := int(ceil(float(army_size) / 100.0)) * 30
	SaveManager.campaign["treasury"] = int(SaveManager.campaign.get("treasury", 0)) - wages
	var stability := int(SaveManager.campaign.get("stability", 75))
	if int(SaveManager.campaign.get("treasury", 0)) < 0:
		SaveManager.campaign["stability"] = maxi(0, stability - 5)
		SaveManager.campaign["treasury"] = 0
	_refresh_campaign_hud()
	_save_game()

func _diplomacy_partner() -> String:
	var partners := {
		"ottoman": "Bizans İmparatorluğu",
		"byzantine": "Osmanlı İmparatorluğu",
		"hungary": "Osmanlı İmparatorluğu",
		"mamluk": "Osmanlı İmparatorluğu",
		"france": "İngiltere Krallığı",
		"england": "Fransa Krallığı",
		"timurid": "Ming Hanedanı",
		"ming": "Timurlu İmparatorluğu"
	}
	return str(partners.get(str(SaveManager.campaign.get("realm_id", "ottoman")), "Komşu Devlet"))

func _open_diplomacy() -> void:
	var partner := _diplomacy_partner()
	var relations: Dictionary = SaveManager.campaign.get("relations", {})
	var treaties: Dictionary = SaveManager.campaign.get("treaties", {})
	var relation := int(relations.get(partner, 0))
	var active := treaties.get(partner, {})
	var summary := "Muhatap: %s\\nİlişkiler: %d / 100\\nMevcut anlaşmalar: %s" % [
		partner, relation, ", ".join(active.keys()) if active is Dictionary and not active.is_empty() else "Yok"
	]
	open_ambassador_dialogue("DİPLOMASİ DİVANI", summary, [
		"İlişkileri geliştir", "Ticaret anlaşması öner", "Saldırmazlık paktı öner",
		"Askerî ittifak iste", "Görüşmeyi bitir"
	])

func _recruit_army() -> void:
	var cost := 250
	var treasury := int(SaveManager.campaign.get("treasury", 0))
	if treasury < cost:
		_show_notice("Hazine yetersiz. 500 asker için 250 altın gerekiyor.")
		return
	SaveManager.campaign["treasury"] = treasury - cost
	SaveManager.campaign["army"] = int(SaveManager.campaign.get("army", 2500)) + 500
	_refresh_campaign_hud()
	_save_game()
	_show_notice("500 asker orduya katıldı. Aylık asker maaşı her 100 asker için 30 altın.")

func _recruit_selected_province() -> void:
	if selected_province.is_empty():
		_show_notice("Önce bir eyalet seç.")
		return
	var cost := 250
	var treasury := int(SaveManager.campaign.get("treasury", 0))
	if treasury < cost:
		_show_notice("Hazine yetersiz.")
		return
	SaveManager.campaign["treasury"] = treasury - cost
	for i in range(provinces.size()):
		if str(provinces[i].get("id", "")) == str(selected_province.get("id", "")):
			provinces[i]["garrison"] = int(provinces[i].get("garrison", 0)) + 500
			selected_province = provinces[i]
			break
	_refresh_campaign_hud()
	_select_province(selected_province)
	_save_game()
	_show_notice("Seçili eyaletin garnizonuna 500 asker eklendi.")

func _show_notice(message: String) -> void:
	open_ambassador_dialogue("DEVLET BİLDİRİMİ", message, ["Tamam"])

func _show_succession() -> void:
	if succession_panel:
		succession_panel.visible = true
		if not is_mobile:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _check_succession() -> void:
	if bool(SaveManager.campaign.get("ended", false)):
		return
	var ruler_id := str(SaveManager.campaign.get("ruler_id", ""))
	var ruler_data: Dictionary = {}
	for entry in historical_rulers:
		if str(entry.get("id", "")) == ruler_id:
			ruler_data = entry
			break
	if ruler_data.is_empty():
		return
	var end_year := int(ruler_data.get("reign_end", 9999))
	var current_year := int(str(SaveManager.campaign.get("date", "1444-01-01")).substr(0, 4))
	if current_year >= end_year and not bool(SaveManager.campaign.get("succession_resolved", false)):
		_show_succession()

func _continue_as_heir() -> void:
	if not bool(SaveManager.campaign.get("dynasty_continuation", true)):
		_end_campaign()
		return
	var ruler_id := str(SaveManager.campaign.get("ruler_id", ""))
	var current_ruler: Dictionary = {}
	for entry in historical_rulers:
		if str(entry.get("id", "")) == ruler_id:
			current_ruler = entry
			break
	var successor_id := str(current_ruler.get("successor", ""))
	var successor: Dictionary = {}
	for entry in historical_rulers:
		if str(entry.get("id", "")) == successor_id:
			successor = entry
			break
	if successor.is_empty():
		_end_campaign()
		return
	SaveManager.campaign["ruler"] = str(successor.get("name", "Varis"))
	SaveManager.campaign["ruler_id"] = successor_id
	SaveManager.campaign["succession_resolved"] = false
	for realm_data in historical_realms:
		if str(realm_data.get("id", "")) == str(successor.get("realm", "")):
			SaveManager.campaign["realm"] = str(realm_data.get("name", ""))
			SaveManager.campaign["realm_id"] = str(realm_data.get("id", ""))
			break
	succession_panel.visible = false
	_refresh_campaign_hud()
	_save_game()


func _end_campaign() -> void:
	SaveManager.campaign["ended"] = true
	succession_panel.visible = false
	if date_label:
		date_label.text = "Sefer sona erdi — hanedan devam etmiyor."
	_save_game()

func _refresh_campaign_hud() -> void:
	if date_label:
		date_label.text = "Tarih: %s  |  %s / %s" % [str(SaveManager.campaign.get("date", "")), str(SaveManager.campaign.get("realm", "")), str(SaveManager.campaign.get("ruler", ""))]
	if treasury_label:
		treasury_label.text = "   Hazine: %s altın" % str(SaveManager.campaign.get("treasury", 0))
	if army_label:
		army_label.text = "   Ordu: %s" % str(SaveManager.campaign.get("army", 2500))

func _save_game() -> void:
	if SaveManager.save_campaign():
		date_label.text = "Kayıt başarılı — %s" % str(SaveManager.campaign.get("date", ""))

func _open_battlefield() -> void:
	SaveManager.save_campaign()
	get_tree().change_scene_to_file("res://scenes/battlefield.tscn")

func open_ambassador_dialogue(name: String, opening: String, options: Array[String]) -> void:
	dialogue_title.text = name
	dialogue_text.text = opening
	for child in dialogue_choices.get_children():
		child.queue_free()
	for option in options:
		var button := Button.new()
		button.text = option
		button.pressed.connect(_on_diplomatic_choice.bind(option))
		dialogue_choices.add_child(button)
	(dialogue_layer.get_meta("panel") as Control).visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_diplomatic_choice(option: String) -> void:
	var partner := _diplomacy_partner()
	var relations: Dictionary = SaveManager.campaign.get("relations", {})
	var treaties: Dictionary = SaveManager.campaign.get("treaties", {})
	var current_relation := int(relations.get(partner, 0))
	var partner_treaties: Dictionary = treaties.get(partner, {})
	match option:
		"İlişkileri geliştir":
			var diplomatic_cost := 40
			var treasury := int(SaveManager.campaign.get("treasury", 0))
			if treasury < diplomatic_cost:
				dialogue_text.text = "Elçi: Diplomatik heyetin masraflarını karşılayacak kadar altınınız yok."
				return
			SaveManager.campaign["treasury"] = treasury - diplomatic_cost
			relations[partner] = mini(100, current_relation + 15)
			dialogue_text.text = "Elçi: Hediyeleriniz ve iyi niyet mesajınız kabul edildi. %s ile ilişkiler 15 puan iyileşti." % partner
		"Ticaret anlaşması öner":
			if bool(partner_treaties.get("trade", false)):
				dialogue_text.text = "Elçi: İki devlet arasında zaten yürürlükte bir ticaret anlaşması var."
				return
			if current_relation < 10:
				dialogue_text.text = "Elçi: İlişkilerimiz yeterince iyi değil. Önce diplomatik bağları güçlendirin."
				return
			partner_treaties["trade"] = true
			relations[partner] = mini(100, current_relation + 5)
			SaveManager.campaign["trade_income"] = int(SaveManager.campaign.get("trade_income", 0)) + 8
			SaveManager.campaign["trade_agreements"] = int(SaveManager.campaign.get("trade_agreements", 0)) + 1
			dialogue_text.text = "Elçi: Ticaret anlaşması imzalandı. Günlük hazine geliriniz 8 altın artacak."
		"Saldırmazlık paktı öner":
			if bool(partner_treaties.get("non_aggression", false)):
				dialogue_text.text = "Elçi: Saldırmazlık paktımız zaten yürürlükte."
				return
			if current_relation < 0:
				dialogue_text.text = "Elçi: Düşmanlık ortamında böyle bir pakt imzalayamayız."
				return
			partner_treaties["non_aggression"] = true
			relations[partner] = mini(100, current_relation + 10)
			SaveManager.campaign["stability"] = mini(100, int(SaveManager.campaign.get("stability", 75)) + 2)
			dialogue_text.text = "Elçi: Saldırmazlık paktı imzalandı. Devlet istikrarınız 2 puan arttı."
		"Askerî ittifak iste":
			if bool(partner_treaties.get("alliance", false)):
				dialogue_text.text = "Elçi: Zaten askerî müttefikiz."
				return
			if current_relation < 40:
				dialogue_text.text = "Elçi: Askerî ittifak için ilişkiler en az 40 olmalı. Şu an: %d." % current_relation
				return
			partner_treaties["alliance"] = true
			relations[partner] = mini(100, current_relation + 10)
			SaveManager.campaign["alliances"] = int(SaveManager.campaign.get("alliances", 0)) + 1
			dialogue_text.text = "Elçi: Askerî ittifak antlaşması imzalandı."
		_:
			(dialogue_layer.get_meta("panel") as Control).visible = false
			if not is_mobile:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			return
	treaties[partner] = partner_treaties
	SaveManager.campaign["relations"] = relations
	SaveManager.campaign["treaties"] = treaties
	_refresh_campaign_hud()
	_save_game()
