extends RigidBody3D
var taken:=false
func _ready():
	# Architecture uses world projection; a moving tool needs local projection.
	for mesh in $Visual.find_children("*","MeshInstance3D",true,false):
		if not mesh.material_override is StandardMaterial3D: continue
		var material=mesh.material_override.duplicate() as StandardMaterial3D
		material.uv1_world_triplanar=false
		material.next_pass=null
		material.uv1_scale=Vector3(7,1.5,7) if material.resource_name=="floor_wood" else Vector3(5,5,5)
		mesh.material_override=material
func interact():
	if taken: return
	var p=get_tree().get_first_node_in_group("horror_player")
	if not p or not p.has_node("ToolController"): return
	if p.camera.global_position.distance_to(global_position)>2.6: return
	taken=true
	var visual=$Visual.duplicate()
	p.get_node("ToolController").equip(visual)
	queue_free()
