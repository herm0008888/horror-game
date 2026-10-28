extends SceneTree
func _initialize(): call_deferred("run")
func own(n: Node,target: Node):
	for c in n.get_children():
		c.owner=target
		own(c,target)
func run():
	var e=load("res://scenes/horror/visitation.tscn").instantiate()
	var s: Skeleton3D=e.find_skeleton(e.get_node("Figure"))
	var attachment=BoneAttachment3D.new()
	attachment.name="RecessedSockets"
	attachment.bone_name="Head"
	s.add_child(attachment)
	var head=s.get_bone_global_rest(s.find_bone("Head"))
	var black=StandardMaterial3D.new()
	black.albedo_color=Color(.004,.003,.002)
	black.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	for bone in ["EyeLeft","EyeRight"]:
		var sphere=MeshInstance3D.new()
		sphere.mesh=SphereMesh.new()
		sphere.mesh.radius=.12
		sphere.mesh.height=.24
		sphere.material_override=black
		var center=s.get_bone_global_rest(s.find_bone(bone)).origin+Vector3(0,0,.035)
		sphere.transform=Transform3D(head.basis.inverse()*Basis.from_scale(Vector3(1,1,.14)),head.affine_inverse()*center)
		attachment.add_child(sphere)
	var throat=MeshInstance3D.new()
	throat.mesh=SphereMesh.new()
	throat.mesh.radius=.27
	throat.mesh.height=.54
	throat.material_override=black
	throat.transform=Transform3D(head.basis.inverse()*Basis.from_scale(Vector3(.8,1,.30)),head.affine_inverse()*Vector3(0,1.48,.08))
	attachment.add_child(throat)
	for m in e.get_node("Figure").find_children("*","MeshInstance3D",true,false):
		if not m.mesh or m.mesh.get_surface_count()!=8: continue
		var enamel=StandardMaterial3D.new()
		enamel.albedo_texture=load("res://assets/horror/visitation_visceral_teeth_albedo.png")
		enamel.albedo_color=Color(.43,.40,.31)
		enamel.roughness=.92
		enamel.metallic_specular=.10
		m.set_surface_override_material(5,enamel)
		var eyes=StandardMaterial3D.new()
		eyes.albedo_texture=load("res://assets/horror/visitation_visceral_eye_albedo.png")
		eyes.albedo_color=Color(.55,.56,.51)
		eyes.roughness=.6
		eyes.metallic_specular=.13
		m.set_surface_override_material(3,eyes)
	attachment.owner=e
	own(attachment,e)
	var pack=PackedScene.new()
	pack.pack(e)
	ResourceSaver.save(pack,"res://scenes/horror/visitation.tscn")
	e.free()
	quit()
