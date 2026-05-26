extends Control

const MAIN_MENU_SCENE := "res://UI/MainMenu.tscn"
const MATCH_SCENE := "res://Scenes/Match.tscn"
const CHARACTER_SELECT_SCENE := "res://UI/CharacterSelect.tscn"

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var winner_label: Label = $Layout/WinnerLabel
@onready var winner_portrait: TextureRect = $Layout/WinnerPortrait
@onready var score_label: Label = $Layout/ScoreLabel
@onready var rematch_button: Button = $Layout/Buttons/RematchButton
@onready var new_match_button: Button = $Layout/Buttons/NewMatchButton
@onready var menu_button: Button = $Layout/Buttons/MenuButton

var input_locked: bool = true

func _ready() -> void:
	var winner := MatchSettings.get_match_winner()
	var winner_entry: CharacterEntry = null
	if winner == 1:
		winner_entry = MatchSettings.player1_entry
	elif winner == 2:
		winner_entry = MatchSettings.player2_entry

	if winner_entry != null:
		winner_label.text = "%s WINS" % String(winner_entry.display_name)
		winner_portrait.texture = winner_entry.portrait
	else:
		winner_label.text = "DRAW"
		winner_portrait.texture = null

	score_label.text = "%d - %d" % [MatchSettings.player1_round_wins, MatchSettings.player2_round_wins]

	if animation_player.has_animation("victory"):
		animation_player.play("victory")
		await animation_player.animation_finished

	input_locked = false
	rematch_button.grab_focus()

	rematch_button.pressed.connect(_on_rematch)
	new_match_button.pressed.connect(_on_new_match)
	menu_button.pressed.connect(_on_menu)

	for btn in [rematch_button, new_match_button, menu_button]:
		btn.focus_entered.connect(AudioManager.play_navigate)

	AudioManager.play_match_win()

func _on_rematch() -> void:
	if input_locked:
		return
	input_locked = true
	AudioManager.play_select()
	MatchSettings.reset_match()
	if animation_player.has_animation("exit"):
		animation_player.play("exit")
		await animation_player.animation_finished
	get_tree().change_scene_to_file(MATCH_SCENE)

func _on_new_match() -> void:
	if input_locked:
		return
	input_locked = true
	AudioManager.play_select()
	if animation_player.has_animation("exit"):
		animation_player.play("exit")
		await animation_player.animation_finished
	get_tree().change_scene_to_file(CHARACTER_SELECT_SCENE)

func _on_menu() -> void:
	if input_locked:
		return
	input_locked = true
	AudioManager.play_back()
	if animation_player.has_animation("exit"):
		animation_player.play("exit")
		await animation_player.animation_finished
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
