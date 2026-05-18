@tool
extends Area2D
class_name InteractionArea


@export var shape_type: Game.ShapeType = Game.ShapeType.CIRCLE:
	set(value):
		shape_type = value
		call_deferred("_update_shape")

@export var object_owner: Node
@export var size: Vector2 = Vector2(32, 32):
	set(value):
		size = value
		call_deferred("_update_shape")

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _enter_tree() -> void:
	call_deferred("_update_shape")

func _ready() -> void:
	if object_owner == null:
		object_owner = get_parent()

	_update_shape()

func _update_shape() -> void:
	if not is_node_ready():
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
