extends SceneTree
var scene: Node3D
var player: CharacterBody3D
var failures := 0
func _initialize() -> void:
	Engine.max_fps=60
	call_deferred("run")
func check(ok: bool, title: String) -> void:
	print("PASS " if ok else "FAIL ",title," @ ",player.position)
	if not ok: failures+=1
func frames(n: int) -> void:
	for i in range(n): await physics_frame
func place(pos: Vector3) -> void:
	player.position=pos
	player.rotation=Vector3.ZERO
	player.velocity=Vector3.ZERO
	await frames(4)
func walk(action: String, n: int) -> void:
	Input.action_press(action)
	await frames(n)
	Input.action_release(action)
	await frames(3)
func ray(a: Vector3,b: Vector3) -> bool:
	var query := PhysicsRayQueryParameters3D.create(a,b)
	query.exclude=[player.get_rid()]
	return not scene.get_world_3d().direct_space_state.intersect_ray(query).is_empty()
func run() -> void:
	scene=load("res://scenes/horror/house_layout.tscn").instantiate()
	root.add_child(scene)
	player=scene.get_node("Player")
	await frames(10)
	check(absf(player.position.y)<0.1,"Spawn supported")
	await place(Vector3(0.95,0.05,11.2))
	await walk("move_forward",112)
	check(player.position.y>1.6 and player.position.y<1.85,"Main stair reaches turning landing")
	await walk("move_right",42)
	await walk("move_back",112)
	check(player.position.y>3.3 and player.position.z>10.5,"Main U stair reaches upper landing")
	await walk("move_right",50)
	check(player.position.x>4.4 and player.position.y>3.3,"Main landing opens to shared gallery")
	await place(Vector3(3.05,3.45,11.2))
	await walk("move_forward",112)
	await walk("move_left",42)
	await walk("move_back",112)
	check(player.position.y<0.1,"Main U stair descends both flights")
	await place(Vector3(15.05,0.05,5.2))
	await walk("move_forward",112)
	await walk("move_left",42)
	await walk("move_back",112)
	check(player.position.y>3.3 and player.position.z>4.5,"Back U stair reaches upper landing")
	await walk("move_left",50)
	check(player.position.x<11.6 and player.position.y>3.3,"Back stair opens to shared lobby")
	check(ray(Vector3(10,4.5,2),Vector3(7.5,4.5,2)),"Bathroom west wall enclosed")
	check(ray(Vector3(10,4.5,2),Vector3(12.5,4.5,2)),"Bathroom east wall enclosed")
	check(ray(Vector3(10,4.5,2),Vector3(10,4.5,-0.5)),"Bathroom north wall enclosed")
	check(ray(Vector3(8.5,4.5,2),Vector3(8.5,4.5,4.5)),"Bathroom south wall beside door")
	check(not ray(Vector3(10,4.5,2),Vector3(10,4.5,5)),"Bathroom single doorway accessible from lobby")
	check(ray(Vector3(2,4.5,7),Vector3(2,4.5,5)),"Bedroom separated from stair by full wall")
	await place(Vector3(5,3.45,11.3))
	await walk("move_right",40)
	await walk("move_forward",106)
	await walk("move_right",60)
	await walk("move_forward",18)
	check(player.position.z<5.5 and player.position.x>9.5,"Bent landing connects both stairs without crossing bedrooms")
	# Secret passages and the new start sequence are covered by test_basement.gd.
	check(not ray(Vector3(6,1.2,4),Vector3(11,1.2,4)),"Eat-in kitchen is open across former dividing wall")
	check(not ray(Vector3(10,1.2,13),Vector3(15,1.2,13)),"Living room spans former lounge divisions")
	check(ray(Vector3(2,1.2,15),Vector3(6,1.2,15)),"Entrance wall prevents bypass of trap")
	check(ray(Vector3(9,1.2,7),Vector3(11,1.2,7)),"Kitchen has stepped L outline")
	print("HOME_LAYOUT_TEST ","PASS" if failures==0 else "FAIL"," failures=",failures)
	quit(0 if failures==0 else 1)
