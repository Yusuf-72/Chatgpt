extends StaticBody3D
class_name AmbassadorNPC

@export var ambassador_name := "Bizans Elçisi"
@export_multiline var opening_line := "Hükümdarım, devletlerimiz arasındaki meseleleri görüşmek üzere huzurunuza çıktım."
@export var diplomatic_options: Array[String] = [
	"Ticaret anlaşması öner",
	"Barış ve dostluk teklif et",
	"Askerî ittifak görüş",
	"Görüşmeyi bitir"
]

func _ready() -> void:
	var robe := StandardMaterial3D.new()
	robe.albedo_color = Color("#4c2925")
	robe.roughness = 0.92
	var skin := StandardMaterial3D.new()
	skin.albedo_color = Color("#b77d59")
	skin.roughness = 0.95
	var turban := StandardMaterial3D.new()
	turban.albedo_color = Color("#d4b36d")
	turban.metallic = 0.12
	var sash := StandardMaterial3D.new()
	sash.albedo_color = Color("#8b252b")
	var body := get_node_or_null("Visual") as MeshInstance3D
	if body:
		body.scale = Vector3(1.0, 0.86, 1.0)
		body.material_override = robe
	_add_sphere("Head", Vector3(0, 0.93, 0), 0.23, skin)
	_add_sphere("Turban", Vector3(0, 1.15, 0), 0.29, turban)
	_add_box("Sash", Vector3(0, 0.32, -0.365), Vector3(0.55, 0.13, 0.08), sash)
	_add_box("Shoulder Mantle", Vector3(0, 0.58, 0), Vector3(0.82, 0.2, 0.48), robe)

func _add_sphere(label: String, pos: Vector3, radius: float, material: Material) -> void:
	var visual := MeshInstance3D.new()
	visual.name = label
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	visual.mesh = mesh
	visual.position = pos
	visual.material_override = material
	add_child(visual)

func _add_box(label: String, pos: Vector3, dimensions: Vector3, material: Material) -> void:
	var visual := MeshInstance3D.new()
	visual.name = label
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	visual.mesh = mesh
	visual.position = pos
	visual.material_override = material
	add_child(visual)

func interact() -> void:
	var palace := get_tree().current_scene
	if palace.has_method("open_ambassador_dialogue"):
		palace.open_ambassador_dialogue(ambassador_name, opening_line, diplomatic_options)
