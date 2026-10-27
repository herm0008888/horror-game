extends SceneTree
var house: Node3D
var player: CharacterBody3D
var failed := 0
func _initialize() -> void:
	Engine.max_fps=60
	call_deferred("run")
func frames(n: int) -> void:
	for i in range(n): await physics_frame
func check(ok: bool, description: String) -> void:
	print("PASS " if ok else "FAIL ",description," @ ",player.position)
	if not ok: failed+=1
func place(pos: Vector3) -> void:
	player.position=pos
	player.velocity=Vector3.ZERO
	player.rotation=Vector3.ZERO
	await frames(4)
func walk(action: String,n: int) -> void:
	Input.action_press(action)
	await frames(n)
	Input.action_release(action)
	await frames(3)
func interact() -> void:
	var event:=InputEventAction.new()
	event.action="interact"
	event.pressed=true
	Input.parse_input_event(event)
	await frames(2)
	event=InputEventAction.new()
	event.action="interact"
	event.pressed=false
	Input.parse_input_event(event)
	await frames(2)
func run() -> void:
	house=load("res://scenes/horror/house_layout.tscn").instantiate()
	root.add_child(house)
	player=house.get_node("Player")
	await frames(150)
	check(house.intro_done and player.position.y < -3.3 and house.hatch_collision.disabled,"Fall opens trap into cell")
	await place(Vector3(6,0.06,12.5))
	await walk("move_right",40)
	check(player.position.x<6.55,"Right side of entrance blocked")
	await walk("move_left",65)
	check(player.position.x>5.45,"Left side of entrance blocked")
	await place(Vector3(6,0.06,12.5))
	await walk("move_back",65)
	await frames(45)
	check(player.position.y < -3.3,"Crossing without plank drops into cell")
	await place(Vector3(9,0.06,9))
	await interact()
	check(house.carrying_plank and not house.plank.visible,"E picks up plank")
	await place(Vector3(6,0.06,12.5))
	await interact()
	await frames(5)
	check(house.bridge_placed and not house.plank_collision.disabled,"E places solid plank over trap")
	await walk("move_back",65)
	check(player.position.y>-0.15 and player.position.z>15.3,"Plank supports player all the way to front door")
	await walk("move_forward",65)
	check(player.position.y>-0.15 and player.position.z<12.8,"Plank is traversable back to house")
	house.restart_intro()
	await frames(150)
	check(house.intro_done and player.position.y < -3.3 and not house.bridge_placed and house.plank.visible,"Replay resets plank and trap")
	print("BRIDGE_TEST ","PASS" if failed==0 else "FAIL"," failures=",failed)
	quit(0 if failed==0 else 1)
