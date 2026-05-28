extends Node2D
class_name MatchController

const WIN_SCREEN_SCENE := "res://UI/WinScreen.tscn"
const ROUND_START_DELAY := 1.6
const ROUND_END_DELAY := 2.2

@onready var stage_slot: Node2D = $StageSlot
@onready var fighters_slot: Node2D = $FightersSlot
@onready var hud: Node = $HudLayer/MatchHUD

var player1: Character = null
var player2: Character = null
var stage_instance: Node = null
var p1_spawn: Node2D = null
var p2_spawn: Node2D = null

var time_remaining: float = 99.0
var match_active: bool = false
var round_resolving: bool = false

func _ready() -> void:
	_load_stage()
	_spawn_fighters()
	_apply_loadouts()
	_setup_hud()
	_start_round()

func _process(delta: float) -> void:
	if not match_active:
		return

	time_remaining -= delta
	hud.update_timer(time_remaining)

	if player1 != null:
		hud.update_hp(1, player1.hp)
	if player2 != null:
		hud.update_hp(2, player2.hp)

	if round_resolving:
		return

	if player1 != null and player1.hp <= 0:
		_end_round(2)
		return
	if player2 != null and player2.hp <= 0:
		_end_round(1)
		return
	if time_remaining <= 0.0:
		_resolve_time_out()

func _load_stage() -> void:
	var stage_data := MatchSettings.selected_stage
	if stage_data == null or stage_data.stage_scene == null:
		var fallback := preload("res://Stages/default_stage.tscn")
		stage_instance = fallback.instantiate()
	else:
		stage_instance = stage_data.stage_scene.instantiate()

	stage_slot.add_child(stage_instance)

	p1_spawn = stage_instance.get_node_or_null("P1Spawn") as Node2D
	p2_spawn = stage_instance.get_node_or_null("P2Spawn") as Node2D

	if stage_data != null and stage_data.music_stream != null:
		AudioManager.play_music(stage_data.music_stream)
	else:
		AudioManager.stop_music()

func _spawn_fighters() -> void:
	player1 = _instantiate_fighter(MatchSettings.player1_entry, 1)
	player2 = _instantiate_fighter(MatchSettings.player2_entry, 2)

	if player1 != null:
		fighters_slot.add_child(player1)
		if p1_spawn != null:
			player1.global_position = p1_spawn.global_position

	if player2 != null:
		fighters_slot.add_child(player2)
		if p2_spawn != null:
			player2.global_position = p2_spawn.global_position
		if player2.body != null:
			player2.body.set_facing(-1)

	if player1 is VersusFighter and player2 is VersusFighter:
		(player1 as VersusFighter).opponent = player2 as VersusFighter
		(player2 as VersusFighter).opponent = player1 as VersusFighter

func _instantiate_fighter(entry: CharacterEntry, player_index: int) -> Character:
	if entry == null or entry.character_scene == null:
		return null
	var instance := entry.character_scene.instantiate() as Character
	if instance == null:
		return null
	if entry.default_stats != null:
		instance.stats = entry.default_stats
	instance.team = Game.Team.BLUE if player_index == 1 else Game.Team.RED
	if instance is VersusFighter:
		(instance as VersusFighter).player_slot = player_index
		(instance as VersusFighter).body_tint = Color.WHITE if player_index == 1 else Color(1.0, 0.5, 0.5)
	instance.name = "Player%d" % player_index
	_disable_child_cameras(instance)
	return instance

func _disable_child_cameras(node: Node) -> void:
	for child in node.find_children("*", "Camera2D", true, false):
		if child is Camera2D:
			(child as Camera2D).enabled = false

func _apply_loadouts() -> void:
	_apply_loadout_to(player1, MatchSettings.player1_loadout)
	_apply_loadout_to(player2, MatchSettings.player2_loadout)

func _apply_loadout_to(character: Character, loadout: LoadoutData) -> void:
	if character == null or loadout == null or character.body == null:
		return
	if loadout.weapon_scene != null:
		character.body.equip_weapon_scene(loadout.weapon_scene)
	if loadout.shield_scene != null:
		character.body.equip_shield_scene(loadout.shield_scene)
	if loadout.moveset_override != null and character is HumanoidCharacter:
		(character as HumanoidCharacter).current_moveset = loadout.moveset_override

