extends StaticBody3D
@export var required_hits:=2
@export var fragment_material: Material
var hits:=0
var broken:=false
var pieces: Array[RigidBody3D]=[]
var wall_material: StandardMaterial3D
func _ready():
	var original=get_node_or_null("Mesh") as MeshInstance3D
	if original==null or not original.mesh is BoxMesh:return
	var size=original.mesh.size
	wall_material=load("res://assets/house_materials/basement_wall.tres" if global_position.y< -1.0 else "res://assets/house_materials/wall_wood.tres")
	fragment_material=wall_material
	for child in get_children():
		if child is Node3D and not child is CollisionShape3D:child.hide()
	build_pieces(size)
	original.show()
	original.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
func point(p: Vector2,depth: float,thin_x: bool) -> Vector3:
	return Vector3(-depth,p.y,p.x) if thin_x else Vector3(p.x,p.y,depth)
func triangle(tool: SurfaceTool,a: Vector3,b: Vector3,c: Vector3,normal: Vector3):
	for vertex in [a,b,c]:
		tool.set_normal(normal)
		tool.add_vertex(vertex)
func build_pieces(size: Vector3):
	var thin_x=size.x<size.z
	var width=size.z if thin_x else size.x
	var depth=size.x if thin_x else size.z
	var rng=RandomNumberGenerator.new();rng.seed=hash(str(name))
	var grid: Array[Vector2]=[]
	for row in range(5):
		for column in range(4):
			var p=Vector2((float(column)/3-.5)*width,(float(row)/4-.5)*size.y)
			if column>0 and column<3:p.x+=rng.randf_range(-.10,.10)*width/3
			if row>0 and row<4:p.y+=rng.randf_range(-.12,.12)*size.y/4
			grid.append(p)
	for row in range(4):
		for column in range(3):
			var poly=PackedVector2Array([grid[row*4+column],grid[row*4+column+1],grid[(row+1)*4+column+1],grid[(row+1)*4+column]])
			var center=Vector2.ZERO
			for p in poly:center+=p*.25
			# Shared crack boundaries; only a hairline gap separates intact pieces.
			for i in range(poly.size()):poly[i]=center+(poly[i]-center)*.994
			var origin=point(center,0,thin_x)
			var normal=Vector3.LEFT if thin_x else Vector3.BACK
			var front=PackedVector3Array();var back=PackedVector3Array()
			for p in poly:
				front.append(point(p,depth*.5,thin_x)-origin)
				back.append(point(p,-depth*.5,thin_x)-origin)
			var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
			var indices=Geometry2D.triangulate_polygon(poly)
			for i in range(0,indices.size(),3):
				var a=indices[i];var b=indices[i+1];var c=indices[i+2]
				triangle(st,front[a],front[c],front[b],normal)
				triangle(st,back[a],back[b],back[c],-normal)
			for i in range(poly.size()):
				var j=(i+1)%poly.size()
				var side=(front[j]-front[i]).cross(normal).normalized()
				triangle(st,front[i],front[j],back[i],side)
				triangle(st,front[j],back[j],back[i],side)
			var body=RigidBody3D.new();body.name="WallPiece%d"%pieces.size()
			body.freeze=true;body.collision_layer=0;body.collision_mask=0
			body.mass=clampf(width*size.y*depth*300/12,.35,3.0)
			body.position=origin
			var mesh=MeshInstance3D.new();mesh.name="Mesh";mesh.mesh=st.commit();mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			var material=wall_material.duplicate() as StandardMaterial3D
			material.cull_mode=BaseMaterial3D.CULL_DISABLED
			mesh.material_override=material
			body.add_child(mesh)
			var collision=CollisionShape3D.new()
			var shape=ConvexPolygonShape3D.new();shape.points=front+back;shape.margin=.002
			collision.shape=shape;body.add_child(collision)
			add_child(body);pieces.append(body)
func fixed_material(body: RigidBody3D) -> StandardMaterial3D:
	var material=body.get_node("Mesh").material_override.duplicate() as StandardMaterial3D
	# Continue the wall's texture phase, then carry it with the physical piece.
	material.uv1_world_triplanar=false
	material.uv1_offset+=body.global_position*material.uv1_scale
	if material.next_pass is ShaderMaterial:
		material.next_pass=material.next_pass.duplicate()
		material.next_pass.set_shader_parameter("use_rest_coordinates",true)
		material.next_pass.set_shader_parameter("rest_transform",body.global_transform)
	return material
func strike(impulse: Vector3) -> void:
	if broken:return
	hits+=1
	if hits<required_hits:
		for piece in pieces:
			piece.get_node("Mesh").scale=Vector3.ONE*.992
		return
	broken=true
	get_node("Mesh").hide()
	collision_layer=0
	var collision=get_node_or_null("Collision")
	if collision:collision.set_deferred("disabled",true)
	get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFERRED,"render_budget","invalidate_visibility")
	var rng=RandomNumberGenerator.new();rng.seed=hash(str(name))
	var world=get_tree().current_scene if get_tree().current_scene else get_parent()
	for piece in pieces:
		piece.get_node("Mesh").material_override=fixed_material(piece)
		piece.get_node("Mesh").cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		piece.reparent(world,true)
		piece.collision_layer=16;piece.collision_mask=17
		piece.freeze=false;piece.sleeping=false
		piece.apply_central_impulse((impulse.normalized()*2.2+Vector3.UP*.12)*piece.mass)
		piece.apply_torque_impulse(Vector3(rng.randf_range(-.3,.3),rng.randf_range(-.3,.3),rng.randf_range(-.3,.3))*piece.mass)
	get_tree().call_group("horror_listener","hear_noise",global_position,12.0)
