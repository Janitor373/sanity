extends Control

const STAGE_SELECT_SCENE := "res://UI/StageSelect.tscn"
const CHARACTER_SELECT_SCENE := "res://UI/CharacterSelect.tscn"

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var p1_portrait: TextureRect = $Layout/P1Side/Portrait
@onready var p2_portrait: TextureRect = $Layout/P2Side/Portrait
@onready var p1_name_label: Label = $Layout/P1Side/NameLabel
@onready var p2_name_label: Label = $Layout/P2Side/NameLabel
@onready var p1_loadout_label: Label = $Layout/P1Side/LoadoutNameLabel
@onready var p2_loadout_label: Label = $Layout/P2Side/LoadoutNameLabel
@onready var p1_loadout_icon: TextureRect = $Layout/P1Side/LoadoutIcon
@onready var p2_loadout_icon: TextureRect = $Layout/P2Side/LoadoutIcon
@onready var p1_ready_label: Label = $Layout/P1Side/ReadyLabel
@onready var p2_ready_label: Label = $Layout/P2Side/ReadyLabel
@onready var p1_left_arrow: Label = $Layout/P1Side/LeftArrow
@onready var p1_right_arrow: Label = $Layout/P1Side/RightArrow
@onready var p2_left_arrow: Label = $Layout/P2Side/LeftArrow
@onready var p2_right_arrow: Label = $Layout/P2Side/RightArrow

var p1_loadout_index: int = 0
var p2_loadout_index: int = 0
var p1_ready: bool = false
var p2_ready: bool = false
var input_locked: bool = false
var p1_loadouts: Array[LoadoutData] = []
var p2_loadouts: Array[LoadoutData] = []

func _ready() -> void:
	var entry1 := MatchSettings.player1_entry
	var entry2 := MatchSettings.player2_entry

	if entry1 != null:
		p1_portrait.texture = entry1.portrait
		p1_name_label.text = String(entry1.display_name)
		p1_loadouts = entry1.available_loadouts.duplicate()
	if entry2 != null:
		p2_portrait.texture = entry2.portrait
		p2_name_label.text = String(entry2.display_name)
		p2_loadouts = entry2.available_loadouts.duplicate()

	if animation_player.has_animation("enter"):
		animation_player.play("enter")

	_refresh_loadout(1)
	_refresh_loadout(2)
	_refresh_ready(1)
	_refresh_ready(2)

func _process(_delta: float) -> void:
	if input_locked:
		return

	_handle_player_input(1)
	_handle_player_input(2)

	if p1_ready and p2_ready:
		_proceed()

func _handle_player_input(player_index: int) -> void:
	var is_ready: bool = p1_ready if player_index == 1 else p2_ready

	if PlayerInput.defend_pressed(player_index):
		if is_ready:
			_set_ready(player_index, false)
		else:
			_go_back()
		return

	if PlayerInput.attack_pressed(player_index):
		if not is_ready:
			_set_ready(player_index, true)
		return

	if is_ready:
		return

	if PlayerInput.left_pressed(player_index):
		_change_loadout(player_index, -1)
	elif PlayerInput.right_pressed(player_index):
		_change_loadout(player_index, 1)

func _change_loadout(player_index: int, direction: int) -> void:
	var loadouts: Array[LoadoutData] = p1_loadouts if player_index == 1 else p2_loadouts
	if loadouts.is_empty():
		return
	var index: int = p1_loadout_index if player_index == 1 else p2_loadout_index
	index = (index + direction + loadouts.size()) % loadouts.size()
	if player_index == 1:
		p1_loadout_index = index
	else:
		p2_loadout_index = index
	AudioManager.play_navigate()
	_refresh_loadout(player_index)

func _refresh_loadout(player_index: int) -> void:
	var loadouts: Array[LoadoutData] = p1_loadouts if player_index == 1 else p2_loadouts
	var label: Label = p1_loadout_label if player_index == 1 else p2_loadout_label
	var icon: TextureRect = p1_loadout_icon if player_index == 1 else p2_loadout_icon
	var left_arrow: Label = p1_left_arrow if player_index == 1 else p2_left_arrow
	var right_arrow: Label = p1_right_arrow if player_index == 1 else p2_right_arrow

	if loadouts.is_empty():
		label.text = "No Loadouts"
		icon.texture = null
		left_arrow.visible = false
		right_arrow.visible = false
		return

	var index: int = p1_loadout_index if player_index == 1 else p2_loadout_index
	var loadout: LoadoutData = loadouts[index]
	if loadout != null:
		label.text = String(loadout.display_name)
		icon.texture = loadout.icon

	left_arrow.visible = loadouts.size() > 1
	right_arrow.visible = loadouts.size() > 1

func _set_ready(player_index: int, value: bool) -> void:
	if player_index == 1:
		p1_ready = value
	else:
		p2_ready = value
	if value:
		AudioManager.play_select()
		if animation_player.has_animation("ready_flash_p%d" % player_index):
			animation_player.play("ready_flash_p%d" % player_index)
	else:
		AudioManager.play_back()
	_refresh_ready(player_index)

func _refresh_ready(player_index: int) -> void:
	var label: Label = p1_ready_label if player_index == 1 else p2_ready_label
	var ready_state: bool = p1_ready if player_index == 1 else p2_ready
	label.text = "READY" if ready_state else ""

func _proceed() -> void:
	if input_locked:
		return
	input_locked = true
	if not p1_loadouts.is_empty():
		MatchSettings.player1_loadout = p1_loadouts[p1_loadout_index]
	if not p2_loadouts.is_empty():
		MatchSettings.player2_loadout = p2_loadouts[p2_loadout_index]
	AudioManager.play_select()
	if animation_player.has_animation("exit"):
		animation_player.play("exit")
		await animation_player.animation_finished
	get_tree().change_scene_to_file(STAGE_SELECT_SCENE)

func _go_back() -> void:
	if input_locked:
		return
	input_locked = true
	AudioManager.play_back()
	if animation_player.has_animation("exit"):
		animation_player.play("exit")
		await animation_player.animation_finished
	get_tree().change_scene_to_file(CHARACTER_SELECT_SCENE)