func _setup_hud() -> void:
	var p1_name := "P1"
	var p2_name := "P2"
	var p1_max := 100
	var p2_max := 100
	if MatchSettings.player1_entry != null:
		p1_name = String(MatchSettings.player1_entry.display_name)
		if MatchSettings.player1_entry.default_stats != null:
			p1_max = MatchSettings.player1_entry.default_stats.max_hp
	if MatchSettings.player2_entry != null:
		p2_name = String(MatchSettings.player2_entry.display_name)
		if MatchSettings.player2_entry.default_stats != null:
			p2_max = MatchSettings.player2_entry.default_stats.max_hp
	hud.setup(p1_name, p2_name, p1_max, p2_max)

func _start_round() -> void:
	time_remaining = MatchSettings.round_time
	round_resolving = false
	match_active = false

	_set_fighters_active(false)
	hud.reset_bars()
	hud.update_timer(time_remaining)
	hud.refresh_score()
	hud.show_center_message("ROUND %d" % MatchSettings.current_round, "round_announcement")
	AudioManager.play_round_start()

	await get_tree().create_timer(ROUND_START_DELAY).timeout

	hud.show_center_message("FIGHT", "round_announcement")
	await get_tree().create_timer(0.6).timeout

	hud.hide_center_message()
	_set_fighters_active(true)
	match_active = true

func _end_round(winner_index: int) -> void:
	if round_resolving:
		return
	round_resolving = true
	match_active = false
	_set_fighters_active(false)
	AudioManager.play_ko()
	AudioManager.play_round_end()

	MatchSettings.register_round_winner(winner_index)
	hud.refresh_score()
	hud.show_center_message("KO", "ko_announcement")

	await get_tree().create_timer(ROUND_END_DELAY).timeout

	if MatchSettings.is_match_over():
		_finish_match()
		return

	MatchSettings.advance_round()
	_reset_fighters()
	_start_round()

func _resolve_time_out() -> void:
	if round_resolving:
		return
	round_resolving = true
	match_active = false
	_set_fighters_active(false)

	var winner := 0
	if player1 != null and player2 != null:
		if player1.hp > player2.hp:
			winner = 1
		elif player2.hp > player1.hp:
			winner = 2

	if winner == 0:
		MatchSettings.register_round_winner(0)
		hud.refresh_score()
		hud.show_center_message("DRAW", "ko_announcement")
		await get_tree().create_timer(ROUND_END_DELAY).timeout
		round_resolving = false
		MatchSettings.advance_round()
		_reset_fighters()
		_start_round()
		return

	MatchSettings.register_round_winner(winner)
	hud.refresh_score()
	hud.show_center_message("KO", "ko_announcement")
	AudioManager.play_ko()
	AudioManager.play_round_end()

	await get_tree().create_timer(ROUND_END_DELAY).timeout

	if MatchSettings.is_match_over():
		_finish_match()
		return

	round_resolving = false
	MatchSettings.advance_round()
	_reset_fighters()
	_start_round()

func _finish_match() -> void:
	if hud != null and hud.has_method("show_center_message"):
		hud.show_center_message("MATCH", "ko_announcement")
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file(WIN_SCREEN_SCENE)

func _reset_fighters() -> void:
	if player1 != null:
		_reset_fighter(player1, 1)
	if player2 != null:
		_reset_fighter(player2, 2)

func _reset_fighter(character: Character, player_index: int) -> void:
	if character.stats != null:
		character.hp = character.stats.max_hp
	character.daze = 0.0
	character.is_dazed = false
	character.velocity = Vector2.ZERO
	if player_index == 1 and p1_spawn != null:
		character.global_position = p1_spawn.global_position
		if character.body != null:
			character.body.set_facing(1)
	elif player_index == 2 and p2_spawn != null:
		character.global_position = p2_spawn.global_position
		if character.body != null:
			character.body.set_facing(-1)

func _set_fighters_active(value: bool) -> void:
	if player1 != null:
		player1.set_physics_process(value)
		player1.set_process(value)
	if player2 != null:
		player2.set_physics_process(value)
		player2.set_process(value)
