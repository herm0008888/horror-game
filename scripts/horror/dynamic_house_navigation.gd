extends NavigationRegion3D
signal routes_updated(revision: int)
@export var settle_delay: float=.65
@export var minimum_interval: float=1.8
var revision:=0
var dirty:=true
var quiet:=1.0
var cooldown:=0.0
var busy:=false
var scan_timer:=0.0
var tracked: Dictionary={}
var service: Node
var candidate: NavigationMesh
func _ready():
 add_to_group("dynamic_navigation")
 call_deferred("initialize_tracking")
func initialize_tracking():
 service=get_parent().get_node_or_null("PropInteraction")
 if service:
  for prop in service.roots:
   if is_instance_valid(prop) and not service.should_highlight(prop):tracked[prop]=prop.global_transform
func request_update():
 if not dirty:quiet=settle_delay
 dirty=true
func _process(delta: float):
 cooldown=maxf(0,cooldown-delta);quiet=maxf(0,quiet-delta);scan_timer-=delta
 if scan_timer<=0:
  scan_timer=.35
  for prop in tracked:
   if not is_instance_valid(prop):continue
   var old: Transform3D=tracked[prop]
   if old.origin.distance_squared_to(prop.global_position)>.0225 or old.basis.x.distance_squared_to(prop.global_basis.x)>.025:
    tracked[prop]=prop.global_transform
    var held: RigidBody3D=get_parent().get_node("Player/ToolController").grabbed
    if not is_instance_valid(held) or (prop!=held and not held.is_ancestor_of(prop)):request_update()
 if dirty and not busy and quiet<=0 and cooldown<=0:
  busy=true;dirty=false
  call_deferred("rebuild")
func excluded(collider: CollisionShape3D, held: RigidBody3D) -> bool:
 if collider.disabled:return true
 var body:=collider.get_parent() as PhysicsBody3D
 if body==null or body is CharacterBody3D or (body.collision_layer&1)==0:return true
 var cursor: Node=body
 while cursor and cursor!=get_parent():
  if cursor.is_in_group("exterior_geometry"):return true
  if cursor==held or cursor is AnimatableBody3D or cursor.has_method("set_open"):return true
  cursor=cursor.get_parent()
 if service:
  var prop: Node3D=service.resolve(body)
  if prop and service.should_highlight(prop):return true
 return false
func rebuild():
 if not is_inside_tree():return
 var house=get_parent()
 var held: RigidBody3D=house.get_node("Player/ToolController").grabbed
 var snapshot:=Node3D.new();snapshot.name="NavigationSnapshot";house.add_child(snapshot);snapshot.set_as_top_level(true);snapshot.global_transform=Transform3D.IDENTITY
 for collision in house.find_children("*","CollisionShape3D",true,false):
  if collision.is_ancestor_of(snapshot) or snapshot.is_ancestor_of(collision) or excluded(collision,held):continue
  var proxy:=StaticBody3D.new();proxy.collision_layer=128;proxy.collision_mask=0;snapshot.add_child(proxy)
  var copy:=CollisionShape3D.new();copy.shape=collision.shape;proxy.add_child(copy);copy.global_transform=collision.global_transform
 candidate=NavigationMesh.new()
 candidate.cell_size=.08;candidate.cell_height=.04;candidate.agent_height=2.04;candidate.agent_radius=.32
 candidate.agent_max_climb=.24;candidate.agent_max_slope=48;candidate.region_min_size=1.0;candidate.region_merge_size=4.0
 candidate.geometry_parsed_geometry_type=NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
 candidate.geometry_collision_mask=128
 var geometry:=NavigationMeshSourceGeometryData3D.new()
 NavigationServer3D.parse_source_geometry_data(candidate,geometry,snapshot)
 # Furniture is an obstruction, not a miniature second floor to climb onto.
 if service:
  for prop in service.roots:
   if not is_instance_valid(prop) or service.should_highlight(prop):continue
   if is_instance_valid(held) and (prop==held or held.is_ancestor_of(prop)):continue
   var bounds: AABB=service.world_bounds(prop)
   if bounds.size.y<.28:continue
   var a:=bounds.position;var b:=bounds.end
   var outline:=PackedVector3Array([Vector3(a.x,0,a.z),Vector3(b.x,0,a.z),Vector3(b.x,0,b.z),Vector3(a.x,0,b.z)])
   geometry.add_projected_obstruction(outline,a.y-.12,bounds.size.y+.24,false)
 snapshot.free()
 NavigationServer3D.bake_from_source_geometry_data_async(candidate,geometry,Callable(self,"bake_finished"))
func bake_finished():
 if not is_inside_tree():return
 if candidate and candidate.get_polygon_count()>20:
  navigation_mesh=candidate
  revision+=1
  var enemy=get_parent().get_node_or_null("Visitation")
  if enemy:
   enemy.repath=0.0
   enemy.agent.target_position=Vector3.INF
   enemy.agent.target_position=enemy.last_seen if enemy.hunt>0 else enemy.points[enemy.patrol_index]
  routes_updated.emit(revision)
 busy=false;cooldown=minimum_interval
