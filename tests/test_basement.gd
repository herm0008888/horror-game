extends SceneTree
var house: Node3D
var player: CharacterBody3D
var failures := 0
func _initialize() -> void:
	Engine.max_fps=60
	call_deferred("run")
func frames(n: int) -> void:
	for i in range(n): await physics_frame
func check(ok: bool,title: String) -> void:
	print("PASS " if ok else "FAIL ",title," @ ",player.position)
	if not ok: failures+=1
func place(pos: Vector3) -> void:
	Input.action_release("crouch")
	player.position=pos
	player.rotation=Vector3.ZERO
	player.velocity=Vector3.ZERO
	await frames(4)
func walk(action: String,n: int) -> void:
	Input.action_press(action)
	await frames(n)
	Input.action_release(action)
	await frames(3)
func interact() -> void:
	var event := InputEventAction.new()
	event.action="interact"
	event.pressed=true
	Input.parse_input_event(event)
	await frames(1)
	event=InputEventAction.new()
	event.action="interact"
	event.pressed=false
	Input.parse_input_event(event)
func run() -> void:
	house=load("res://scenes/horror/house_layout.tscn").instantiate()
	root.add_child(house)
	player=house.get_node("Player")
	await frames(165)
	check(house.intro_done and player.position.y < -3.3 and player.position.x>4 and player.position.x<8,"Entrance hatch drops player into cell")
	check(house.hatch_collision.disabled,"Hatch stays open after the fall")
	await walk("move_forward",65)
	check(player.position.z>12.2,"Locked cell bars block normal exit")
	await place(Vector3(5,-3.35,15.2))
	await walk("move_left",30)
	check(player.position.x>4.2,"Cell corner requires crouching")
	Input.action_press("crouch")
	await walk("move_left",80)
	check(player.position.x<3.2,"Broken lower wall escapes cell into separate store")
	Input.action_release("crouch")
	await walk("move_forward",80)
	check(player.position.z<12,"Cell escape connects to rest of basement")
	await place(Vector3(0.95,-3.35,11.2))
	await walk("move_forward",112)
	await walk("move_right",42)
	await walk("move_back",112)
	check(player.position.y>-0.1 and player.position.z>10.5,"Basement U stair reaches house")
	await place(Vector3(0.95,0.05,11.2))
	await walk("move_forward",112)
	await walk("move_right",42)
	await walk("move_back",112)
	check(player.position.y>3.3,"Main staircase still reaches second floor")
	await place(Vector3(2,0.05,0.75))
	await walk("move_right",25)
	check(player.position.x<2.4,"Cupboard tunnel blocks standing player")
	Input.action_press("crouch")
	await walk("move_right",150)
	check(player.position.x>5.6,"Cupboard tunnel crosses study/kitchen wall")
	await walk("move_left",150)
	check(player.position.x<2.5,"Cupboard tunnel works in reverse")
	await place(Vector3(15.5,3.45,10.3))
	await walk("move_back",50)
	check(player.position.z<11.9,"Bedroom breach requires crouching")
	Input.action_press("crouch")
	await walk("move_back",60)
	check(player.position.z>12.6,"Behind wardrobe passage reaches different bedroom")
	await walk("move_forward",60)
	check(player.position.z<12,"Bedroom passage works in reverse")
	await place(Vector3(15.3,-3.35,2.8))
	await walk("move_right",25)
	check(player.position.x<16,"Foundation tunnel requires crouching")
	Input.action_press("crouch")
	await walk("move_right",40)
	check(player.position.x>16.4,"Foundation tunnel entrance accessible")
	await walk("move_back",456)
	await walk("move_left",60)
	check(player.position.x<15.5 and player.position.z>13.7,"Full tunnel traverses to south storage room")
	await place(Vector3(10.6,-3.35,2.1))
	await interact()
	await frames(130)
	check(player.position.y>-0.1 and player.position.x>11.3 and not house.climbing,"E climbs concealed ladder into kitchen")
	await interact()
	await frames(130)
	check(player.position.y<-3.3 and not house.climbing,"E returns down ladder into basement")
	house.restart_intro()
	await frames(165)
	check(house.intro_done and player.position.y<-3.3 and absf(player.position.x-6)<0.2 and absf(player.position.z-14)<0.2,"Intro can be replayed")
	print("BASEMENT_TEST ","PASS" if failures==0 else "FAIL"," failures=",failures)
	quit(0 if failures==0 else 1)
