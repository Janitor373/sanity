extends Control

const LOADOUT_SELECT_SCENE := "res://UI/LoadoutSelect.tscn"
const MAIN_MENU_SCENE := "res://UI/MainMenu.tscn"
const PORTRAIT_SIZE := Vector2(192, 192)

@export var roster: Array[CharacterEntry] = []
@export var portrait_columns: int = 4

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var portrait_grid: GridContainer = $Layout/PortraitPanel/PortraitGrid
@onready var p1_name_label: Label = $Layout/Players/P1Side/NameLabel
@onready var p2_name_label: Label = $Layout/Players/P2Side/NameLabel
@onready var p1_portrait_preview: TextureRect = $Layout/Players/P1Side/Preview
@onready var p2_portrait_preview: TextureRect = $Layout/Players/P2Side/Preview
@onready var p1_ready_label: Label = $Layout/Players/P1Side/ReadyLabel
@onready var p2_ready_label: Label = $Layout/Players/P2Side/ReadyLabel
@onready var p1_cursor: Control = $Layout/PortraitPanel/Cursors/P1Cursor
@onready var p2_cursor: Control = $Layout/PortraitPanel/Cursors/P2Cursor
@onready var header_label: Label = $Layout/HeaderLabel

var p1_index: int = 0
var p2_index: int = 0
var p1_ready: bool = false
var p2_ready: bool = false
var input_locked: bool = false
var portrait_buttons: Array[TextureButton] = []

func _ready() -> void:
	portrait_grid.columns = portrait_columns
	if roster.is_empty():
		roster = MatchSettings.character_roster

	_populate_portraits()

	if animation_player.has_animation("enter"):
		animation_player.play("enter")

	_refresh_cursor(1)
	_refresh_cursor(2)
	_refresh_player_preview(1)
	_refresh_player_preview(2)
	_refresh_ready(1)
	_refresh_ready(2)

func _populate_portraits() -> void:
	for child in portrait_grid.get_children():
		child.queue_free()
	portrait_buttons.clear()

	for entry in roster:
		var btn := TextureButton.new()
		btn.custom_minimum_size = PORTRAIT_SIZE
		btn.stretch_mode = TextureButton.STRETCH_SCALE
		btn.ignore_texture_size = true
		if entry != null and entry.portrait != null:
			btn.texture_normal = entry.portrait
		btn.focus_mode = Control.FOCUS_NONE
		portrait_grid.add_child(btn)
		portrait_buttons.append(btn)

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

	var dx := 0
	var dy := 0
	if PlayerInput.left_pressed(player_index):
		dx -= 1
	if PlayerInput.right_pressed(player_index):
		dx += 1
	if PlayerInput.up_pressed(player_index):
		dy -= 1
	if PlayerInput.down_pressed(player_index):
		dy += 1

	if dx != 0 or dy != 0:
		_move_cursor(player_index, dx, dy)

func _move_cursor(player_index: int, dx: int, dy: int) -> void:
	if roster.is_empty():
		return
	var current: int = p1_index if player_index == 1 else p2_index
	var cols := portrait_columns
	var total := roster.size()
	var rows: int = ceili(float(total) / float(cols))
	var col: int = current % cols
	var row: int = floori(float(current) / float(cols))

	col = clampi(col + dx, 0, cols - 1)
	row = clampi(row + dy, 0, rows - 1)
	var new_index: int = row * cols + col
	new_index = clampi(new_index, 0, total - 1)

	if new_index == current:
		return

	if player_index == 1:
		p1_index = new_index
	else:
		p2_index = new_index

	AudioManager.play_navigate()
	_refresh_cursor(player_index)
	_refresh_player_preview(player_index)

func _refresh_cursor(player_index: int) -> void:
	var index: int = p1_index if player_index == 1 else p2_index
	if index < 0 or index >= portrait_buttons.size():
		return
	var target: TextureButton = portrait_buttons[index]
	var cursor: Control = p1_cursor if player_index == 1 else p2_cursor
	cursor.global_position = target.global_position - Vector2(8, 8)
	cursor.size = target.size + Vector2(16, 16)

func _refresh_player_preview(player_index: int) -> void:
	var index: int = p1_index if player_index == 1 else p2_index
	if index < 0 or index >= roster.size():
		return
	var entry: CharacterEntry = roster[index]
	if entry == null:
		return
	if player_index == 1:
		p1_name_label.text = String(entry.display_name)
		p1_portrait_preview.texture = entry.portrait
	else:
		p2_name_label.text = String(entry.display_name)
		p2_portrait_preview.texture = entry.portrait

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
	if p1_index < 0 or p1_index >= roster.size():
		return
	if p2_index < 0 or p2_index >= roster.size():
		return

	input_locked = true
	MatchSettings.player1_entry = roster[p1_index]
	MatchSettings.player2_entry = roster[p2_index]

	AudioManager.play_select()
	if animation_player.has_animation("exit"):
		animation_player.play("exit")
		await animation_player.animation_finished
	get_tree().change_scene_to_file(LOADOUT_SELECT_SCENE)

func _go_back() -> void:
	if input_locked:
		return
	input_locked = true
	AudioManager.play_back()
	if animation_player.has_animation("exit"):
		animation_player.play("exit")
		await animation_player.animation_finished
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
