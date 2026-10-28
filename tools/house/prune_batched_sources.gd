extends SceneTree
## Stage-only cleanup after visual batches have been saved. Collision nodes are never touched.
func _initialize(): call_deferred("run")
func run():
	var removed:=0
	for path in DirAccess.get_files_at("res://scenes/horror"):
		if not path.ends_with(".tscn") or not (path.begins_with("upper_") or path.begins_with("ground_") or path.begins_with("basement_") or path=="stone_workshop_decor.tscn"): continue
		var target="res://scenes/horror/"+path
		var scene=load(target).instantiate()
		var changed=false
		for prop in scene.get_children():
			if prop.get_script()!=null or prop.scene_file_path.contains("/furniture/"): continue
			if prop.find_children("StaticBatch*","MeshInstance3D",true,false).is_empty(): continue
			if not prop.find_children("*","AnimationPlayer",true,false).is_empty(): continue
			for mesh in prop.find_children("*","MeshInstance3D",true,false):
				if mesh.visible or mesh.skin or mesh.get_script()!=null: continue
				# Every selected node is an invisible source that already has a saved visual batch.
				mesh.get_parent().remove_child(mesh)
				mesh.free()
				removed+=1
				changed=true
		if changed:
			var pack=PackedScene.new()
			pack.pack(scene)
			ResourceSaver.save(pack,target)
		scene.free()
	print("BATCH_SOURCE_NODES_REMOVED ",removed)
	quit()
