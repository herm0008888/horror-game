@tool
extends ItemList
func drag_payload(index: int) -> Dictionary:
 if index<0 or index>=item_count: return {}
 return {"type":"files","files":PackedStringArray([str(get_item_metadata(index))])}
func _get_drag_data(at_position: Vector2) -> Variant:
 var index:=get_item_at_position(at_position,true)
 if index<0: return null
 select(index)
 item_selected.emit(index)
 var preview:=VBoxContainer.new()
 var image:=TextureRect.new()
 image.texture=get_item_icon(index)
 image.custom_minimum_size=Vector2(112,112)
 image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 preview.add_child(image)
 var label:=Label.new();label.text=get_item_text(index);preview.add_child(label)
 set_drag_preview(preview)
 return drag_payload(index)
