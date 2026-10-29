extends SceneTree
var scene: Node3D
var rng:=RandomNumberGenerator.new()
func own(node: Node,parent: Node):
 parent.add_child(node);node.owner=scene
 return node
func group_node(label: String,parent: Node)->Node3D:
 var n:=Node3D.new();n.name=label;own(n,parent);return n
func material(path: String,tint:=Color.WHITE,scale_uv:=Vector3.ONE)->StandardMaterial3D:
 var m:=StandardMaterial3D.new();m.albedo_texture=load(path);m.albedo_color=tint;m.roughness=.95;m.uv1_scale=scale_uv
 m.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
 return m
func box(label: String,p: Vector3,size: Vector3,mat: Material,parent: Node,solid:=false)->Node3D:
 var node: Node3D=StaticBody3D.new() if solid else Node3D.new();node.name=label;own(node,parent);node.position=p
 var mesh:=BoxMesh.new();mesh.size=size;mesh.material=mat
 var mi:=MeshInstance3D.new();mi.name="Mesh";mi.mesh=mesh;own(mi,node)
 if solid:
  var c:=CollisionShape3D.new();var shape:=BoxShape3D.new();shape.size=size;c.shape=shape;own(c,node)
 return node
func height(x: float,z: float)->float:
 var distance:=maxf(maxf(-x,x-16.0),maxf(-z,z-16.0))
 var fade:=smoothstep(2.0,10.0,distance)
 return -.10+fade*(sin(x*.15+z*.08)*.65+cos(z*.21-x*.07)*.42+sin(x*.48)*sin(z*.35)*.15)
func surface(vertices: PackedVector3Array,uvs: PackedVector2Array,mat: Material)->ArrayMesh:
 var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES);st.set_material(mat)
 for i in range(vertices.size()):st.set_uv(uvs[i]);st.add_vertex(vertices[i])
 st.generate_normals();st.index();return st.commit()
func save_part(node: Node3D,path: String):
 var packed:=PackedScene.new();packed.pack(node);ResourceSaver.save(packed,path)
