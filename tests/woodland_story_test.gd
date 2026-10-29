extends SceneTree
var failures:=0
func check(ok: bool,label: String):
 print("PASS " if ok else "FAIL ",label)
 if not ok:failures+=1
func _initialize():call_deferred("run")
func run():
 var h=load("res://scenes/horror/house_layout.tscn").instantiate();root.add_child(h)
 var e=h.get_node("Visitation");e.set_physics_process(false)
 var p=h.get_node("Player");p.set_physics_process(false)
 var story=h.get_node("ExteriorStory")
 var outside=h.get_node("AbandonedExterior")
 for i in range(5):await physics_frame
 check(p.global_position.distance_to(outside.get_node("StoryStart").global_position)<.1,"Player starts on forest path")
 check(outside.get_node("DenseFirForest").get_child_count()>600,"Dense mature forest saved as editable nodes")
 check(outside.get_node("DenseFirForest").get_child(0).has_node("FullCrown0"),"Full textured crowns retained")
 check(outside.get_node("WindowDepthGuttersAndFoundation").get_child_count()>12,"Facade has window depth and building details")
 check(outside.get_node("EntrancePorch").has_node("CagedPorchLantern"),"Real porch lamp model")
 for i in range(1200):
  await physics_frame
  if h.get_node("HouseNavigation").revision>0:break
 var route:=NavigationServer3D.map_get_path(e.agent.get_navigation_map(),p.global_position,Vector3(6,-.1,17.5),true)
 check(route.size()>1 and route[route.size()-1].distance_to(Vector3(6,-.1,17.5))<1,"Walkable forest route leads to porch")
 p.position=Vector3(8.2,.1,23.2);story._process(.01)
 check(story.phase==1 and "skjerf" in story.caption(),"Scarf provides reason to investigate")
 p.position=Vector3(6,.1,17.5);story._process(.01)
 check(story.phase==2,"Door story cue")
 h.get_node("FrontDoor").interact()
 for i in range(90):await physics_frame
 check(h.get_node("FrontDoor").can_pass(),"Door interaction opens entrance")
 p.position=Vector3(6,.1,15.4);story._process(.01)
 check(story.phase==3,"Inside cue leads to cellar trap")
 p.position=Vector3(6,-3.3,14);story._process(.01)
 check(story.phase==4 and "ikke der" in story.caption(),"Cellar twist message")
 print("WOODLAND_STORY_TEST failures=",failures)
 quit(failures)
