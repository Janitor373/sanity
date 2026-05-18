extends Resource
class_name BoneKeyframe

@export_range(0.0, 1.0, 0.01) var time: float = 0.0
@export var rotation_degrees: float = 0.0
@export var skew_degrees: float = 0.0
@export var sprite_mode: StringName = &"default"
@export var z_index_offset: int = 0
@export var position_offset: Vector2 = Vector2.ZERO
