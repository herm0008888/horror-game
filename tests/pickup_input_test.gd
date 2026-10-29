extends SceneTree
var failures:=0
func check(ok: bool,label: String):
 print("PASS " if ok else "FAIL ",label)
 if not ok:failures+=1
func _initialize():call_deferred("run")
func run():
 Engine.max_fps=0
 root.size=Vector2i(1024,720);root.content_scale_size=Vector2i.ZERO
 var h=load("res://scenes/horror/house_layout.tscn").instantiate();root.add_child(h)
 var p=h.get_node("Player");p.set_physics_process(false);h.get_node("Visitation").set_physics_process(false)
 var controller=p.get_node("PlayerFeel/PickupController");controller.set_physics_process(false)
 var motion=p.get_node("PlayerFeel/CameraMotion");motion.set_process(false)
 var ring=h.get_node("InteractionCrosshair/Screen/PickupRing")
 var service=h.get_node("PropInteraction");var tool=p.get_node("ToolController")
 for frame in range(5):await physics_frame
 check(not ring.visible,"Ring hidden when idle")
 var cabinet=h.get_node("GroundFloorDressing/LivingRoom/PaintedWoodenCabinet")
 var door=cabinet.find_children("*","AnimatableBody3D",true,false)[0]
 var center: Vector3=service.world_bounds(door).get_center()
 var front: Vector3=cabinet.global_basis.z.normalized()
 p.position=center+front*.9-Vector3.UP*1.6;p.camera.global_position=center+front*.9;p.camera.look_at(center)
 controller.begin()
 check(controller.holding and controller.duration>=.95,"Big furniture requires a longer hold")
 controller.advance(.25)
 check(ring.visible and ring.progress>0 and ring.progress<1 and tool.grabbed==null,"White ring fills while holding; no early pickup")
 var release:=InputEventAction.new();release.action="interact";release.pressed=false
 controller._unhandled_input(release)
 check(not ring.visible and door.opened and tool.grabbed==null,"Short E opens storage and clears ring")
 door.set_open(false,true)
 for frame in range(3):await physics_frame
 controller.begin();controller.advance(.3)
 p.camera.rotate_y(PI)
 controller.advance(.1)
 check(not controller.holding and not ring.visible,"Looking away cancels hold")
 p.camera.look_at(center)
 controller.begin();controller.advance(1.3)
 check(is_instance_valid(tool.grabbed) and not ring.visible,"Completed hold lifts whole cabinet and hides ring")
 tool.drop_grabbed()
 p.camera.position=Vector3(0,1.6,0);p.camera.rotation=Vector3.ZERO;p.pitch=0
 p.position=Vector3(6,.02,10.8);p.velocity=Vector3(2,-1,1)
 for frame in range(30):
  p.move_and_slide();motion._process(1.0/60)
  await physics_frame
 check(absf(p.camera.rotation.z)>.001 and absf(p.camera.position.x)>.0001,"Camera has strafe lean and walking motion")
 var old: Transform3D=p.camera.transform;p.caught=true;motion._process(.1)
 check(p.camera.transform.is_equal_approx(old),"Camera motion yields to jumpscare")
 var particles=h.get_node("HouseParticles")
 check(particles.get_child_count()==7 and particles.get_node("BoilerVapour").emitting,"Saved dust and smoke emitters active")
 check(particles.get_node("HallDust").amount==80,"Particle counts kept bounded")
 print("PLAYER_FEEL_TEST failures=",failures)
 h.free();quit(1 if failures else 0)
