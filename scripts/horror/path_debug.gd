extends MeshInstance3D
var line := ImmediateMesh.new()
var material := StandardMaterial3D.new()
var timer: float = 0.0
func _ready() -> void:
	top_level = true
	global_transform = Transform3D.IDENTITY
	mesh = line
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0.2,1.0,0.12)
	material.no_depth_test = true
func _process(delta: float) -> void:
	timer -= delta
	if timer > 0: return
	timer = 0.06
	line.clear_surfaces()
	var enemy: Node3D = get_parent()
	if enemy.route_path.is_empty(): return
	line.surface_begin(Mesh.PRIMITIVE_LINES,material)
	var previous: Vector3 = enemy.global_position + Vector3.UP*0.08
	for point in enemy.route_path:
		var next: Vector3 = point + Vector3.UP*0.08
		line.surface_add_vertex(previous)
		line.surface_add_vertex(next)
		previous = next
	line.surface_end()
