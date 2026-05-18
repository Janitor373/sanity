extends Area2D
class_name InteractionArea

enum ShapeType { CIRCLE, RECTANGLE }

@export var shape_type: ShapeType = ShapeType.CIRCLE
@export var object_owner: Node
@export var size: Vector2 = Vector2(32, 32)

func _ready():
	if object_owner == null:
		object_owner = get_parent()

	var collision = $CollisionShape2D

	if shape_type == ShapeType.RECTANGLE:
		var rect = RectangleShape2D.new()
		rect.size = size
		collision.shape = rect
	else:
		var circle = CircleShape2D.new()
		circle.radius = size.x
		collision.shape = circle
