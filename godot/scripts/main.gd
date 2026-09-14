extends Node3D

@export var segment_length := 32.0
@export var segments_ahead := 8
@export var segments_behind := 2
@export var obstacle_every := 1.2

@onready var player: CharacterBody3D = $Player
@onready var hud: Control = $HUD

var distance := 0.0
var start_z := 0.0
var segs: Dictionary = {}
var last_i := -999999
var obstacles: Array[Node3D] = []
var spawn_t := 0.0
var zone := "ПОЛЕ"

func _ready() -> void:
	player.start_run()
	start_z = player.global_position.z
	_sync_world()

func _process(delta: float) -> void:
	distance = start_z - player.global_position.z
	zone = _zone_name(distance)
	hud.set_values(player.speed, player.fuel, player.fuel_max, zone)
	_sync_world()
	spawn_t += delta
	if player.running and player.fuel > 0.0 and spawn_t >= obstacle_every:
		spawn_t = 0.0
		_spawn_obstacle()

func _zone_of(dist: float) -> int:
	if dist < 250.0:
		return 0
	if dist < 550.0:
		return 1
	return 2

func _zone_name(dist: float) -> String:
	match _zone_of(dist):
		1:
			return "ЛЕС"
		2:
			return "РУИНЫ"
		_:
			return "ПОЛЕ"

func _sync_world() -> void:
	var i := int(floor(-player.global_position.z / segment_length))
	if i == last_i:
		return
	last_i = i
	for n in range(i - segments_behind, i + segments_ahead):
		if segs.has(n):
			continue
		var seg := Node3D.new()
		seg.set_script(load("res://scripts/road_segment.gd"))
		seg.position = Vector3(0, 0, -float(n) * segment_length)
		add_child(seg)
		seg.call("setup", _zone_of(max(0.0, -seg.position.z)), segment_length)
		segs[n] = seg
	var drop: Array = []
	for k in segs.keys():
		if k < i - segments_behind or k > i + segments_ahead:
			drop.append(k)
	for k in drop:
		(segs[k] as Node).queue_free()
		segs.erase(k)

func _spawn_obstacle() -> void:
	var kinds := ["rock", "pit", "wreck"]
	var kind: String = kinds[randi() % kinds.size()]
	var a := Area3D.new()
	a.monitoring = true
	a.position = Vector3(randf_range(-4.2, 4.2), 0.35, player.global_position.z - 36.0)
	var box := BoxMesh.new()
	var mat := StandardMaterial3D.new()
	match kind:
		"wreck":
			box.size = Vector3(1.8, 1.0, 2.4)
			mat.albedo_color = Color(0.14, 0.13, 0.12)
		"pit":
			box.size = Vector3(1.8, 0.12, 1.8)
			mat.albedo_color = Color(0.12, 0.08, 0.05)
		_:
			box.size = Vector3(0.9, 0.7, 0.9)
			mat.albedo_color = Color(0.28, 0.24, 0.2)
	box.material = mat
	var mi := MeshInstance3D.new()
	mi.mesh = box
	a.add_child(mi)
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = box.size
	cs.shape = sh
	a.add_child(cs)
	a.body_entered.connect(_on_hit)
	add_child(a)
	obstacles.append(a)

func _on_hit(body: Node3D) -> void:
	if body == player:
		player.hit()

func _on_left_down() -> void:
	player.set_steer(-1.0)

func _on_left_up() -> void:
	player.set_steer(0.0)

func _on_right_down() -> void:
	player.set_steer(1.0)

func _on_right_up() -> void:
	player.set_steer(0.0)
