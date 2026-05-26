extends Control

const MATCH_SCENE := "res://Scenes/Match.tscn"
const LOADOUT_SELECT_SCENE := "res://UI/LoadoutSelect.tscn"

@export var stage_roster: Array[StageData] = []

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var preview_rect: TextureRect = $Layout/PreviewPanel/Preview
@onready var stage_name_label: Label = $Layout/PreviewPanel/StageNameLabel
@onready var left_arrow: Label = $Layout/PreviewPanel/LeftArrow
@onready var right_arrow: Label = $Layout/PreviewPanel/RightArrow
@onready var prompt_label: Label = $Layout/PromptLabel

var selected_index: int = 0
var input_locked: bool = false

func _ready() -> void:
	if stage_roster.is_empty():
		stage_roster = MatchSettings.stage_roster

	if animation_player.has_animation("enter"):
		animation_player.play("enter")

	_refresh_stage()

func _process(_delta: float) -> void:
	if input_locked:
		return

	if _defend_pressed():
		_go_back()
		return

	if _attack_pressed():
		_proceed()
		return

	if _left_pressed():
		_change_stage(-1)
	elif _right_pressed():
		_change_stage(1)

func _defend_pressed() -> bool:
	return PlayerInput.defend_pressed(1) or PlayerInput.defend_pressed(2)

func _attack_pressed() -> bool:
	return PlayerInput.attack_pressed(1) or PlayerInput.attack_pressed(2)

func _left_pressed() -> bool:
	return PlayerInput.left_pressed(1) or PlayerInput.left_pressed(2)

func _right_pressed() -> bool:
	return PlayerInput.right_pressed(1) or PlayerInput.right_pressed(2)

func _change_stage(direction: int) -> void:
	if stage_roster.is_empty():
		return
	selected_index = (selected_index + direction + stage_roster.size()) % stage_roster.size()
	AudioManager.play_navigate()
	_refresh_stage()
	if animation_player.has_animation("stage_change"):
		animation_player.play("stage_change")

func _refresh_stage() -> void:
	if stage_roster.is_empty():
		preview_rect.texture = null
		stage_name_label.text = "No Stages"
		left_arrow.visible = false
		right_arrow.visible = false
		return

	var stage: StageData = stage_roster[selected_index]
	if stage != null:
		preview_rect.texture = stage.preview
		stage_name_label.text = String(stage.display_name)
	left_arrow.visible = stage_roster.size() > 1
	right_arrow.visible = stage_roster.size() > 1

func _proceed() -> void:
	if input_locked:
		return
	if stage_roster.is_empty():
		AudioManager.play_invalid()
		return
	input_locked = true
	MatchSettings.selected_stage = stage_roster[selected_index]
	MatchSettings.reset_match()
	AudioManager.play_select()
	if animation_player.has_animation("exit"):
		animation_player.play("exit")
		await animation_player.animation_finished
	get_tree().change_scene_to_file(MATCH_SCENE)

func _go_back() -> void:
	if input_locked:
		return
	input_locked = true
	AudioManager.play_back()
	if animation_player.has_animation("exit"):
		animation_player.play("exit")
		await animation_player.animation_finished
	get_tree().change_scene_to_file(LOADOUT_SELECT_SCENE)
