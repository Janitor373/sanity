extends Resource
class_name HitboxDefinition


@export var attachment_point: StringName
@export var shape_type: Game.ShapeType = Game.ShapeType.RECTANGLE
@export var size: Vector2 = Vector2(24, 24)
@export var offset: Vector2 = Vector2.ZERO
@export var rotation_degrees: float = 0.0

@export_range(0.0, 10.0, 0.01) var active_start_time: float = 0.0
@export_range(0.0, 10.0, 0.01) var active_end_time: float = 0.1

@export var damage: int = 10
@export var daze_damage: float = 10.0
@export var knockback: Vector2 = Vector2.ZERO
@export var reaction: Game.HitReaction = Game.HitReaction.NONE

@export var power: int = 0
@export var attack_type: Game.AttackType = Game.AttackType.MELEE
