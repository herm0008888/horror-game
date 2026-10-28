extends RigidBody3D
## Sleeping props wake only when pushed, grabbed or struck.
@export var grabbable:=true
var holder: Node3D
func interact():
	var p=get_tree().get_first_node_in_group("horror_player")
	if p and p.has_node("ToolController") and grabbable: p.get_node("ToolController").grab(self)
