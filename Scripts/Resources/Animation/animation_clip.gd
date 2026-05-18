extends Resource
class_name AnimationClip

@export var clip_name: StringName
@export var duration: float = 0.3
@export var looping: bool = false
@export var additive: bool = false
@export var tracks: Array[BoneTrack] = []
