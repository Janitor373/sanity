extends HumanoidHero
class_name PlayerHero

var SPEED:= 500

func _physics_process(_delta: float) -> void:
	var input_dir := Vector2.ZERO

	if Input.is_action_pressed("move_upwards"):
		input_dir.y -= 1
	if Input.is_action_pressed("move_downwards"):
		input_dir.y += 1
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1

	input_dir = input_dir.normalized()
	velocity = input_dir * SPEED

	update_body(input_dir)

	if Input.is_action_just_pressed("attack"):
		handle_attack_input()

	move_and_slide()
