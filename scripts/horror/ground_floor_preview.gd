extends Node3D
## Dedicated walk-through; the main game keeps its cellar intro.
func _ready() -> void:
	var house=$House
	house.intro_done=true
	house.dropped=true
	house.hinge.rotation.x=deg_to_rad(95)
	house.hatch_collision.set_deferred("disabled",true)
	house.player.position=Vector3(13.8,.05,12.65)
	house.player.start=house.player.position
	house.player.rotation.y=deg_to_rad(119)
	house.player.get_node("Camera").rotation.x=-.10
	house.get_node("Lighting").set_normal_lighting(true)
