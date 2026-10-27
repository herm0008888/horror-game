extends Node
## Held contractions followed by violent releases, always relative to the bind pose.
@export_range(0.0, 1.0) var neck_twist: float = 0.46
@export_range(0.0, 0.5) var body_hunch: float = 0.38
@export var glitch_intensity: float = 1.0
@export_range(0.0, 0.2) var limp_depth: float = 0.09
var phase: float = 0.0
var elapsed: float = 0.0
var moving_blend: float = 0.0
var spasm_left: float = 0.0
var next_spasm: float = 0.8
var spasm_number: int = 0
var spasm: float = 0.0
var release: float = 0.0
var head_offset := Vector3.ZERO

func speed_factor(hunting: bool) -> float:
	if spasm > 0.0: return 0.06
	if release > 0.0: return 1.85 if hunting else 1.55
	var pull := pow(maxf(0.0, sin(phase)), 4.0)
	return (0.78 + pull * 0.9) if hunting else (0.48 + pull * 1.15)

func animate(delta: float, moving: bool, hunting: bool, figure: Node3D,
		skeleton: Skeleton3D, bones: Dictionary, rest: Dictionary) -> void:
	elapsed += delta
	next_spasm -= delta
	spasm_left = maxf(0.0, spasm_left - delta)
	if next_spasm <= 0.0:
		spasm_number += 1
		spasm_left = 0.38 if hunting else 0.48
		# Unequal intervals prevent a predictable metronome-like walk.
		next_spasm = (1.05 if hunting else 1.8) + fposmod(float(spasm_number) * 1.618, 1.0) * 1.4
	spasm = clampf(glitch_intensity, 0.0, 1.5) if spasm_left > 0.17 else 0.0
	release = 1.0 if spasm_left > 0.0 and spasm_left <= 0.17 and glitch_intensity > 0.0 else 0.0
	moving_blend = move_toward(moving_blend, 1.0 if moving else 0.0, delta * 8.0)
	phase += delta * (12.0 if hunting else 6.3) * moving_blend * speed_factor(hunting)
	var drag := sin(phase)
	var hitch := pow(maxf(0.0, sin(phase + 0.65)), 6.0)
	# Hold each broken pose for several frames; no random frame-rate-dependent jitter.
	var snap := sin(floor(elapsed * 15.0) * 2.399 + float(spasm_number))
	var counter := sin(floor(elapsed * 11.0) * 1.71)
	head_offset = Vector3(-0.13 + snap * spasm * 0.32 - release * 0.2,
		counter * spasm * 0.24, neck_twist + snap * spasm * 0.48 - release * 0.35)
	figure.position.x = snap * 0.035 * spasm
	figure.position.y = -0.025 - hitch * limp_depth * moving_blend - spasm * 0.055
	figure.rotation.z = 0.045 + drag * 0.045 * moving_blend + counter * spasm * 0.075
	if not skeleton: return
	var poses := {
		"Head": Quaternion.from_euler(head_offset),
		"Spine": Quaternion.from_euler(Vector3(-body_hunch - hitch * 0.09 - release * 0.17, snap * spasm * 0.14, -0.08 - counter * spasm * 0.12)),
		"ArmLeft": Quaternion.from_euler(Vector3(-0.4 - (0.3 if hunting else 0.0) - spasm * 0.5 + drag * 0.12, 0.12, 0.2 + snap * spasm * 0.25)),
		"ArmRight": Quaternion.from_euler(Vector3(0.16 - release * 0.8 + counter * spasm * 0.35, -0.14, -0.15 - spasm * 0.24)),
		"ForearmLeft": Quaternion.from_euler(Vector3(-0.55 - spasm * 0.75, 0.0, 0.16)),
		"ForearmRight": Quaternion.from_euler(Vector3(-0.15 - release * 0.65 - spasm * 0.35, 0.0, -0.22)),
		"LegLeft": Quaternion.from_euler(Vector3(drag * 0.32 * moving_blend - spasm * 0.12, 0.0, 0.04)),
		"LegRight": Quaternion.from_euler(Vector3(-drag * 0.16 * moving_blend - 0.05, 0.0, -0.04))
	}
	for bone in poses:
		if bones.has(bone):
			var index: int = bones[bone]
			var target: Quaternion = rest[bone] * poses[bone]
			skeleton.set_bone_pose_rotation(index, skeleton.get_bone_pose_rotation(index).slerp(target, 1.0 - exp(-delta * (70.0 if spasm > 0.0 or release > 0.0 else 20.0))))

func apply_tracked_head(skeleton: Skeleton3D, bones: Dictionary) -> void:
	# The gaze solver runs first; retain the contractions instead of erasing them.
	if not skeleton or not bones.has("Head"): return
	var index: int = bones["Head"]
	skeleton.set_bone_pose_rotation(index, skeleton.get_bone_pose_rotation(index) * Quaternion.from_euler(head_offset))
