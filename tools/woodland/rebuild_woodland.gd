extends "res://tools/woodland/build_base.gd"
var trunk_positions: Array[Vector3]=[]
func clear_part(label: String):
 var n=scene.get_node_or_null(label)
 if n:n.free()
func terrain_y(x: float,z: float)->float:
 var x0:=floorf(x/2)*2;var z0:=floorf(z/2)*2;var u: float=(x-x0)/2;var v: float=(z-z0)/2
 if u+v<=1:return height(x0,z0)*(1-u-v)+height(x0+2,z0)*u+height(x0,z0+2)*v
 return height(x0+2,z0+2)*(u+v-1)+height(x0,z0+2)*(1-u)+height(x0+2,z0)*(1-v)
func pbr(folder: String,tint:=Color.WHITE)->StandardMaterial3D:
 var m:=material(folder+"/Diffuse.jpg",tint)
 m.normal_enabled=true;m.normal_texture=load(folder+"/nor_gl.jpg");m.normal_scale=.6
 m.roughness_texture=load(folder+"/Rough.jpg");return m
func make_window(p: Vector3,angle: float,wood: Material,dark: Material,parent: Node,boarded: bool):
 var w:=group_node("DeepWindowSurround",parent);w.position=p;w.rotation.y=angle
 for x in [-.98,.98]:box("SideTrim",Vector3(x,0,0),Vector3(.15,1.65,.2),wood,w)
 box("DripLintel",Vector3(0,.79,.03),Vector3(2.18,.15,.28),wood,w)
 box("DeepSill",Vector3(0,-.73,.1),Vector3(2.16,.13,.39),wood,w)
 box("Mullion",Vector3(0,0,.02),Vector3(.055,1.35,.1),wood,w)
 box("Transom",Vector3(0,0,.02),Vector3(1.8,.055,.1),wood,w)
 for x in [-1.23,1.23]:
  var shutter:=box("LooseShutter",Vector3(x,-.02,-.01),Vector3(.4,1.45,.08),dark,w)
  shutter.rotation.y=x*.12;shutter.rotation.z=rng.randf_range(-.055,.055)
 if boarded:
  for i in range(2):
   var board:=box("SplitWindowBoard",Vector3(.1,-.27+i*.5,.14),Vector3(2.08,.18,.065),wood,w)
   board.rotation.z=-.17+i*.37
