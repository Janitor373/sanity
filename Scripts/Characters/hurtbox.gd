@tool
extends Area2D
class_name Hurtbox

enum BodyPart {
	HEAD,
	TORSO,
	ARM_L,
	ARM_R,
	LEG_L,
	LEG_R
}

@export var shape_type: Game.ShapeType = Game.ShapeType.RECTANGLE:
	set(value):
		shape_type = value
		call_deferred("_update_shape")

@export var size: Vector2 = Vector2(24, 24):
	set(value):
		size = value
		call_deferred("_update_shape")

@export var body_part: BodyPart = BodyPart.TORSO
@export var damage_multiplier: float = 1.0

var owner_character = null

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _enter_tree() -> void:
	call_deferred("_update_shape")

func _ready() -> void:
	add_to_group("hurtbox")
	call_deferred("_update_shape")

func _update_shape() -> void:
	if not is_inside_tree():
		return

	if collision_shape == null:
		return

	var shape: Shape2D

	if shape_type == Game.ShapeType.RECTANGLE:
		var rect := RectangleShape2D.new()
		rect.size = size
		shape = rect
	else:
		var circle := CircleShape2D.new()
		circle.radius = size.x * 0.5
		shape = circle

	collision_shape.shape = shape
