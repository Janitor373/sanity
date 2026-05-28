extends HumanoidHero
class_name VersusFighter

@export var player_slot: int = 1
@export var body_tint: Color = Color.WHITE

const WALK_SPEED := 320.0
const GRAVITY := 2400.0
const JUMP_VELOCITY := -950.0
const ATTACK_COOLDOWN := 0.45
const BASE_ATTACK_RANGE := 150.0
const ATTACK_VERTICAL_RANGE := 150.0
const BASE_ATTACK_DAMAGE := 7
const WEAPON_DAMAGE_BONUS := 8
const WEAPON_RANGE_BONUS := 80.0
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
	var move_x := 0.0
	was_blocking = is_blocking
	is_blocking = false

	if not is_dazed:
		is_blocking = grounded and PlayerInput.defend_held(player_slot)
		if is_blocking and not was_blocking:
			play_named_move(&"guard_unarmed")
		if not is_blocking:
			move_x = PlayerInput.get_horizontal(player_slot)
			if grounded and PlayerInput.jump_pressed(player_slot):
				vertical_velocity = JUMP_VELOCITY
			if attack_timer <= 0.0 and PlayerInput.attack_pressed(player_slot):
				_attack()

	vertical_velocity += GRAVITY * delta
	velocity = Vector2(move_x * WALK_SPEED, vertical_velocity)

	if body != null:
		body.set_move_input(Vector2(move_x, 0.0))

	_face_opponent()
	_anchor_body()
	move_and_slide()

	if global_position.y >= ground_y:
		global_position.y = ground_y
		if vertical_velocity > 0.0:
			vertical_velocity = 0.0

func _attack() -> void:
	attack_timer = ATTACK_COOLDOWN
	handle_attack_input()
	if opponent == null or not is_instance_valid(opponent):
		return
	var dx := opponent.global_position.x - global_position.x
	var dy := opponent.global_position.y - global_position.y
	var reach := BASE_ATTACK_RANGE
	var damage := BASE_ATTACK_DAMAGE
	if _has_weapon():
		var wtype: int = (body.equipped_weapon as Equipment).get_equipment_type()
		match wtype:
			EquipmentData.EquipmentType.BAT:
				reach += WEAPON_RANGE_BONUS + 20.0
				damage += WEAPON_DAMAGE_BONUS + 4
			EquipmentData.EquipmentType.BATON:
				reach += WEAPON_RANGE_BONUS - 20.0
				damage += WEAPON_DAMAGE_BONUS - 2
			_:
				reach += WEAPON_RANGE_BONUS
				damage += WEAPON_DAMAGE_BONUS
	if absf(dx) <= reach and absf(dy) <= ATTACK_VERTICAL_RANGE:
		opponent.take_fighter_hit(damage)
		AudioManager.play_hit()

func take_fighter_hit(amount: int) -> void:
	var final_amount := amount
	if is_blocking:
		final_amount = maxi(1, roundi(amount * BLOCK_MULTIPLIER))
	hp = maxi(0, hp - final_amount)

func _has_weapon() -> bool:
	return body != null and body.equipped_weapon != null and is_instance_valid(body.equipped_weapon)

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
	if not _has_weapon():
		return &"punch"
	if not (body.equipped_weapon is Equipment):
		return &"punch"
	var wtype: int = (body.equipped_weapon as Equipment).get_equipment_type()
	match wtype:
		EquipmentData.EquipmentType.SWORD:
			return &"sword_attack"
		EquipmentData.EquipmentType.AXE:
			return &"axe_attack"
		EquipmentData.EquipmentType.BAT:
			return &"bat_attack"
		EquipmentData.EquipmentType.BATON:
			return &"baton_attack"
		_:
			return &"punch"

func die(_killer = null) -> void:
	velocity = Vector2.ZERO
