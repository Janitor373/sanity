extends CanvasLayer

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var p1_hp_bar: ProgressBar = $Top/P1HpBar
@onready var p2_hp_bar: ProgressBar = $Top/P2HpBar
@onready var p1_name_label: Label = $Top/P1NameLabel
@onready var p2_name_label: Label = $Top/P2NameLabel
@onready var p1_round_pips: HBoxContainer = $Top/P1RoundPips
@onready var p2_round_pips: HBoxContainer = $Top/P2RoundPips
@onready var timer_label: Label = $Top/TimerLabel
@onready var round_label: Label = $Top/RoundLabel
@onready var center_message_label: Label = $CenterMessageLabel

var p1_hp_max: int = 100
var p2_hp_max: int = 100

func setup(p1_name: String, p2_name: String, p1_max_hp: int, p2_max_hp: int) -> void:
	p1_name_label.text = p1_name
	p2_name_label.text = p2_name
	p1_hp_max = maxi(1, p1_max_hp)
	p2_hp_max = maxi(1, p2_max_hp)
	p1_hp_bar.max_value = p1_hp_max
	p2_hp_bar.max_value = p2_hp_max
	p1_hp_bar.value = p1_hp_max
	p2_hp_bar.value = p2_hp_max
	_rebuild_pips(p1_round_pips, MatchSettings.rounds_to_win)
	_rebuild_pips(p2_round_pips, MatchSettings.rounds_to_win)
	_refresh_pips()
	_refresh_round_label()

func update_hp(player_index: int, current_hp: int) -> void:
	var bar: ProgressBar = p1_hp_bar if player_index == 1 else p2_hp_bar
	var previous: float = bar.value
	bar.value = clampf(current_hp, 0.0, bar.max_value)
	if bar.value < previous and animation_player.has_animation("hp_damage_p%d" % player_index):
		animation_player.play("hp_damage_p%d" % player_index)

func update_timer(seconds_remaining: float) -> void:
	var clamped := maxf(0.0, seconds_remaining)
	timer_label.text = "%02d" % int(clamped)
	if clamped <= 10.0 and animation_player.has_animation("timer_warning"):
		if not animation_player.is_playing() or animation_player.current_animation != "timer_warning":
			animation_player.play("timer_warning")

func show_center_message(message: String, animation_name: String = "round_announcement") -> void:
	center_message_label.text = message
	center_message_label.visible = true
	if animation_player.has_animation(animation_name):
		animation_player.play(animation_name)

func hide_center_message() -> void:
	center_message_label.visible = false

func refresh_score() -> void:
	_refresh_pips()
	_refresh_round_label()

func _refresh_pips() -> void:
	var p1_pips := p1_round_pips.get_children()
	for i in p1_pips.size():
		var pip := p1_pips[i] as ColorRect
		if pip != null:
			pip.color = Color(1.0, 0.85, 0.2) if i < MatchSettings.player1_round_wins else Color(0.25, 0.25, 0.25)
	var p2_pips := p2_round_pips.get_children()
	for i in p2_pips.size():
		var pip := p2_pips[i] as ColorRect
		if pip != null:
			pip.color = Color(1.0, 0.85, 0.2) if i < MatchSettings.player2_round_wins else Color(0.25, 0.25, 0.25)

func _refresh_round_label() -> void:
	round_label.text = "ROUND %d" % MatchSettings.current_round

func _rebuild_pips(container: HBoxContainer, count: int) -> void:
	for child in container.get_children():
		child.queue_free()
	for i in count:
		var pip := ColorRect.new()
		pip.custom_minimum_size = Vector2(24, 24)
		pip.color = Color(0.25, 0.25, 0.25)
		container.add_child(pip)
