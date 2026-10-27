extends SceneTree
func _initialize() -> void: call_deferred("run")
func bounds(node: Node, transform: Transform3D, result: Array[AABB]) -> void:
	var t:=transform
	if node is Node3D: t=transform*node.transform
	if node is MeshInstance3D: result.append(t*node.get_aabb())
	for child in node.get_children(): bounds(child,t,result)
func run() -> void:
	var scene: Node3D=load("res://scenes/horror/basement_ruined_workshop.tscn").instantiate()
	for node in scene.get_children():
		if node.get_meta("asset_id","")=="unused": continue
		if not str(node.name).begins_with("CrossPeinHammer") and not str(node.name).begins_with("HandsawWood"): continue
		var model: Node3D=node.get_node("Model")
		model.rotation.z+=PI/2
		var boxes: Array[AABB]=[]
		bounds(model,Transform3D.IDENTITY,boxes)
		var b:=boxes[0]
		for box in boxes: b=b.merge(box)
		model.position-=Vector3(b.get_center().x,b.position.y,b.get_center().z)
	var packed:=PackedScene.new()
	packed.pack(scene)
	ResourceSaver.save(packed,"res://scenes/horror/basement_ruined_workshop.tscn")
	scene.free()
	quit()
