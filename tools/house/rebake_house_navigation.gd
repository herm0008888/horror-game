extends SceneTree
func _initialize():call_deferred("run")
func strip(n):
 for c in n.get_children():strip(c)
 n.set_script(null)
func own(n,target):
 for c in n.get_children():c.owner=target;own(c,target)
func run():
 var h=load("res://scenes/horror/house_layout.tscn").instantiate();strip(h);root.add_child(h)
 var data=NavigationMeshSourceGeometryData3D.new()
 for c in h.find_children("*","CollisionShape3D",true,false):
  if c.disabled or not c.get_parent() is StaticBody3D:continue
  if c.shape is BoxShape3D:
   var mesh=BoxMesh.new();mesh.size=c.shape.size;data.add_mesh(mesh,c.global_transform)
  elif c.shape is ConvexPolygonShape3D:
   var p=c.shape.points
   if p.size()==8:data.add_faces(PackedVector3Array([p[1],p[3],p[5],p[3],p[7],p[5],p[5],p[3],p[1],p[5],p[7],p[3]]),c.global_transform)
 var nav=NavigationMesh.new();nav.cell_size=.08;nav.cell_height=.04;nav.agent_radius=.34;nav.agent_height=2.04;nav.agent_max_climb=.24;nav.agent_max_slope=48;nav.region_min_size=1;nav.region_merge_size=4
 NavigationServer3D.bake_from_source_geometry_data(nav,data)
 var n=NavigationRegion3D.new();n.name="HouseNavigation";n.navigation_mesh=nav;var pack=PackedScene.new();pack.pack(n);ResourceSaver.save(pack,"res://scenes/horror/house_navigation.tscn");n.free()
 print("NAVIGATION_POLYGONS ",nav.get_polygon_count())
 var fixtures=Node3D.new();fixtures.name="CeilingFixtures";root.add_child(fixtures)
 var scene=load("res://assets/house_library/caged_hanging_light/caged_hanging_light.gltf")
 var emission=StandardMaterial3D.new();emission.albedo_color=Color(1,.86,.59);emission.emission_enabled=true;emission.emission=Color(1,.7,.35);emission.emission_energy_multiplier=2
 var cordmat=StandardMaterial3D.new();cordmat.albedo_color=Color(.06,.055,.04);cordmat.roughness=1
 for light in h.get_node("Lighting/HorrorLights").get_children():
  if "Window" in str(light.name) or "Moon" in str(light.name):continue
  var model=scene.instantiate();model.name=str(light.name)+"Fixture";fixtures.add_child(model)
  var b=AABB();var first=true
  for m in model.find_children("*","MeshInstance3D",true,false):
   var a=m.global_transform*m.get_aabb();b=a if first else b.merge(a);first=false
  var factor=.48/b.size.y;model.scale*=factor;model.position=light.position-Vector3(b.get_center().x,b.position.y+.09,b.get_center().z)*factor
  var bulb=MeshInstance3D.new();bulb.name=str(light.name)+"Bulb";var sphere=SphereMesh.new();sphere.radius=.035;sphere.height=.07;bulb.mesh=sphere;bulb.material_override=emission;bulb.position=light.position+Vector3.UP*.10;fixtures.add_child(bulb)
  var top=light.position.y+.44;var ceiling=floorf((light.position.y+.4)/3.4)*3.4+3.2
  if ceiling>top:
   var cord=MeshInstance3D.new();cord.name=str(light.name)+"Cable";var cylinder=CylinderMesh.new();cylinder.top_radius=.008;cylinder.bottom_radius=.008;cylinder.height=ceiling-top;cylinder.radial_segments=6;cord.mesh=cylinder;cord.material_override=cordmat;cord.position=Vector3(light.position.x,(ceiling+top)*.5,light.position.z);fixtures.add_child(cord)
 own(fixtures,fixtures);pack=PackedScene.new();pack.pack(fixtures);ResourceSaver.save(pack,"res://scenes/horror/ceiling_fixtures.tscn");fixtures.free();h.free();quit()
