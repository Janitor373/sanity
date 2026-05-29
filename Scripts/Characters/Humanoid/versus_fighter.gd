extends HumanoidHero
class_name VersusFighter

@export var player_slot: int = 1
@export var body_tint: Color = Color.WHITE

const GRAVITY := 2400.0
const JUMP_VELOCITY := -1300.0
const ATTACK_COOLDOWN := 0.45
const BLOCK_MULTIPLIER := 0.25

var opponent: VersusFighter = null
var body_anchor: Vector2 = Vector2.ZERO
var ground_y: float = 0.0
var ground_set: bool = false
var vertical_velocity: float = 0.0
var attack_timer: float = 0.0
var is_blocking: bool = false
var was_blocking: bool = false

func _ready() -> void:
	super._ready()

	if body != null:
		body.modulate = body_tint
		var skeleton := body.get_node_or_null("HumanoidSkeleton")
		if skeleton is Node2D:
			body_anchor = (skeleton as Node2D).position

func _physics_process(delta: float) -> void:
	if not ground_set:
		ground_y = global_position.y
		ground_set = true

	if attack_timer > 0.0:
		attack_timer -= delta

	var grounded := global_position.y >= ground_y - 1.0
	var input_dir := Vector2.ZERO

	was_blocking = is_blocking
	is_blocking = false

	if not is_dazed:
		is_blocking = grounded and PlayerInput.defend_held(player_slot)

		if is_blocking and not was_blocking:
			play_named_move(_get_defend_move_name())

		if not is_blocking:
			input_dir.x = PlayerInput.get_horizontal(player_slot)
			# input_dir.y = PlayerInput.get_vertical(player_slot)

			if grounded and PlayerInput.jump_pressed(player_slot):
				vertical_velocity = JUMP_VELOCITY
				play_named_move(&"jump")

			if attack_timer <= 0.0 and PlayerInput.attack_pressed(player_slot):
				attack_timer = ATTACK_COOLDOWN
				handle_attack_input()

	input_dir = input_dir.normalized()

	if body != null:
		body.set_move_input(input_dir)

	_face_opponent()
	_anchor_body()

	vertical_velocity += GRAVITY * delta

	var move_speed := get_move_speed()
	var move_mult := get_movement_multiplier()
	var propulsion_velocity := get_propulsion_velocity()

	var scaled_input := Vector2(
		input_dir.x * move_mult.x,
		input_dir.y * move_mult.y
	)

	var input_velocity := scaled_input * move_speed
	update_knockback(delta)
	velocity.x = input_velocity.x + propulsion_velocity.x + knockback_velocity.x
	velocity.y = vertical_velocity + input_velocity.y + propulsion_velocity.y + knockback_velocity.y

	move_and_slide()

	if global_position.y >= ground_y:
		global_position.y = ground_y
		if vertical_velocity > 0.0:
			vertical_velocity = 0.0

func _has_weapon() -> bool:
	return body != null and body.equipped_weapon != null and is_instance_valid(body.equipped_weapon)

func _has_shield() -> bool:
	return (
		body != null
		and body.equipped_shield != null
		and is_instance_valid(body.equipped_shield)
		and body.equipped_shield.data != null
		and body.equipped_shield.get_equipment_type() == EquipmentData.EquipmentType.SHIELD
	)

func _get_weapon_type() -> int:
	if not _has_weapon():
		return EquipmentData.EquipmentType.NONE

	return body.equipped_weapon.get_equipment_type()

func _face_opponent() -> void:
	if body == null or opponent == null or not is_instance_valid(opponent):
		return

	var dx := opponent.global_position.x - global_position.x
	if dx > 1.0:
		body.set_facing(1)
	elif dx < -1.0:
		body.set_facing(-1)

func _anchor_body() -> void:
	if body == null:
		return

	body.position = Vector2(-body.facing * body_anchor.x, -body_anchor.y)

func attack() -> void:
	play_named_move(_get_attack_move_name())

func _get_attack_move_name() -> StringName:
	match _get_weapon_type():
		EquipmentData.EquipmentType.AXE:
			return &"axe_attack"
		EquipmentData.EquipmentType.SPEAR:
			return &"spear_attack"
		EquipmentData.EquipmentType.SWORD:
			return &"sword_attack"
		EquipmentData.EquipmentType.DAGGER:
			return &"dagger_attack"
		EquipmentData.EquipmentType.BAT:
			return &"bat_attack"
		EquipmentData.EquipmentType.BATON:
			return &"baton_attack"
		EquipmentData.EquipmentType.KNIFE:
			return &"knife_attack"
		_:
			return &"punch"

func _get_defend_move_name() -> StringName:
	if _has_shield():
		return &"shield_defend"

	if _has_weapon():
		return &"guard_armed"

	return &"guard_unarmed"

func receive_hit(hitbox: Hitbox, hurtbox: Hurtbox) -> void:
	var attack_value := 0
	if hitbox.attacker != null and hitbox.attacker.has_method("get_attack"):
		attack_value = hitbox.attacker.get_attack()

	var defense_value := get_defense()
	var raw_damage := hitbox.damage + attack_value - defense_value
	raw_damage = max(1, raw_damage)

	var final_damage: int = roundi(raw_damage * hurtbox.damage_multiplier)

	if is_blocking:
		final_damage = maxi(1, roundi(final_damage * BLOCK_MULTIPLIER))

	hp -= final_damage

	apply_hit_knockback(hitbox)
	
	if(is_dazed == true):
		exit_dazed_state()
	add_daze(hitbox.daze_damage, hitbox.attacker)

	if AudioManager != null:
		AudioManager.play_hit()

	if hp <= 0:
		die(hitbox.attacker)

func take_fighter_hit(_amount: int) -> void:
	pass

func die(_killer = null) -> void:
	velocity = Vector2.ZERO
