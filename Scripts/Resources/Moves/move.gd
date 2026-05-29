extends Resource
class_name Move

@export var move_name: StringName
@export var animation_clip: AnimationClip
@export var duration: float = 0.3
@export var hitboxes: Array[HitboxDefinition] = []
@export var propulsion: MovePropulsionClip
@export var movement_multiplier: Vector2 = Vector2.ONE
@export var sound_events: Array[MoveSoundEvent] = []
