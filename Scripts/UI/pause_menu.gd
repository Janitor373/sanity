extends CanvasLayer

const MAIN_MENU_SCENE := "res://UI/MainMenu.tscn"

@onready var resume_button: Button = $Dim/Center/VBox/ResumeButton
@onready var menu_button: Button = $Dim/Center/VBox/MenuButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	resume_button.pressed.connect(_resume)
	menu_button.pressed.connect(_to_menu)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if get_tree().paused:
			_resume()
		else:
			_open()
		get_viewport().set_input_as_handled()

func _open() -> void:
	visible = true
	get_tree().paused = true
	AudioManager.play_navigate()
	resume_button.grab_focus()

func _resume() -> void:
	get_tree().paused = false
	visible = false
	AudioManager.play_back()

func _to_menu() -> void:
	get_tree().paused = false
	AudioManager.play_select()
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
