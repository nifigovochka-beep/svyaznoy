extends CharacterBody3D

@export var max_speed := 16.0
@export var accel := 8.0
@export var steer_speed := 8.0
@export var gravity := 24.0

var speed := 7.0
var lane_input := 0.0
var engine_upgrade := false
var tires_upgrade := false
var fuel := 100.0
var playing := false

func _physics_process(delta: float) -> void:
	if not playing:
		velocity = Vector3.ZERO
		return
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	var target := max_speed + (5.0 if engine_upgrade else 0.0)
	speed = move_toward(speed, target, accel * delta)
	fuel = max(0.0, fuel - (4.0 + speed * 0.12) * delta)

	var steer := 0.0
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		steer -= 1.0
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		steer += 1.0
	steer += lane_input

	var turn := steer_speed + (3.0 if tires_upgrade else 0.0)
	velocity.x = move_toward(velocity.x, steer * turn, 22.0 * delta)
	velocity.z = -speed
	position.x = clamp(position.x, -5.8, 5.8)
	move_and_slide()

	rotation.z = lerp_angle(rotation.z, -steer * 0.28, 10.0 * delta)
	rotation.y = lerp_angle(rotation.y, -steer * 0.12, 8.0 * delta)

func set_steer(v: float) -> void:
	lane_input = v

func reset_run() -> void:
	position = Vector3(0, 0.7, 0)
	velocity = Vector3.ZERO
	rotation = Vector3.ZERO
	speed = 7.0
	fuel = 100.0
	lane_input = 0.0
