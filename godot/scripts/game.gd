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
var spawned: Array[Node3D] = []
var spawn_acc := 0.0

func _ready() -> void:
	_load()
	_refresh_menu()
	playing = false

func _process(delta: float) -> void:
	if not playing:
		return
	var dist := start_z - player.global_position.z
	if dist < 500.0:
		zone = "ПОЛЕ"
	elif dist < 1000.0:
		zone = "ПОСАДКА"
	elif dist < 1500.0:
		zone = "СЕЛО"
	elif dist < GOAL:
		zone = "ПУСТОШЬ"
	else:
		zone = "СВОИ"
		_end(true)
		return
	hud_zone.text = zone
	hud_dist.text = "%d м" % int(dist)
	hud_speed.text = "%d км/ч" % int(player.speed * 3.2)
	spawn_acc += delta
	if spawn_acc > 1.1:
		spawn_acc = 0.0
		_spawn_hazard()

func _spawn_hazard() -> void:
	var kinds := ["wreck", "crater", "puddle", "bush", "drone"]
	var kind: String = kinds[randi() % kinds.size()]
	var body := Area3D.new()
	body.name = kind
	body.position = Vector3(randf_range(-5.0, 5.0), 0.4, player.global_position.z - 40.0)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	match kind:
		"wreck":
			box.size = Vector3(2.4, 1.2, 3.2)
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(0.15, 0.15, 0.13)
			box.material = mat
		"crater":
			box.size = Vector3(2.2, 0.2, 2.2)
			var mat2 := StandardMaterial3D.new()
			mat2.albedo_color = Color(0.18, 0.12, 0.08)
			box.material = mat2
		"puddle":
			box.size = Vector3(2.0, 0.08, 1.6)
			var mat3 := StandardMaterial3D.new()
			mat3.albedo_color = Color(0.2, 0.32, 0.38)
			box.material = mat3
		"drone":
			box.size = Vector3(1.2, 0.2, 1.2)
			body.position.y = 4.0
			var mat4 := StandardMaterial3D.new()
			mat4.albedo_color = Color(0.05, 0.05, 0.05)
			box.material = mat4
		_:
			box.size = Vector3(0.8, 1.4, 0.8)
			var mat5 := StandardMaterial3D.new()
			mat5.albedo_color = Color(0.16, 0.28, 0.12)
			box.material = mat5
	mesh.mesh = box
	body.add_child(mesh)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = box.size
	col.shape = shape
	body.add_child(col)
	body.body_entered.connect(_on_hit.bind(kind, body))
	add_child(body)
	spawned.append(body)

func _on_hit(body: Node3D, kind: String, hazard: Node3D) -> void:
	if body != player or not playing:
		return
	if kind == "puddle":
		player.velocity.x += sign(player.position.x) * -4.0
		return
	if kind == "bush" and kit_left > 0:
		kit_left -= 1
		hazard.queue_free()
		return
	_end(false)

func _start() -> void:
	for n in spawned:
		if is_instance_valid(n):
			n.queue_free()
	spawned.clear()
	player.position = Vector3(0, 0.6, 0)
	player.velocity = Vector3.ZERO
	player.speed = 8.0
	player.engine_upgrade = engine
	player.tires_upgrade = tires
	start_z = player.global_position.z
	kit_left = 1 if kit else 0
	playing = true
	menu.visible = false
	over.visible = false
	shop.visible = false

func _end(win: bool) -> void:
	playing = false
	var dist := start_z - player.global_position.z
	var gain := maxi(1, int(dist / 180.0) + (8 if win else 0))
	tokens += gain
	if dist > best:
		best = dist
	_save()
	over_title.text = "ДОВЁЗ" if win else "ПАКЕТ НЕ ДОШЁЛ"
	over_sub.text = ("свои приняли пакет" if win else "оборвалось на " + zone.toLower()) + "  +" + str(gain)
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
