@tool
extends VBoxContainer
const CATALOG="res://addons/prop_library/catalog.json"
const PREFS="res://.godot/editor/prop_library.cfg"
var editor: EditorInterface
var entries: Array=[]
var visible_entries: Array=[]
var favorites: PackedStringArray=[]
var selected: Dictionary={}
var icon_cache: Dictionary={}
@onready var search: LineEdit=$Search
@onready var category: OptionButton=$Filters/Category
@onready var only_favorites: CheckButton=$Filters/Favorites
@onready var grid: ItemList=$Assets
@onready var count: Label=$Count
@onready var picture: TextureRect=$Preview
@onready var title: Label=$Title
@onready var details: Label=$Details
@onready var favorite: Button=$Actions/Favorite
@onready var reveal: Button=$Actions/Reveal
func setup(interface: EditorInterface) -> void:
 editor=interface
 var prefs:=ConfigFile.new()
 if prefs.load(PREFS)==OK: favorites=PackedStringArray(prefs.get_value("library","favorites",PackedStringArray()))
 search.text_changed.connect(func(_text: String): apply_filter())
 category.item_selected.connect(func(_index: int): apply_filter())
 only_favorites.toggled.connect(func(_on: bool): apply_filter())
 grid.item_selected.connect(select_asset)
 grid.item_activated.connect(open_asset)
 favorite.pressed.connect(toggle_favorite)
 reveal.pressed.connect(reveal_asset)
 $Refresh.pressed.connect(reload_catalog)
 reload_catalog()
func reload_catalog() -> void:
 var parsed: Variant=JSON.parse_string(FileAccess.get_file_as_string(CATALOG))
 entries=parsed if parsed is Array else []
 var categories: Array[String]=[]
 for entry in entries:
  if not str(entry.category) in categories:categories.append(str(entry.category))
 categories.sort()
 category.clear();category.add_item("Alle kategorier")
 for value in categories:category.add_item(value)
 apply_filter()
func apply_filter() -> void:
 grid.clear();visible_entries.clear()
 var query:=search.text.strip_edges().to_lower()
 var selected_category:=category.get_item_text(category.selected) if category.selected>0 else ""
 for entry in entries:
  if selected_category!="" and entry.category!=selected_category:continue
  if only_favorites.button_pressed and not str(entry.id) in favorites:continue
  var words:=(str(entry.name)+" "+str(entry.id)+" "+str(entry.category)).to_lower()
  var matches:=true
  for word in query.split(" ",false):
   if not word in words:matches=false;break
  if not matches:continue
  var path:=str(entry.path)
  if not ResourceLoader.exists(path):continue
  var thumbnail:=str(entry.thumbnail)
  if not icon_cache.has(thumbnail):
   # Load the local rendered PNG directly, also before Godot has imported it.
   var image:=Image.new()
   image.load_png_from_buffer(FileAccess.get_file_as_bytes(thumbnail))
   if image and not image.is_empty():icon_cache[thumbnail]=ImageTexture.create_from_image(image)
  var icon: Texture2D=icon_cache.get(thumbnail)
  var label: String=("★ " if str(entry.id) in favorites else "")+str(entry.name)
  var index:=grid.add_item(label,icon)
  grid.set_item_metadata(index,path)
  grid.set_item_tooltip(index,str(entry.name)+"\n"+str(entry.category)+(" · Kan åpnes" if entry.interactive else "")+"\nDra inn i 3D-visningen eller scenetreet\n"+path)
  visible_entries.append(entry)
 count.text=str(visible_entries.size())+" / "+str(entries.size())+" modeller"
func select_asset(index: int) -> void:
 if index<0 or index>=visible_entries.size():return
 selected=visible_entries[index]
 picture.texture=grid.get_item_icon(index)
 title.text=str(selected.name)
 var dims: Array=selected.get("dimensions",[])
 details.text=str(selected.category)+(" · Kan åpnes med E" if selected.interactive else "")
 if dims.size()==3:details.text+="\nB %.2f · H %.2f · D %.2f m" % [dims[0],dims[1],dims[2]]
 favorite.disabled=false;reveal.disabled=false
 favorite.text="★ Fjern favoritt" if str(selected.id) in favorites else "☆ Favoritt"
func toggle_favorite() -> void:
 if selected.is_empty():return
 var id:=str(selected.id)
 if id in favorites:favorites.remove_at(favorites.find(id))
 else:favorites.append(id)
 var prefs:=ConfigFile.new();prefs.set_value("library","favorites",favorites);prefs.save(PREFS)
 favorite.text="★ Fjern favoritt" if id in favorites else "☆ Favoritt"
 apply_filter()
func reveal_asset() -> void:
 if not selected.is_empty() and editor:editor.get_file_system_dock().navigate_to_path(str(selected.path))
func open_asset(index: int) -> void:
 if index>=0 and index<visible_entries.size() and editor:editor.open_scene_from_path(str(visible_entries[index].path))
