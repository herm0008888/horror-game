extends Node3D
@export_node_path("Node3D") var lighting_path: NodePath=NodePath("../Lighting")
var next_creak:=0
func _ready() -> void:
	var loop: AudioStreamWAV=$RoomTone.stream.duplicate()
	loop.loop_begin=0
	loop.loop_end=roundi(loop.get_length()*loop.mix_rate)
	loop.loop_mode=AudioStreamWAV.LOOP_FORWARD
	$RoomTone.stream=loop
	$CreakTimer.timeout.connect(_creak)
	var lighting:=get_node_or_null(lighting_path)
	if lighting:
		lighting.mode_changed.connect(_mode_changed)
		_mode_changed(lighting.normal_lighting)
	else: _mode_changed(false)
func _mode_changed(normal: bool) -> void:
	if normal:
		$RoomTone.stop()
		$CreakTimer.stop()
		for sound in $Creaks.get_children(): sound.stop()
	else:
		$RoomTone.play()
		$CreakTimer.start(15.0)
func _creak() -> void:
	var sounds: Array=$Creaks.get_children()
	var sound: AudioStreamPlayer3D=sounds[next_creak%sounds.size()]
	next_creak+=1
	sound.pitch_scale=randf_range(0.82,0.98)
	sound.play()
	$CreakTimer.start(randf_range(21.0,34.0))
