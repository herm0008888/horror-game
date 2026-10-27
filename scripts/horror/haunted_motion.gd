extends Node
## Uneven dragging steps, a locked shoulder and delayed head movements.
## All offsets multiply the imported bind pose so joints remain attached.
@export_range(0.0, 1.0) var neck_twist: float = 0.32
@export_range(0.0, 0.5) var body_hunch: float = 0.25
@export var glitch_intensity: float = 1.0
@export_range(0.0, 0.2) var limp_depth: float = 0.045
var phase: float = 0.0
var elapsed: float = 0.0
var moving_blend: float = 0.0

func speed_factor(hunting: bool) -> float:
	# A short pull followed by a long dragging step; never teleport the body.
	var cycle := fmod(elapsed, 4.7)
	if cycle > 2.6 and cycle < 2.82 and glitch_intensity > 0.0:
		return 0.08 if fmod(cycle * 9.0, 1.0) < 0.65 else 1.45
	var pull := pow(maxf(0.0, sin(phase)), 3.0)
	return (0.77 + pull * 0.83) if hunting else (0.62 + pull * 1.05)

func animate(delta: float, moving: bool, hunting: bool, figure: Node3D,
		skeleton: Skeleton3D, bones: Dictionary, rest: Dictionary) -> void:
	elapsed += delta
	moving_blend = move_toward(moving_blend, 1.0 if moving else 0.0, delta * 8.0)
	phase += delta * (10.0 if hunting else 5.3) * moving_blend
	var glitching := fmod(elapsed, 4.7) > 2.6 and fmod(elapsed, 4.7) < 2.95 and glitch_intensity > 0.0
	var sample_phase: float = floor(phase * 2.5) / 2.5 if glitching else phase
	var drag := sin(sample_phase)
	var hitch := pow(maxf(0.0, sin(sample_phase + 0.65)), 6.0)
	# Infrequent, brief neck contractions. No random per-frame mesh jitter.
	var contraction := pow(maxf(0.0, sin(elapsed * 1.41)), 32.0)
	var breath := sin(elapsed * 1.7)
	figure.position.x = (sin(floor(elapsed * 20.0) * 13.1) * 0.025 * glitch_intensity) if glitching else 0.0
	figure.position.y = -0.025 - hitch * limp_depth * moving_blend
	figure.rotation.z = 0.045 + drag * 0.025 * moving_blend
	if not skeleton: return
	var poses := {
		"Head": Quaternion.from_euler(Vector3(-0.10 + contraction * 0.18, -0.12 + contraction * 0.24, neck_twist + breath * 0.025 - contraction * 0.24)),
		"Spine": Quaternion.from_euler(Vector3(-body_hunch - hitch * 0.045, 0.055, -0.055)),
		"ArmLeft": Quaternion.from_euler(Vector3(-0.30 - (0.19 if hunting else 0.0) + drag * 0.055, 0.09, 0.12)),
		"ArmRight": Quaternion.from_euler(Vector3(0.13 - hitch * 0.10, -0.07, -0.07)),
		"ForearmLeft": Quaternion.from_euler(Vector3(-0.35 - contraction * 0.08, 0.0, 0.08)),
		"ForearmRight": Quaternion.from_euler(Vector3(-0.10 + drag * 0.045, 0.0, -0.12)),
		"LegLeft": Quaternion.from_euler(Vector3(drag * 0.19 * moving_blend, 0.0, 0.025)),
		"LegRight": Quaternion.from_euler(Vector3(-drag * 0.10 * moving_blend - 0.025, 0.0, -0.02))
	}
	for bone in poses:
		if bones.has(bone):
			var index: int = bones[bone]
			var target: Quaternion = rest[bone] * poses[bone]
			skeleton.set_bone_pose_rotation(index, skeleton.get_bone_pose_rotation(index).slerp(target, 1.0 - exp(-delta * (85.0 if glitching else 26.0))))


