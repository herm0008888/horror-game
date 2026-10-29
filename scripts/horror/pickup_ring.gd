extends Control
@export var radius: float=13.0
@export var thickness: float=2.0
var progress:=0.0
func _ready():
 add_to_group("pickup_progress")
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 hide()
func set_progress(value: float):
 progress=clampf(value,0.0,1.0)
 visible=progress>0.0
 queue_redraw()
func _draw():
 if progress>0.0:draw_arc(size*.5,radius,-PI*.5,-PI*.5+TAU*progress,64,Color.WHITE,thickness,true)
