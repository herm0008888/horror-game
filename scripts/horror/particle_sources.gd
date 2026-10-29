extends Node3D
@export_node_path("Node3D") var boiler_path: NodePath
@export var vent_offset:=Vector3(0,1.4,0)
var boiler: Node3D
@onready var vapour: GPUParticles3D=$BoilerVapour
func _ready():
 boiler=get_node_or_null(boiler_path)
 vapour.emitting=is_instance_valid(boiler)
func _process(_delta):
 if is_instance_valid(boiler):vapour.global_position=boiler.global_transform*vent_offset
 else:vapour.emitting=false
