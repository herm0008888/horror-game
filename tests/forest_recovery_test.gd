extends SceneTree
var failures:=0
func check(ok: bool,label: String):
 print("PASS " if ok else "FAIL ",label)
 if not ok:failures+=1
func _initialize():call_deferred("run")
func run():
 var h=load("res://scenes/horror/house_layout.tscn").instantiate();root.add_child(h)
 var p=h.get_node("Player");p.set_physics_process(false)
 var e=h.get_node("Visitation");e.set_physics_process(false)
 var nav=h.get_node("HouseNavigation")
 for i in range(1400):
  await physics_frame
  if nav.revision>0:break
 check(nav.revision>0,"Dynamic navigation finishes")
 # Repeated blocked movement must never postpone the bake indefinitely.
 var previous: int=nav.revision
 for i in range(420):
  nav.request_update();await physics_frame
  if nav.revision>previous:break
 check(nav.revision>previous,"Repeated repath requests do not starve rebuild")
 var exterior=h.get_node("AbandonedExterior")
 check(exterior.get_node("ForestTrees").get_child_count()>35,"Forest trees authored in scene")
 check(exterior.get_node("OutdoorNavigation").navigation_mesh.get_polygon_count()>300,"Outdoor navigation present")
 var door=h.get_node("FrontDoor");door.set_open(true)
 for i in range(100):await physics_frame
 check(door.can_pass(),"Front door opens from real hinge")
 var map: RID=e.agent.get_navigation_map()
 var outside:=NavigationServer3D.map_get_path(map,Vector3(6,0,14),Vector3(15,-.1,29),true)
 check(outside.size()>1 and outside[outside.size()-1].distance_to(Vector3(15,-.1,29))<2,"Route connects front door to outdoor path")
 var service=h.get_node("PropInteraction")
 var sofa=h.get_node("GroundFloorDressing/LivingRoom/Sofa02")
 var bounds: AABB=service.world_bounds(sofa)
 p.position=Vector3(100,0,100)
 e.position=Vector3(bounds.get_center().x,bounds.end.y+.09,bounds.get_center().z)
 e.velocity=Vector3.ZERO;e.previous_position=e.position;e.hunt=99;e.last_seen=Vector3(12,0,13);e.repath=0;e.caught=false;e.set_physics_process(true)
 var escaped:=false
 for i in range(650):
  await physics_frame
  if e.global_position.y<bounds.position.y+.2:escaped=true;break
 check(escaped,"Enemy walks off furniture instead of remaining perched")
 print("RECOVERY_POSITION ",e.global_position," original_sofa_top=",bounds.end.y)
 e.set_physics_process(false)
 # Render actual runtime atmosphere without the player camera overriding it.
 for n in p.find_children("*","Node",true,false):n.set_process(false);n.set_physics_process(false)
 if h.has_node("HouseVisibility"):h.get_node("HouseVisibility").set_process(false)
 var cam=exterior.get_node("CinematicMarkers/HouseEstablishing");cam.make_current()
 var env=h.get_node("Environment").environment
 env.fog_depth_begin=14;env.fog_depth_end=70;env.fog_density=.65;env.fog_light_color=Color(.07,.10,.12)
 for i in range(8):await process_frame
 if DisplayServer.get_name()!="headless":
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("C:/Users/edu3569171/Documents/Codex/2026-10-26/v/outputs/forest-preview.png")
 print("FOREST_RECOVERY failures=",failures)
 quit(failures)
