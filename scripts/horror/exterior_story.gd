extends Node3D
## Story cues stay editable in their own scene. No forced cinematic camera.
@export var start_outside: bool=true
@export_node_path("Marker3D") var spawn_path: NodePath=NodePath("../AbandonedExterior/StoryStart")
@export var opening: String="23:17. Ida sendte deg adressen. «Jeg er inne. Vær så snill, kom alene.» Så ble det stille."
@export var scarf_line: String="Idas røde skjerf. Hun må ha gått inn her."
@export var door_line: String="Lyset er på, men ingen svarer. Finn Ida."
@export var inside_line: String="Tre korte bank under gulvet. Det gamle signalet deres."
@export var cellar_line: String="En ny melding fra Ida: «Ikke gå inn. Jeg er ikke der.»"
var phase:=0
var caption_left:=14.0
var current_text: String
var player: CharacterBody3D
func _ready():
 current_text=opening
 call_deferred("setup")
func setup():
 player=get_parent().get_node("Player")
 var spawn=get_node_or_null(spawn_path)
 if start_outside and spawn:
  player.global_transform=spawn.global_transform;player.start=spawn.global_position;player.velocity=Vector3.ZERO
func caption()->String:return current_text if caption_left>0 else ""
func show_line(text: String,duration: float):current_text=text;caption_left=duration
func _process(delta: float):
 caption_left=maxf(0,caption_left-delta)
 if not is_instance_valid(player):return
 var p:=player.global_position
 if phase==0 and p.distance_to($ScarfClue.global_position)<3.8:
  phase=1;show_line(scarf_line,6)
 elif phase<=1 and p.distance_to($DoorCue.global_position)<2.8:
  phase=2;show_line(door_line,6)
 elif phase<=2 and p.z<15.65 and p.z>12 and p.x>4 and p.x<8 and p.y>-.5:
  phase=3;show_line(inside_line,4)
 elif phase==3 and p.y< -2.8:
  phase=4;show_line(cellar_line,9)
