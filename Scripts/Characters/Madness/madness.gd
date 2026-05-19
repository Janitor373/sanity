extends PlayerHero
class_name MadnessHero

@export var starting_weapon_scene: PackedScene
@export var starting_shield_scene: PackedScene

var equipped_weapon: Equipment = null
var equipped_shield: Equipment = null



func _ready() -> void:
	super._ready()
	equip_starting_loadout()

func _physics_process(_delta: float) -> void:
	var input_dir := Vector2.ZERO

	if Input.is_action_pressed("move_upwards"):
		input_dir.y -= 1
	if Input.is_action_pressed("move_downwards"):
		input_dir.y += 1
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1
	
	input_dir = input_dir.normalized()
	
	var move_mult: Vector2 = get_movement_multiplier()
	var scaled_input := Vector2(
		input_dir.x * move_mult.x,
		input_dir.y * move_mult.y
	)

	var input_velocity := scaled_input * get_move_speed()
	var propulsion_velocity := get_propulsion_velocity()
	
	velocity = input_velocity + propulsion_velocity

	update_body(input_dir)

	if Input.is_action_just_pressed("attack"):
		handle_attack_action()

	if Input.is_action_just_pressed("defend"):
		handle_defend_action()

	if Input.is_action_just_pressed("jump"):
		handle_jump_action()

	move_and_slide()

func equip_starting_loadout() -> void:
	if body == null:
		return

	if starting_weapon_scene != null:
		equipped_weapon = body.equip_weapon_scene(starting_weapon_scene)

	if starting_shield_scene != null:
		equipped_shield = body.equip_shield_scene(starting_shield_scene)

func handle_attack_action() -> void:
	play_named_move(get_attack_move_name())

func handle_defend_action() -> void:
	play_named_move(get_defend_move_name())

func handle_jump_action() -> void:
	play_named_move(&"jump")

func handle_command_action() -> void:
	print("Command action pressed.")

func get_attack_move_name() -> StringName:
	match get_weapon_type():
		EquipmentData.EquipmentType.AXE:
			return &"axe_attack"
		EquipmentData.EquipmentType.SPEAR:
			return &"spear_attack"
		EquipmentData.EquipmentType.SWORD:
			return &"sword_attack"
		EquipmentData.EquipmentType.DAGGER:
			return &"dagger_attack"
		_:
			return &"punch"

func get_defend_move_name() -> StringName:
	if has_shield():
		return &"shield_defend"

	match get_weapon_type():
		EquipmentData.EquipmentType.AXE:
			return &"axe_defend"
		EquipmentData.EquipmentType.SPEAR:
			return &"spear_defend"
		EquipmentData.EquipmentType.SWORD:
			return &"sword_defend"
		EquipmentData.EquipmentType.DAGGER:
			return &"dagger_defend"
		_:
			return &"guard_unarmed"

func has_shield() -> bool:
	return equipped_shield != null and equipped_shield.data != null and equipped_shield.get_equipment_type() == EquipmentData.EquipmentType.SHIELD

func get_weapon_type() -> int:
	if equipped_weapon == null:
		return EquipmentData.EquipmentType.NONE
	return equipped_weapon.get_equipment_type()
