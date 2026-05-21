extends Node

const PLAYER_TWO_PREFIX := "p2_"

func get_action(slot: int, base: StringName) -> StringName:
	if slot == 2:
		return StringName(PLAYER_TWO_PREFIX + base)
	return base

func get_move_vector(slot: int) -> Vector2:
	var direction := Vector2.ZERO
	if Input.is_action_pressed(get_action(slot, &"move_upwards")):
		direction.y -= 1.0
	if Input.is_action_pressed(get_action(slot, &"move_downwards")):
		direction.y += 1.0
	if Input.is_action_pressed(get_action(slot, &"move_left")):
		direction.x -= 1.0
	if Input.is_action_pressed(get_action(slot, &"move_right")):
		direction.x += 1.0
	return direction.normalized()

func get_horizontal(slot: int) -> float:
	var axis := 0.0
	if Input.is_action_pressed(get_action(slot, &"move_left")):
		axis -= 1.0
	if Input.is_action_pressed(get_action(slot, &"move_right")):
		axis += 1.0
	return axis

func attack_pressed(slot: int) -> bool:
	return Input.is_action_just_pressed(get_action(slot, &"attack"))

func defend_pressed(slot: int) -> bool:
	return Input.is_action_just_pressed(get_action(slot, &"defend"))

func defend_held(slot: int) -> bool:
	return Input.is_action_pressed(get_action(slot, &"defend"))

func jump_pressed(slot: int) -> bool:
	return Input.is_action_just_pressed(get_action(slot, &"jump"))

func left_pressed(slot: int) -> bool:
	return Input.is_action_just_pressed(get_action(slot, &"move_left"))

func right_pressed(slot: int) -> bool:
	return Input.is_action_just_pressed(get_action(slot, &"move_right"))

func up_pressed(slot: int) -> bool:
	return Input.is_action_just_pressed(get_action(slot, &"move_upwards"))

func down_pressed(slot: int) -> bool:
	return Input.is_action_just_pressed(get_action(slot, &"move_downwards"))
