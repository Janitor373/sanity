extends CharacterBody2D
class_name Character

@export var team = Game.Team.BLUE
@onready var body_slot: Node = $BodySlot

@export var stats: CharacterStats
var hp: float = 0.0
var daze: float = 0.0
var is_dazed: bool = false
var body: Body = null
var nearby_object = null
var carried_object: Throwable = null

func _ready() -> void:
	for child in body_slot.get_children():
		if child is Body:
			body = child
			break

	if stats != null:
		hp = stats.max_hp
	
	if body != null:
		body.set_owner_character(self)

func _process(delta: float) -> void:
	if not is_dazed:
		daze = max(0.0, daze - get_daze_recovery_rate() * delta)

func update_body(input_dir: Vector2) -> void:
	if body == null:
		return

	body.set_move_input(input_dir)

	if input_dir.x > 0.0:
		body.set_facing(1)
	elif input_dir.x < 0.0:
		body.set_facing(-1)

func handle_attack_input() -> void:
	if carried_object:
		throw_object()
	elif nearby_object:
		use()
	else:
		attack()

func receive_hit(hitbox: Hitbox, hurtbox: Hurtbox) -> void:
	print("RECEIVE_HIT start | hp before=", hp)

	var attack_value := 0
	if hitbox.attacker != null and hitbox.attacker.has_method("get_attack"):
		attack_value = hitbox.attacker.get_attack()

	var defense_value := get_defense()
	var raw_damage := hitbox.damage + attack_value - defense_value
	raw_damage = max(1, raw_damage)

	var final_damage: int = roundi(raw_damage * hurtbox.damage_multiplier)
	hp -= final_damage

	print("RECEIVE_HIT end | final_damage=", final_damage, " hp after=", hp)

	if hp <= 0:
		die(hitbox.attacker)

	add_daze(hitbox.daze_damage, hitbox.attacker)

func die(_killer = null) -> void:
	print(name, " died.")
	queue_free()

func throw_object() -> void:
	if carried_object:
		var dir := get_facing_direction()
		carried_object.throw(dir)
		carried_object = null

func use() -> void:
	if nearby_object:
		nearby_object.interact(self)

func attack() -> void:
	pass

func enter_dazed_state(_source = null) -> void:
	is_dazed = true
	velocity = Vector2.ZERO
	print(name, " is dazed.")

func exit_dazed_state() -> void:
	is_dazed = false
	daze = 0.0

func get_facing_direction() -> Vector2:
	if velocity.length() > 0.01:
		return velocity.normalized()

	if body != null:
		return Vector2(body.facing, 0.0)

	return Vector2.RIGHT

func get_power() -> int:
	if stats == null:
		return 0
	return stats.power

func get_attack() -> int:
	if stats == null:
		return 0
	return stats.attack

func get_defense() -> int:
	if stats == null:
		return 0
	return stats.defense

func get_daze_threshold() -> float:
	if stats == null:
		return 100.0
	return stats.daze_threshold

func get_daze_recovery_rate() -> float:
	if stats == null:
		return 0.0
	return stats.daze_recovery_rate

func add_daze(amount: float, source = null) -> void:
	if is_dazed:
		return

	daze += amount

	if daze >= get_daze_threshold():
		enter_dazed_state(source)

func get_move_speed() -> float:
	if stats == null:
		return 500.0
	return stats.move_speed

func get_movement_multiplier() -> Vector2:
	if body == null:
		return Vector2.ONE
	return body.get_current_movement_multiplier()

func get_propulsion_velocity() -> Vector2:
	if body == null:
		return Vector2.ZERO

	var local_velocity := body.get_current_propulsion_velocity()

	local_velocity.x *= body.facing
	return local_velocity

func on_clash_tied(_my_hitbox: Hitbox, _other_hitbox: Hitbox) -> void:
	print(name, " clashed evenly.")

func on_clash_won_weak(_my_hitbox: Hitbox, _other_hitbox: Hitbox) -> void:
	print(name, " won clash narrowly.")

func on_clash_won_strong(_my_hitbox: Hitbox, _other_hitbox: Hitbox) -> void:
	print(name, " won clash strongly.")

func on_clash_lost_weak(_my_hitbox: Hitbox, _other_hitbox: Hitbox) -> void:
	print(name, " lost clash narrowly.")
	add_daze(10.0, _other_hitbox.attacker)

func on_clash_lost_strong(_my_hitbox: Hitbox, _other_hitbox: Hitbox) -> void:
	print(name, " lost clash badly.")
	add_daze(25.0, _other_hitbox.attacker)

func on_clash_lost_weak_non_melee(_my_hitbox: Hitbox, _other_hitbox: Hitbox) -> void:
	print(name, " lost clash narrowly against non-melee attack.")

func on_clash_lost_strong_non_melee(_my_hitbox: Hitbox, _other_hitbox: Hitbox) -> void:
	print(name, " lost clash badly against non-melee attack.")
