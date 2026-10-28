extends SceneTree
func _initialize():call_deferred("run")
func strip(n):
 for c in n.get_children():strip(c)
 n.set_script(null)
func own(n,target):
 for c in n.get_children():c.owner=target;own(c,target)
func box(parent,title,pos,size,mat):
 var m=MeshInstance3D.new();m.name=title;var mesh=BoxMesh.new();mesh.size=size;m.mesh=mesh;m.position=pos;m.material_override=mat;parent.add_child(m)
 var c=CollisionShape3D.new();var shape=BoxShape3D.new();shape.size=size;c.shape=shape;c.position=pos;parent.add_child(c)
func run():
 var h=load("res://scenes/horror/house_layout.tscn").instantiate();strip(h);root.add_child(h)
 # Simple blockout cupboards get a hollow interior and real hinged panels.
 var manifest=[]
 for title in ["StudyCupboard","DiningCupboard","BedroomWardrobe","KitchenCupboard"]:
  var original=h.get_node_or_null(title)
  if not original:continue
  var src=original.get_node("Mesh");var size=src.mesh.size;var mat=src.material_override
  var storage=StaticBody3D.new();storage.name=title
  box(storage,"Left",Vector3(-size.x*.5+.025,0,0),Vector3(.05,size.y,size.z),mat)
  box(storage,"Right",Vector3(size.x*.5-.025,0,0),Vector3(.05,size.y,size.z),mat)
  box(storage,"Back",Vector3(0,0,-size.z*.5+.025),Vector3(size.x,size.y,.05),mat)
  box(storage,"Top",Vector3(0,size.y*.5-.025,0),Vector3(size.x,.05,size.z),mat)
  box(storage,"Bottom",Vector3(0,-size.y*.5+.025,0),Vector3(size.x,.05,size.z),mat)
  for side in [-1,1]:
   var door=AnimatableBody3D.new();door.name="LeftDoor" if side<0 else "RightDoor";door.set_script(load("res://scripts/horror/storage_part.gd"));door.position=Vector3(side*(size.x*.5-.025),0,size.z*.5);door.open_rotation_degrees=Vector3(0,side*105,0);storage.add_child(door)
   box(door,"Panel",Vector3(-side*size.x*.25,0,0),Vector3(size.x*.5-.025,size.y-.06,.04),mat)
   var slot=Marker3D.new();slot.name="ItemSlot";storage.add_child(slot)
  storage.transform=original.transform
  own(storage,storage);var pack=PackedScene.new();pack.pack(storage);var path="res://scenes/horror/furniture/"+title.to_snake_case()+".tscn";ResourceSaver.save(pack,path);manifest.append({"scene":"res://scenes/horror/house_layout.tscn","node":title,"replacement":path});storage.free()
 var file=FileAccess.open("res://tools/house/simple_storage_manifest.json",FileAccess.WRITE);file.store_string(JSON.stringify(manifest,"  "))
 # Nav geometry is built from actual static colliders, not decorative pictures/labels.
 var geometry=NavigationMeshSourceGeometryData3D.new()
 for c in h.find_children("*","CollisionShape3D",true,false):
  if c.disabled or not c.get_parent() is StaticBody3D:continue
  if c.shape is BoxShape3D:
   var mesh=BoxMesh.new();mesh.size=c.shape.size;geometry.add_mesh(mesh,c.global_transform)
 var nav=NavigationMesh.new();nav.cell_size=.08;nav.cell_height=.04;nav.agent_radius=.26;nav.agent_height=1.75;nav.agent_max_climb=.24;nav.agent_max_slope=48;nav.region_min_size=1.0;nav.region_merge_size=4.0;nav.edge_max_length=6.0
 NavigationServer3D.bake_from_source_geometry_data(nav,geometry)
 var region=NavigationRegion3D.new();region.name="HouseNavigation";region.navigation_mesh=nav
 var pack=PackedScene.new();pack.pack(region);ResourceSaver.save(pack,"res://scenes/horror/house_navigation.tscn");region.free()
 print("NAVIGATION_BAKED polygons=",nav.get_polygon_count())
 # Physical fixtures sit at the existing light positions and retain the L toggle.
 var fixture=load("res://assets/house_library/caged_hanging_light/caged_hanging_light.gltf")
 var fixtures=Node3D.new();fixtures.name="CeilingFixtures"
 var emissive=StandardMaterial3D.new();emissive.albedo_color=Color(1,.85,.55);emissive.emission_enabled=true;emissive.emission=Color(1,.65,.27);emissive.emission_energy_multiplier=2.0
 for light in h.get_node("Lighting/HorrorLights").get_children():
  if "Window" in str(light.name) or "Moon" in str(light.name):continue
  var model=fixture.instantiate();model.name=str(light.name)+"Fixture";fixtures.add_child(model)
  var meshes=model.find_children("*","MeshInstance3D",true,false);var bounds=AABB();var first=true
  for m in meshes:
   var b=m.global_transform*m.get_aabb();bounds=b if first else bounds.merge(b);first=false
  var factor=.48/maxf(bounds.size.y,.01);model.scale*=factor;model.position=light.position-Vector3(bounds.get_center().x,bounds.position.y+.09,bounds.get_center().z)*factor
  var bulb=MeshInstance3D.new();bulb.name=str(light.name)+"Bulb";var sphere=SphereMesh.new();sphere.radius=.035;sphere.height=.07;bulb.mesh=sphere;bulb.material_override=emissive;bulb.position=light.position+Vector3.UP*.10;fixtures.add_child(bulb)
 own(fixtures,fixtures);pack=PackedScene.new();pack.pack(fixtures);ResourceSaver.save(pack,"res://scenes/horror/ceiling_fixtures.tscn");fixtures.free();h.free();quit()
