extends Control

const CHARACTER_SELECT_SCENE := "res://UI/CharacterSelect.tscn"

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var play_button: Button = $CenterContainer/VBoxContainer/PlayButton
@onready var quit_button: Button = $CenterContainer/VBoxContainer/QuitButton
@onready var title_label: Label = $TitleLabel

var input_locked: bool = true

func _ready() -> void:
	MatchSettings.reset_all()
	if animation_player.has_animation("intro"):
		animation_player.play("intro")
		await animation_player.animation_finished
	input_locked = false
	play_button.grab_focus()
	AudioManager.play_menu_music()

	play_button.pressed.connect(_on_play_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	for btn in [play_button, quit_button]:
		btn.focus_entered.connect(_on_focus_navigate)

func _on_play_pressed() -> void:
	if input_locked:
		return
	input_locked = true
	AudioManager.play_select()
	if animation_player.has_animation("outro"):
		animation_player.play("outro")
		await animation_player.animation_finished
	get_tree().change_scene_to_file(CHARACTER_SELECT_SCENE)

func _on_quit_pressed() -> void:
	if input_locked:
		return
	AudioManager.play_back()
	get_tree().quit()

func _on_focus_navigate() -> void:
	AudioManager.play_navigate()