func _initialize():call_deferred("run")
func run():
 rng.seed=84312
 scene=Node3D.new();scene.name="AbandonedExterior";root.add_child(scene);scene.add_to_group("exterior_geometry",true)
 scene.set_script(load("res://scripts/horror/exterior_atmosphere.gd"));scene.set_process(false)
 var wood:=material("res://assets/house_library/wood_peeling_paint_weathered/Diffuse.jpg",Color(.47,.46,.4),Vector3(2,2,1))
 var roof_mat:=material("res://assets/house_library/wooden_rough_planks/Diffuse.jpg",Color(.25,.27,.27),Vector3(6,8,1))
 var ground:=material("res://assets/exterior/forest_floor.jpg",Color(.55,.56,.5))
 var path_mat:=material("res://assets/house_library/dirty_concrete/Diffuse.jpg",Color(.36,.35,.31),Vector3(1.4,1.4,1))
 var trim:=material("res://assets/house_library/wood_planks_dirt/Diffuse.jpg",Color(.27,.29,.25))
 var terrain:=group_node("UnevenForestGround",scene)
 var vertices:=PackedVector3Array();var uvs:=PackedVector2Array()
 for x in range(-24,60,2):
  for z in range(-20,72,2):
   if x>=0 and x<16 and z>=0 and z<16:continue
   for v in [Vector2(x,z),Vector2(x+2,z),Vector2(x,z+2),Vector2(x+2,z),Vector2(x+2,z+2),Vector2(x,z+2)]:
    vertices.append(Vector3(v.x,height(v.x,v.y),v.y));uvs.append(v/3.0)
 var terrain_mesh:=surface(vertices,uvs,ground)
 ResourceSaver.save(terrain_mesh,"res://assets/exterior/terrain.res")
 var mi:=MeshInstance3D.new();mi.name="ForestFloor";mi.mesh=terrain_mesh;own(mi,terrain)
 var body:=StaticBody3D.new();body.name="TerrainCollision";own(body,terrain)
 var cs:=CollisionShape3D.new();cs.shape=terrain_mesh.create_trimesh_shape();own(cs,body)
 var shell:=group_node("HouseRoofAndTrim",scene)
 # Complete pitched roof, closed gables and deep eaves above both floors.
 for side in [-1,1]:
  var roof:=box("RoofSlope"+str(side),Vector3(8+side*4.35,8.25,8),Vector3(9.4,.16,18),roof_mat,shell,true)
  roof.rotation.z=-side*.36
 for z in [-.18,16.18]:
  var vv:=PackedVector3Array([Vector3(-.3,6.7,z),Vector3(8,9.85,z),Vector3(16.3,6.7,z),Vector3(16.3,6.7,z),Vector3(8,9.85,z),Vector3(-.3,6.7,z)])
  var uu:=PackedVector2Array([Vector2(0,1),Vector2(.5,0),Vector2(1,1),Vector2(1,1),Vector2(.5,0),Vector2(0,1)])
  var g:=MeshInstance3D.new();g.name="ClosedGable"+str(int(z));g.mesh=surface(vv,uu,wood);own(g,shell)
 for x in [-.16,16.16]:
  for z in [-.16,16.16]:box("WeatheredCorner",Vector3(x,3.35,z),Vector3(.22,6.7,.22),trim,shell)
 for y in [.12,3.4,6.7]:
  for z in [-.19,16.19]:
   if y<.2:
    box("PlinthLeft",Vector3(2.65,y,z),Vector3(5.1,.22,.16),trim,shell)
    box("PlinthRight",Vector3(11.45,y,z),Vector3(9.1,.22,.16),trim,shell)
   else:box("FacadeCornice",Vector3(8,y,z),Vector3(16.5,.18,.18),trim,shell)
  for x in [-.19,16.19]:box("SideCornice",Vector3(x,y,8),Vector3(.18,.2,16.5),trim,shell)
 box("Chimney",Vector3(12.7,9.2,5),Vector3(.9,2.8,1.1),load("res://assets/house_materials/basement_wall_decay.tres"),shell,true)
 box("ChimneyCap",Vector3(12.7,10.65,5),Vector3(1.12,.18,1.32),trim,shell)
 var porch:=group_node("EntrancePorch",scene)
 box("StoneThreshold",Vector3(6,-.03,16.7),Vector3(2.5,.16,1.35),path_mat,porch,true)
 for x in [4.7,7.3]:box("PorchPost",Vector3(x,1.4,17.45),Vector3(.16,2.8,.16),trim,porch,true)
 var cover:=box("PorchRoof",Vector3(6,2.82,16.9),Vector3(3.1,.15,2.25),roof_mat,porch,true);cover.rotation.x=.12
 var lamp:=OmniLight3D.new();lamp.name="PorchWarmLight";lamp.position=Vector3(6,2.48,16.8);lamp.light_color=Color(1,.67,.37);lamp.light_energy=1.0;lamp.omni_range=5;lamp.shadow_enabled=true;own(lamp,porch)
 var bulb_mat:=StandardMaterial3D.new();bulb_mat.albedo_color=Color(.65,.4,.19);bulb_mat.emission_enabled=true;bulb_mat.emission=Color(1,.57,.24);bulb_mat.emission_energy_multiplier=1.8
 box("LanternBody",Vector3(6,2.55,16.8),Vector3(.19,.29,.19),bulb_mat,porch)
 var path:=group_node("BrokenPathTurningRight",scene)
 for i in range(29):
  var z:=17.8+minf(i,12)*.94+sin(i*.8)*.13
  var x:=6+maxf(i-12,0)*1.15+sin(i*.43)*.2
  for side in [-1,1]:
   if rng.randf()<.16:continue
   var slab:=box("CrackedPaving",Vector3(x+side*.43,height(x,z)+.035,z),Vector3(rng.randf_range(.62,.9),.07,rng.randf_range(.65,.86)),path_mat,path,true)
   slab.rotation=Vector3(rng.randf_range(-.035,.035),rng.randf_range(-.14,.14),rng.randf_range(-.035,.035))
 var trees:=group_node("ForestTrees",scene)
 var tree_scene:=load("res://assets/exterior/woodland_tree.glb") as PackedScene
 var positions: Array[Vector3]=[]
 for i in range(125):
  var x:=rng.randf_range(-20,54);var z:=rng.randf_range(-14,65)
  if x> -3 and x<19 and z> -3 and z<20:continue
  if absf(x-6)<3 and z<32 and z>16:continue
  if absf(z-29)<3 and x>3 and x<31:continue
  var p:=Vector3(x,height(x,z),z)
  var close:=false
  for previous in positions:
   if previous.distance_to(p)<3:close=true;break
  if close:continue
  positions.append(p)
  var tree:=tree_scene.instantiate();tree.name="WoodlandTree%02d"%i;own(tree,trees);tree.position=p;tree.rotation.y=rng.randf_range(-PI,PI);tree.scale=Vector3.ONE*rng.randf_range(.85,1.7)
  var trunk:=StaticBody3D.new();trunk.name="TrunkCollision";own(trunk,tree)
  var c:=CollisionShape3D.new();var shape:=CylinderShape3D.new();shape.radius=.25;shape.height=3;c.shape=shape;c.position.y=1.5;own(c,trunk)
 var debris:=group_node("AbandonedFenceAndDebris",scene)
 for i in range(19):
  if i in [5,6,7,8,12]:continue
  var x: float=-3+i*1.4;var z:=23.0
  var post:=box("RottenFencePost",Vector3(x,height(x,z)+.6,z),Vector3(.13,1.4,.13),wood,debris,true);post.rotation.z=rng.randf_range(-.16,.16)
  if i%4!=0:
   for y in [.4,.9]:box("BrokenFenceRail",Vector3(x+.65,height(x,z)+y,z),Vector3(1.3,.11,.08),trim,debris)
 # Cool moonlight and low transparent mist banks; no heavy volumetric renderer required.
 var moon:=DirectionalLight3D.new();moon.name="ColdMoon";moon.rotation_degrees=Vector3(-52,-28,0);moon.light_color=Color(.49,.61,.72);moon.light_energy=.16;moon.shadow_enabled=false;own(moon,scene)
 var mist:=group_node("LowForestMist",scene)
 var fog_shader:=load("res://assets/exterior/forest_mist.gdshader")
 var fog_material:=ShaderMaterial.new();fog_material.shader=fog_shader
 var quad:=QuadMesh.new();quad.size=Vector2(22,3.8);quad.material=fog_material
 for i in range(9):
  var fog:=MeshInstance3D.new();fog.name="MistBank%02d"%i;fog.mesh=quad;fog.position=Vector3(-8+(i%3)*21,1.1,24+floori(i/3.0)*14);fog.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;own(fog,mist)
 var nav:=NavigationRegion3D.new();nav.name="OutdoorNavigation";own(nav,scene)
 var navmesh:=NavigationMesh.new();navmesh.cell_size=.08;navmesh.cell_height=.04
 var navverts:=PackedVector3Array()
 for x in range(-8,44,2):
  for z in range(16,52,2):
   var blocked:=false
   for p in positions:
    if Vector2(p.x-x-1,p.z-z-1).length()<1.3:blocked=true;break
   if blocked:continue
   var start:=navverts.size()
   for v in [Vector2(x,z),Vector2(x+2,z),Vector2(x+2,z+2),Vector2(x,z+2)]:navverts.append(Vector3(v.x,height(v.x,v.y),v.y))
   navmesh.add_polygon(PackedInt32Array([start,start+1,start+2,start+3]))
 navmesh.vertices=navverts;nav.navigation_mesh=navmesh
 var link:=NavigationLink3D.new();link.name="FrontDoorNavigationLink";link.start_position=Vector3(6,0,15.4);link.end_position=Vector3(6,-.1,17.6);own(link,scene)
 var shots:=group_node("CinematicMarkers",scene)
 for entry in [["Doorway",Vector3(6,1.65,18.6),Vector3(6,1.5,16)],["HouseEstablishing",Vector3(25,3.6,36),Vector3(8,3.8,8)],["ForestRight",Vector3(29,1.65,30),Vector3(45,1.3,38)]]:
  var camera:=Camera3D.new();camera.name=entry[0];camera.position=entry[1];camera.fov=65;own(camera,shots);camera.look_at(entry[2]);camera.current=false
 save_part(scene,"res://scenes/horror/abandoned_exterior.tscn")
 print("EXTERIOR_BUILT trees=",positions.size()," terrain_triangles=",vertices.size()/3," nav_polygons=",navmesh.get_polygon_count())
 quit()
