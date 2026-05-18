extends Character
class_name HumanoidCharacter

@export var default_moveset: Moveset
var current_moveset: Moveset = null

var stamina: float = 0.0


func _ready() -> void:
	super._ready()
	current_moveset = default_moveset
	
	if stats is HumanoidStats:
		stamina = stats.max_stamina

func play_named_move(move_name: StringName) -> void:
	if body == null or current_moveset == null:
		return

	var move := current_moveset.get_move(move_name)
	if move != null:
		body.play_move(move, true)

func attack() -> void:
	play_named_move("jab")

func _on_interaction_box_area_entered(area: Area2D) -> void:
	if area is InteractionArea:
		nearby_object = area.object_owner

func _on_interaction_box_area_exited(area: Area2D) -> void:
	if area is InteractionArea and area.object_owner == nearby_object:
		nearby_object = null

func get_max_stamina() -> float:
	if stats is HumanoidStats:
		return (stats as HumanoidStats).max_stamina
	return 0.0
