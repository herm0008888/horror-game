@tool
extends EditorPlugin
var dock: Control
func _enter_tree() -> void:
 dock=preload("res://addons/prop_library/library_panel.tscn").instantiate()
 add_control_to_dock(DOCK_SLOT_RIGHT_UL,dock)
 dock.setup(get_editor_interface())
func _exit_tree() -> void:
 if is_instance_valid(dock):
  remove_control_from_docks(dock)
  dock.queue_free()