func run():
 rng.seed=90461
 scene=load("res://scenes/horror/abandoned_exterior.tscn").instantiate();root.add_child(scene);scene.set_process(false)
 for name in ["ForestTrees","BrokenPathTurningRight","AbandonedFenceAndDebris"]:clear_part(name)
 var forest:=group_node("DenseFirForest",scene)
 var mature:=load("res://assets/exterior/mature_fir.glb") as PackedScene
 # Irregular staggered planting, several deep layers, with a readable path corridor.
 for ix in range(-10,23):
  for iz in range(-7,28):
   var x:=ix*2.6+rng.randf_range(-.8,.8);var z:=iz*2.6+rng.randf_range(-.8,.8)
   if x> -3 and x<19 and z> -3 and z<20:continue
   if z>16 and z<32 and absf(x-6)<2.7:continue
   if x>4 and x<42 and absf(z-29)<2.5:continue
   if rng.randf()<.20:continue
   var tree:=mature.instantiate();tree.name="MatureFir_%03d"%trunk_positions.size();own(tree,forest)
   tree.position=Vector3(x,terrain_y(x,z),z);tree.rotation.y=rng.randf_range(-PI,PI)
   var scale_y:=rng.randf_range(.72,1.23);tree.scale=Vector3(scale_y*1.08,scale_y,scale_y*1.08)
   trunk_positions.append(tree.position)
   for mesh in tree.find_children("*","MeshInstance3D",true,false):mesh.visibility_range_end=62;mesh.visibility_range_end_margin=6;mesh.lod_bias=.55
   var body:=StaticBody3D.new();body.name="SolidTrunk";own(body,tree)
   var c:=CollisionShape3D.new();var shape:=CylinderShape3D.new();shape.radius=.48;shape.height=3.6;c.shape=shape;c.position.y=1.7;own(c,body)
 var saplings:=group_node("YoungTreesAndDeadfall",scene)
 var small:=load("res://assets/exterior/woodland_tree.glb") as PackedScene
 for i in range(58):
  var p:=trunk_positions[rng.randi_range(0,trunk_positions.size()-1)]+Vector3(1.2,0,.7)
  var sapling:=small.instantiate();sapling.name="Understory%02d"%i;own(sapling,saplings)
  sapling.position=Vector3(p.x,terrain_y(p.x,p.z),p.z);sapling.rotation.y=rng.randf()*TAU;sapling.scale=Vector3.ONE*rng.randf_range(.4,.8)
  for mesh in sapling.find_children("*","MeshInstance3D",true,false):mesh.visibility_range_end=32;mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 # Multi-texture ground uses fixed mesh UVs and physically lit normals.
 var ground:=ShaderMaterial.new();ground.shader=load("res://assets/exterior/woodland_ground.gdshader")
 ground.set_shader_parameter("leaves",load("res://assets/exterior/forest_ground_04/Diffuse.jpg"));ground.set_shader_parameter("earth",load("res://assets/exterior/brown_mud_rocks_01/Diffuse.jpg"))
 ground.set_shader_parameter("leaf_normal",load("res://assets/exterior/forest_ground_04/nor_gl.jpg"));ground.set_shader_parameter("earth_normal",load("res://assets/exterior/brown_mud_rocks_01/nor_gl.jpg"))
 scene.get_node("UnevenForestGround/ForestFloor").material_override=ground
 var path:=group_node("WornEarthAndGravelPath",scene)
 var pathmat:=ShaderMaterial.new();pathmat.shader=load("res://assets/exterior/woodland_path.gdshader")
 pathmat.set_shader_parameter("ground_map",load("res://assets/exterior/brown_mud_rocks_01/Diffuse.jpg"));pathmat.set_shader_parameter("normal_map",load("res://assets/exterior/brown_mud_rocks_01/nor_gl.jpg"))
 var centers: Array[Vector2]=[]
 for i in range(23):centers.append(Vector2(6+sin(i*.15)*.18,17+i*.5))
 for i in range(13):
  var t:=i*PI/24;centers.append(Vector2(8-2*cos(t),28+2*sin(t)))
 for i in range(65):centers.append(Vector2(8+i*.5,30+sin(i*.11)*.35))
 var verts:=PackedVector3Array();var uv:=PackedVector2Array()
 for i in range(centers.size()-1):
  var a:=centers[i];var b:=centers[i+1];var tangent: Vector2=(b-a).normalized();var side:=Vector2(-tangent.y,tangent.x)
  var width:=1.0+sin(i*.7)*.13
  var points=[a-side*width,a+side*width,b-side*width,b+side*width]
  for idx in [0,2,1,1,2,3]:
   var p: Vector2=points[idx];verts.append(Vector3(p.x,terrain_y(p.x,p.y)+.028,p.y));uv.append(p/1.8)
 var mesh:=surface(verts,uv,pathmat);ResourceSaver.save(mesh,"res://assets/exterior/worn_path.res")
 var mi:=MeshInstance3D.new();mi.name="ContinuousGravelAndMud";mi.mesh=mesh;own(mi,path)
 var wood:=pbr("res://assets/house_library/wood_peeling_paint_weathered",Color(.62,.62,.55))
 wood.uv1_triplanar=true;wood.uv1_scale=Vector3(.65,.65,.65)
 var darkwood:=pbr("res://assets/house_library/wood_planks_dirt",Color(.5,.47,.4));darkwood.uv1_triplanar=true;darkwood.uv1_scale=Vector3(.5,.5,.5)
 var stone:=load("res://assets/house_materials/basement_wall_decay.tres")
 # Wall strips match existing exterior wall segments so windows and doors stay clear.
 var facade:=group_node("WeatherboardFacade",scene)
 var house=load("res://scenes/horror/house_layout.tscn").instantiate()
 for node in house.get_children():
  if not node is StaticBody3D or not node.has_node("Mesh"):continue
  var m=node.get_node("Mesh")
  if not m.mesh is BoxMesh:continue
  var size: Vector3=m.mesh.size;var p: Vector3=node.position
  var front:=absf(p.z-16)<.1 and size.z>.1 and size.z<.18
  var right:=absf(p.x-16)<.1 and size.x>.1 and size.x<.18
  if not (front or right) or p.y<0 or p.y>6.6:continue
  var bottom:=p.y-size.y*.5
  var rows:=ceili(size.y/.22)
  for i in range(rows):
   var h:=minf(.22,size.y-i*.22)
   var at:=p;at.y=bottom+i*.22+h*.5
   var dims:=Vector3(size.x,h,.09) if front else Vector3(.09,h,size.z)
   if front:at.z=16.13+(i%2)*.008
   else:at.x=16.13+(i%2)*.008
   box("OverlappingWeatherboard",at,dims,wood,facade)
 house.free()
 var details:=group_node("WindowDepthGuttersAndFoundation",scene)
 for y in [1.55,4.95]:
  for x in [10.0,14.0]:make_window(Vector3(x,y,16.24),0,wood,darkwood,details,x==14 and y>3)
  for z in [8.5,13.5]:make_window(Vector3(16.24,y,z),PI*.5,wood,darkwood,details,z==13.5)
 make_window(Vector3(2,4.95,16.24),0,wood,darkwood,details,true)
 for z in [.0,16.0]:
  if z==16:
   box("StoneFoundationLeft",Vector3(2.6,-.18,z+.14),Vector3(5.15,.48,.28),stone,details)
   box("StoneFoundationRight",Vector3(11.4,-.18,z+.14),Vector3(9.2,.48,.28),stone,details)
  else:box("RearFoundation",Vector3(8,-.18,z),Vector3(16,.48,.28),stone,details)
 for x in [0.0,16.0]:box("SideFoundation",Vector3(x,-.18,8),Vector3(.28,.48,16),stone,details)
 var roofmat:=pbr("res://assets/exterior/roof_slates_02",Color(.55,.61,.6));roofmat.uv1_scale=Vector3(8,14,1)
 for n in scene.get_node("HouseRoofAndTrim").get_children():
  if str(n.name).begins_with("RoofSlope"):n.get_node("Mesh").material_override=roofmat
  if str(n.name).begins_with("ClosedGable"):n.material_override=wood
 for x in [-.65,16.65]:
  box("RainGutter",Vector3(x,6.7,8),Vector3(.15,.16,17.9),darkwood,details)
  box("DrainPipe",Vector3(x,3.1,15.5),Vector3(.12,6.1,.12),darkwood,details)
 var attic:=group_node("AtticVent",details);attic.position=Vector3(8,7.75,16.28)
 var black:=StandardMaterial3D.new();black.albedo_color=Color(.035,.04,.037);black.roughness=1
 box("Recess",Vector3.ZERO,Vector3(1.2,.85,.05),black,attic)
 for i in range(6):box("VentSlat",Vector3(0,-.38+i*.145,.04),Vector3(1.28,.075,.12),darkwood,attic)
 # A recognisable picket fence with missing boards, supported by rails.
 var fence:=group_node("BrokenPicketFence",scene)
 for segment in range(15):
  var x: float=-5+segment*2.2
  if x>2.5 and x<8.5:continue
  var z:=23.0+sin(segment*.28)*.45
  var section:=group_node("FenceSection%02d"%segment,fence);section.position=Vector3(x,terrain_y(x,z),z)
  section.rotation.z=rng.randf_range(-.045,.045)
  box("Post",Vector3(0,.62,0),Vector3(.16,1.3,.16),darkwood,section,true)
  for y in [.35,.85]:box("Rail",Vector3(1.1,y,-.035),Vector3(2.2,.12,.08),darkwood,section)
  for j in range(8):
   if rng.randf()<.2:continue
   var picket:=box("WeatheredPicket",Vector3(.17+j*.265,.59,.035),Vector3(.16,rng.randf_range(.92,1.2),.065),wood,section)
   picket.rotation.z=rng.randf_range(-.09,.09)
 # Real scanned mossy stones, seated into the terrain around trunks and path edges.
 var debris:=group_node("MossyStonesAndForestDebris",scene)
 for i in range(70):
  var p:=trunk_positions[rng.randi_range(0,trunk_positions.size()-1)]+Vector3(rng.randf_range(-1,1),0,rng.randf_range(-1,1))
  var rock=load("res://scenes/horror/decor/stone_%02d.tscn"%(1+i%6)).instantiate();rock.name="MossStone%02d"%i;own(rock,debris)
  rock.position=Vector3(p.x,terrain_y(p.x,p.z)+.03,p.z);rock.rotation.y=rng.randf()*TAU;rock.scale=Vector3.ONE*rng.randf_range(.16,.48)
  for n in rock.find_children("*","MeshInstance3D",true,false):n.visibility_range_end=38;n.lod_bias=.6
 # Keep the cinematic camera closer so the house is framed through tree trunks.
 scene.get_node("CinematicMarkers/HouseEstablishing").position=Vector3(21,2.9,32)
 scene.get_node("CinematicMarkers/HouseEstablishing").look_at(Vector3(8,3.8,10))
 scene.get_node("ColdMoon").light_energy=.24
 scene.forest_ambient=.40
 # Rebuild the coarse exterior walk area around the new actual trunk positions.
 var navmesh:=NavigationMesh.new();navmesh.cell_size=.08;navmesh.cell_height=.04
 var navverts:=PackedVector3Array()
 for x in range(-8,44):
  for z in range(16,52):
   var blocked:=false
   for p in trunk_positions:
    if Vector2(p.x-x-.5,p.z-z-.5).length()<1.0:blocked=true;break
   if z>=22 and z<=23 and not (x>=4 and x<=8):blocked=true
   if blocked:continue
   var start:=navverts.size()
   for v in [Vector2(x,z),Vector2(x+1,z),Vector2(x+1,z+1),Vector2(x,z+1)]:navverts.append(Vector3(v.x,terrain_y(v.x,v.y),v.y))
   navmesh.add_polygon(PackedInt32Array([start,start+1,start+2,start+3]))
 navmesh.vertices=navverts;scene.get_node("OutdoorNavigation").navigation_mesh=navmesh
 save_part(scene,"res://scenes/horror/abandoned_exterior.tscn")
 print("DENSE_FOREST_BUILT trees=",trunk_positions.size()," nav=",navmesh.get_polygon_count())
 quit()
