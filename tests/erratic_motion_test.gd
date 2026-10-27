extends SceneTree
var errors: Array[String] = []
func _initialize() -> void: call_deferred("run")
func run() -> void:
	set_meta("creature_situation", 4)
	var scene := load("res://scenes/horror/test_area.tscn").instantiate() as Node3D
	root.add_child(scene)
	current_scene = scene
	for i in range(5): await physics_frame
	var player: CharacterBody3D = scene.get_node("Player")
	var enemy: CharacterBody3D = scene.get_node("Visitation")
	player.set_physics_process(false)
	enemy.set_physics_process(false)
	var skeleton: Skeleton3D = enemy.pose_skeleton
	var head: int = enemy.pose_bones["Head"]
	for fps in [30, 60, 120]:
		for hunting in [false, true]:
			var motion: Node = load("res://scripts/horror/haunted_motion.gd").new()
			var freezes := 0
			var bursts := 0
			for frame in range(fps * 8):
				motion.animate(1.0 / fps, true, hunting, enemy.figure, skeleton, enemy.pose_bones, enemy.pose_rest_rotations)
				var speed: float = motion.speed_factor(hunting)
				if speed < 0.1: freezes += 1
				if speed > 1.5: bursts += 1
				enemy.track_player_head(1.0 / fps)
				var aimed := skeleton.get_bone_pose_rotation(head)
				motion.apply_tracked_head(skeleton, enemy.pose_bones)
				if aimed.angle_to(skeleton.get_bone_pose_rotation(head)) < 0.05:
					errors.append("Gaze erased the head performance")
				if not enemy.figure.transform.is_finite(): errors.append("Invalid figure transform")
			if freezes == 0 or bursts == 0: errors.append("Missing stop/burst at %s fps" % fps)
			motion.free()
	print("ERRATIC_MOTION_TEST ", "PASS" if errors.is_empty() else errors)
	quit(0 if errors.is_empty() else 1)
