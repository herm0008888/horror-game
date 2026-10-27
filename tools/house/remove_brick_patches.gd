extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var scene: Node3D=load("res://scenes/horror/basement_decay.tscn").instantiate()
	var removed:=0
	for node in scene.get_children():
		if str(node.name).begins_with("ExposedMasonry"):
			scene.remove_child(node)
			node.free()
			removed+=1
		elif node is MeshInstance3D and str(node.name).begins_with("FallenPlaster"):
			node.material_override=load("res://assets/house_materials/basement_wall.tres")
	var packed:=PackedScene.new()
	packed.pack(scene)
	var error:=ResourceSaver.save(packed,"res://scenes/horror/basement_decay.tscn")
	print("REMOVED_BRICK_PATCHES ",removed," save=",error)
	scene.free()
	quit(error)
