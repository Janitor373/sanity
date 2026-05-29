extends Resource
class_name MoveSoundEvent

@export_range(0.0, 999.0, 0.01) var time: float = 0.0
@export var sound: AudioStream
@export var volume_db: float = 0.0
@export var pitch_scale: float = 1.0
@export var bus: StringName = &"SFX"
