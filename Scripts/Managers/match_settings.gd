extends Node

signal settings_changed

const ROUND_TIME_DEFAULT: float = 99.0
const ROUNDS_TO_WIN_DEFAULT: int = 2

var player1_entry: CharacterEntry = null
var player2_entry: CharacterEntry = null
var player1_loadout: LoadoutData = null
var player2_loadout: LoadoutData = null
var selected_stage: StageData = null

var round_time: float = ROUND_TIME_DEFAULT
var rounds_to_win: int = ROUNDS_TO_WIN_DEFAULT

var player1_round_wins: int = 0
var player2_round_wins: int = 0
var current_round: int = 1
var last_round_winner: int = 0

var character_roster: Array[CharacterEntry] = []
var stage_roster: Array[StageData] = []

func reset_match() -> void:
	player1_round_wins = 0
	player2_round_wins = 0
	current_round = 1
	last_round_winner = 0
	settings_changed.emit()

func reset_all() -> void:
	player1_entry = null
	player2_entry = null
	player1_loadout = null
	player2_loadout = null
	selected_stage = null
	reset_match()

func register_round_winner(player_index: int) -> void:
	last_round_winner = player_index
	if player_index == 1:
		player1_round_wins += 1
	elif player_index == 2:
		player2_round_wins += 1
	settings_changed.emit()

func advance_round() -> void:
	current_round += 1
	settings_changed.emit()

func get_match_winner() -> int:
	if player1_round_wins >= rounds_to_win:
		return 1
	if player2_round_wins >= rounds_to_win:
		return 2
	return 0

func is_match_over() -> bool:
	return get_match_winner() != 0
