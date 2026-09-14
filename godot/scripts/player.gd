extends CharacterBody3D

@export var max_speed := 18.0
@export var accel := 10.0
@export var steer_speed := 8.0
@export var gravity := 24.0

var speed := 8.0
var lane_input := 0.0
var engine_upgrade := false
var tires_upgrade := false

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	var target := max_speed + (6.0 if engine_upgrade else 0.0)
	speed = move_toward(speed, target, accel * delta)

	var steer := 0.0
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		steer -= 1.0
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		steer += 1.0
	steer += lane_input

	var turn := steer_speed + (3.0 if tires_upgrade else 0.0)
	velocity.x = move_toward(velocity.x, steer * turn, 20.0 * delta)
	velocity.z = -speed
	position.x = clamp(position.x, -6.5, 6.5)
	move_and_slide()

	rotation.z = lerp(rotation.z, -steer * 0.25, 8.0 * delta)
	rotation.y = lerp(rotation.y, -steer * 0.15, 8.0 * delta)

func set_steer(v: float) -> void:
	lane_input = v
