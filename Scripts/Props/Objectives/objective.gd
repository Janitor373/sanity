extends Prop

var is_captured = false

func _ready() -> void:
	health = int(round(max_health/2))
	update_health_bar()

func on_hit(attacker):
	print("Hit! HP:", health)
	update_health_bar()
	
	if health <= 0:
		die(attacker)

func die(attacker):
	if is_captured:
		return
		
	is_captured = true
	super.die(attacker)
	await get_tree().create_timer(0.2).timeout
	
	capture(attacker)
	is_captured = false

func update_health_bar():
	var ratio = float(health) / max_health
	$HealthBar/Fill.scale.x = ratio

func capture(attacker):
	if attacker == null:
		return
	
	print("Captured by: ", attacker.team)
	
	team = attacker.team
	health = max_health
	
	play_capture_effect()
	update_health_bar()
	update_flag_color()
	

func update_flag_color():
	var flag = $Flag
	
	match team:
		Game.Team.BLUE:
			flag.modulate = Color.BLUE
		Game.Team.RED:
			flag.modulate = Color.RED
		_:
			flag.modulate = Color.WHITE

func play_capture_effect():
	print("BOOM!")
