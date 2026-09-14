extends Node3D

@onready var player: CharacterBody3D = $Player
@onready var hud_zone: Label = $UI/HUD/Zone
@onready var hud_dist: Label = $UI/HUD/Dist
@onready var hud_speed: Label = $UI/HUD/Speed
@onready var menu: Control = $UI/Menu
@onready var over: Control = $UI/Over
@onready var shop: Control = $UI/Shop
@onready var tokens_label: Label = $UI/Menu/Card/Tokens
@onready var best_label: Label = $UI/Menu/Card/Best
@onready var over_title: Label = $UI/Over/Card/Title
@onready var over_sub: Label = $UI/Over/Card/Sub
@onready var shop_tokens: Label = $UI/Shop/Card/Tokens
var world: WorldStreamer

const SAVE := "user://svyaznoy.save"
const GOAL := 2200.0

var playing := false
var start_z := 0.0
var tokens := 0
var best := 0.0
var tires := false
var engine := false
var kit := false
var kit_left := 0
var zone := "ПОЛЕ"
var hazards: Array[Node3D] = []
var spawn_acc := 0.0
var fuel_label: Label

func _ready() -> void:
	if has_node("World"):
		world = $World
	else:
		var w := Node3D.new()
		w.name = "World"
		w.set_script(load("res://scripts/world.gd"))
		add_child(w)
		world = w
	_load()
	_refresh_menu()
	playing = false
	fuel_label = Label.new()
	fuel_label.name = "Fuel"
	fuel_label.position = Vector2(24, 96)
	$UI/HUD.add_child(fuel_label)

func _process(delta: float) -> void:
	if not playing:
		return
	var dist := start_z - player.global_position.z
	zone = world.biome_at(dist)
	hud_zone.text = zone
	hud_dist.text = "%d м" % int(dist)
	hud_speed.text = "%d км/ч" % int(player.speed * 3.4)
	fuel_label.text = "топливо %d" % int(player.fuel)
	world.sync(player.global_position.z, dist)
	if player.fuel <= 0.0:
		_end(false, "топливо кончилось")
		return
	if dist >= GOAL:
		_end(true, "свои приняли пакет")
		return
	spawn_acc += delta
	if spawn_acc > 1.05:
		spawn_acc = 0.0
		_spawn_hazard(dist)

func _spawn_hazard(dist: float) -> void:
	var kinds := ["wreck", "crater", "puddle", "bush"]
	if dist > 900.0:
		kinds.append("drone")
	var kind: String = kinds[randi() % kinds.size()]
	var body := Area3D.new()
	body.monitoring = true
	body.position = Vector3(randf_range(-4.6, 4.6), 0.35, player.global_position.z - 42.0)
	var box := BoxMesh.new()
	var mat := StandardMaterial3D.new()
	match kind:
		"wreck":
			box.size = Vector3(2.2, 1.1, 3.0)
			mat.albedo_color = Color(0.12, 0.12, 0.11)
		"crater":
			box.size = Vector3(2.0, 0.18, 2.0)
			mat.albedo_color = Color(0.16, 0.1, 0.07)
		"puddle":
			box.size = Vector3(1.8, 0.06, 1.4)
			mat.albedo_color = Color(0.18, 0.28, 0.32)
		"drone":
			box.size = Vector3(1.1, 0.18, 1.1)
			body.position.y = 3.6
			mat.albedo_color = Color(0.04, 0.04, 0.04)
		_:
			box.size = Vector3(0.7, 1.3, 0.7)
			mat.albedo_color = Color(0.14, 0.24, 0.1)
	box.material = mat
	var mesh := MeshInstance3D.new()
	mesh.mesh = box
	body.add_child(mesh)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = box.size
	col.shape = shape
	body.add_child(col)
	body.body_entered.connect(_on_hit.bind(kind, body))
	add_child(body)
	hazards.append(body)

func _on_hit(body: Node3D, kind: String, hazard: Node3D) -> void:
	if body != player or not playing:
		return
	if kind == "puddle":
		player.velocity.x += (-1.0 if player.position.x > 0.0 else 1.0) * 5.0
		player.fuel = max(0.0, player.fuel - 4.0)
		return
	if kind == "bush" and kit_left > 0:
		kit_left -= 1
		hazard.queue_free()
		return
	_end(false, "оборвалось на " + zone.to_lower())

func _clear_hazards() -> void:
	for n in hazards:
		if is_instance_valid(n):
			n.queue_free()
	hazards.clear()

func _start() -> void:
	_clear_hazards()
	world.reset()
	player.reset_run()
	player.engine_upgrade = engine
	player.tires_upgrade = tires
	player.playing = true
	start_z = player.global_position.z
	kit_left = 1 if kit else 0
	playing = true
	menu.visible = false
	over.visible = false
	shop.visible = false
	world.sync(player.global_position.z, 0.0)

func _end(win: bool, reason: String) -> void:
	playing = false
	player.playing = false
	var dist := start_z - player.global_position.z
	var gain := maxi(1, int(dist / 180.0) + (8 if win else 0))
	tokens += gain
	if dist > best:
		best = dist
	_save()
	over_title.text = "ДОВЁЗ" if win else "ПАКЕТ НЕ ДОШЁЛ"
	over_sub.text = reason + "  +" + str(gain)
	over.visible = true
	_refresh_menu()

func _refresh_menu() -> void:
	tokens_label.text = "жетоны %d" % tokens
	best_label.text = "рекорд %d м" % int(best)
	shop_tokens.text = "жетоны %d" % tokens

func _save() -> void:
	var f := FileAccess.open(SAVE, FileAccess.WRITE)
	f.store_var({"tokens": tokens, "best": best, "tires": tires, "engine": engine, "kit": kit})

func _load() -> void:
	if not FileAccess.file_exists(SAVE):
		return
	var f := FileAccess.open(SAVE, FileAccess.READ)
	var d: Dictionary = f.get_var()
	tokens = int(d.get("tokens", 0))
	best = float(d.get("best", 0))
	tires = bool(d.get("tires", false))
	engine = bool(d.get("engine", false))
	kit = bool(d.get("kit", false))

func _open_shop() -> void:
	menu.visible = false
	shop.visible = true
	_refresh_menu()

func _close_shop() -> void:
	shop.visible = false
	menu.visible = true
	_refresh_menu()

func _to_menu() -> void:
	over.visible = false
	menu.visible = true

func buy(what: String, price: int) -> void:
	if tokens < price:
		return
	if what == "tires" and not tires:
		tires = true
		tokens -= price
	elif what == "engine" and not engine:
		engine = true
		tokens -= price
	elif what == "kit" and not kit:
		kit = true
		tokens -= price
	_save()
	_refresh_menu()
