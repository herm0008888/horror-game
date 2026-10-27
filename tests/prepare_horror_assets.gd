extends SceneTree
var materials: Dictionary = {}
var white: ImageTexture
var psx: Shader
func _initialize() -> void: call_deferred("run")
func convert_materials(node: Node) -> void:
	if node is MeshInstance3D:
		for surface in range(node.mesh.get_surface_count()):
			var old := node.get_active_material(surface) as BaseMaterial3D
			if not old: continue
			var key := old.get_instance_id()
			if not materials.has(key):
				var replacement := ShaderMaterial.new()
				replacement.shader = load("res://assets/horror/reference_face.gdshader") if (old.resource_name.begins_with("ReferenceFace") or old.resource_name.begins_with("OriginalVisage")) else psx
				if old.resource_name.begins_with("Skin"):
					replacement.shader = load("res://assets/horror/corpse_skin.gdshader")
				if old.resource_name.begins_with("MouthInterior"):
					replacement.shader = load("res://assets/horror/mouth_interior.gdshader")
				replacement.set_shader_parameter("surface_texture", old.albedo_texture if old.albedo_texture else white)
				replacement.set_shader_parameter("tint", old.albedo_color)
				if old.resource_name.begins_with("Eyes"):
					replacement.set_shader_parameter("emission_strength", 0.18)
				if (old.resource_name.begins_with("ReferenceFaceEyes") or old.resource_name.begins_with("OriginalVisageEyes")):
					replacement.set_shader_parameter("surface_roughness", 0.40)
					replacement.set_shader_parameter("surface_specular", 0.18)
				var custom_materials := {
					"VisceralFace":"visceral_face", "WetEye":"visceral_eye", "WetTongue":"visceral_tongue",
					"RottenTeeth":"visceral_teeth", "FreshBlood":"visceral_blood", "VisceralBody":"visceral_body", "VisceralCloth":"visceral_cloth"
				}
				for prefix in custom_materials:
					if old.resource_name.begins_with(prefix):
						replacement = load("res://assets/horror/materials/%s.tres" % custom_materials[prefix]).duplicate()
				materials[key] = replacement
			node.set_surface_override_material(surface, materials[key])
	for child in node.get_children(): convert_materials(child)
func run() -> void:
	var image := Image.create(2, 2, false, Image.FORMAT_RGB8)
	image.fill(Color.WHITE)
	white = ImageTexture.create_from_image(image)
	psx = load("res://assets/horror/psx.gdshader")
	var figure := load("res://assets/horror/visitation.glb").instantiate() as Node3D
	root.add_child(figure)
	convert_materials(figure)
	var packed := PackedScene.new()
	packed.pack(figure)
	ResourceSaver.save(packed, "res://scenes/horror/figure_visual.tscn")
	print("PSX_FIGURE_READY ", materials.size(), " materials")
	quit()


