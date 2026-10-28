extends SceneTree
func _initialize(): call_deferred("run")
func run():
	var h=load("res://scenes/horror/house_layout.tscn").instantiate()
	h.process_mode=Node.PROCESS_MODE_DISABLED
	root.add_child(h)
	var manager=Node.new()
	manager.name="HouseVisibility"
	manager.set_script(load("res://scripts/horror/house_visibility.gd"))
	h.add_child(manager)
	manager.owner=h
	# Save all render groups visible; the manager selects them at runtime.
	manager.enabled=false
	manager.refresh(h.get_node("Player/Camera"),true)
	manager.enabled=true
	h.process_mode=Node.PROCESS_MODE_INHERIT
	var pack=PackedScene.new()
	pack.pack(h)
	ResourceSaver.save(pack,"res://scenes/horror/house_layout.tscn")
	h.free()
	quit()
