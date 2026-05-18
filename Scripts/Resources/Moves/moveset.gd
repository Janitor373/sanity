extends Resource
class_name Moveset

@export var moveset_name: StringName
@export var stance: StringName
@export var moves: Array[Move] = []

func get_move(move_name: StringName) -> Move:
	for move in moves:
		if move != null and move.move_name == move_name:
			return move
	return null

func has_move(move_name: StringName) -> bool:
	return get_move(move_name) != null
