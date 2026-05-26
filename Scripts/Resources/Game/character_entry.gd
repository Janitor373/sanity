extends Resource
class_name CharacterEntry

@export var display_name: StringName = &"Unknown"
@export var portrait: Texture2D
@export var character_scene: PackedScene
@export var body_tint: Color = Color.WHITE
@export var available_loadouts: Array[LoadoutData] = []
@export var default_stats: CharacterStats
