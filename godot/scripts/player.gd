extends CharacterBody3D

@export var max_speed := 14.0
@export var accel := 6.0
@export var steer_speed := 7.0
@export var gravity := 24.0
@export var fuel_max := 100.0
@export var fuel_drain := 5.0
@export var hit_slow := 0.45
@export var hit_recover := 2.2

var speed := 0.0
var fuel := 100.0
var steer_input := 0.0
var slow := 1.0
var running := false

func _ready() -> void:
	fuel = fuel_max

func start_run() -> void:
	position = Vector3(0, 0.7, 0)
	velocity = Vector3.ZERO
	rotation = Vector3.ZERO
	speed = 6.0
	fuel = fuel_max
	slow = 1.0
	steer_input = 0.0
	running = true

func stop_run() -> void:
	running = false
	velocity = Vector3.ZERO

func set_steer(v: float) -> void:
	steer_input = v

func hit() -> void:
	slow = hit_slow

func _physics_process(delta: float) -> void:
	if not running:
		return
	if fuel <= 0.0:
		speed = move_toward(speed, 0.0, 12.0 * delta)
		velocity = Vector3(0, velocity.y, -speed)
		if not is_on_floor():
			velocity.y -= gravity * delta
		else:
			velocity.y = 0.0
		move_and_slide()
		return
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0
	slow = move_toward(slow, 1.0, hit_recover * delta)
	speed = move_toward(speed, max_speed * slow, accel * delta)
	fuel = max(0.0, fuel - fuel_drain * delta)
	var steer := 0.0
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		steer -= 1.0
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		steer += 1.0
	steer += steer_input
	velocity.x = move_toward(velocity.x, steer * steer_speed, 20.0 * delta)
	velocity.z = -speed
	position.x = clampf(position.x, -5.5, 5.5)
	move_and_slide()
	rotation.z = lerp_angle(rotation.z, -steer * 0.22, 8.0 * delta)
