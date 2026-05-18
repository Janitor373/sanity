@tool
extends Area2D
class_name Hitbox

@export var shape_type: Game.ShapeType = Game.ShapeType.CIRCLE:
	set(value):
		shape_type = value
		call_deferred("_update_shape")

@export var size: Vector2 = Vector2(32, 32):
	set(value):
		size = value
		call_deferred("_update_shape")

var attacker = null
var damage: int = 10
var daze_damage: float = 0.0
var knockback: Vector2 = Vector2.ZERO
var reaction: int = Game.HitReaction.NONE
var power: int = 0
var attack_type: int = Game.AttackType.MELEE

var hit_targets: Array = []
var clashed_hitboxes: Array = []

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _enter_tree() -> void:
	call_deferred("_update_shape")

func _ready() -> void:
	add_to_group("hitbox")
	collision_shape.disabled = true
	area_entered.connect(_on_area_entered)
	call_deferred("_update_shape")

func _update_shape() -> void:
	if not is_inside_tree():
		return
	if collision_shape == null:
		return

	var shape: Shape2D

	if shape_type == Game.ShapeType.RECTANGLE:
		var rect := RectangleShape2D.new()
		rect.size = size
		shape = rect
	else:
		var circle := CircleShape2D.new()
		circle.radius = size.x * 0.5
		shape = circle

	collision_shape.shape = shape

func configure_from_definition(definition: HitboxDefinition, new_attacker) -> void:
	attacker = new_attacker
	damage = definition.damage
	daze_damage = definition.daze_damage
	knockback = definition.knockback
	reaction = definition.reaction
	power = definition.power
	attack_type = definition.attack_type

	shape_type = definition.shape_type
	size = definition.size
	position = definition.offset
	rotation = deg_to_rad(definition.rotation_degrees)

	_update_shape()
	deactivate()

func is_active_at_time(time: float, definition: HitboxDefinition) -> bool:
	return time >= definition.active_start_time and time <= definition.active_end_time

func activate() -> void:
	if not collision_shape.disabled:
		return

	hit_targets.clear()
	clashed_hitboxes.clear()
	collision_shape.disabled = false

func deactivate() -> void:
	if collision_shape.disabled:
		return

	collision_shape.disabled = true

func is_active() -> bool:
	return not collision_shape.disabled

func is_melee() -> bool:
	return attack_type == Game.AttackType.MELEE

func can_daze_attacker_on_clash() -> bool:
	return is_melee()

func _on_area_entered(area: Area2D) -> void:
	if collision_shape.disabled:
		return

	if area is Hurtbox:
		_handle_hurtbox(area as Hurtbox)
	elif area is Hitbox:
		_handle_hitbox(area as Hitbox)

func _handle_hurtbox(hurtbox: Hurtbox) -> void:
	if hurtbox == null:
		return
	if hurtbox.owner_character == null:
		return
	if hurtbox.owner_character == attacker:
		return
	if attacker != null and hurtbox.owner_character.team == attacker.team:
		return
	if hurtbox.owner_character in hit_targets:
		return

	hit_targets.append(hurtbox.owner_character)

	if hurtbox.owner_character.has_method("receive_hit"):
		hurtbox.owner_character.receive_hit(self, hurtbox)

func _handle_hitbox(other: Hitbox) -> void:
	if other == null:
		return
	if other == self:
		return
	if not other.is_active():
		return
	if other.attacker == null or attacker == null:
		return
	if other.attacker == attacker:
		return
	if other.attacker.team == attacker.team:
		return
	if other in clashed_hitboxes:
		return
	if self in other.clashed_hitboxes:
		return

	if get_instance_id() > other.get_instance_id():
		return

	clashed_hitboxes.append(other)
	other.clashed_hitboxes.append(self)

	resolve_clash(other)

func resolve_clash(other: Hitbox) -> void:
	var my_power: int = get_effective_clash_power()
	var other_power: int = other.get_effective_clash_power()

	if other_power <= 0 and my_power <= 0:
		apply_clash_result(other, Game.ClashResult.TIE)
		other.apply_clash_result(self, Game.ClashResult.TIE)
		return

	var ratio: float = 1.0
	if min(my_power, other_power) > 0:
		ratio = float(max(my_power, other_power)) / float(min(my_power, other_power))

	if abs(my_power - other_power) <= 2 or ratio < 1.15:
		apply_clash_result(other, Game.ClashResult.TIE)
		other.apply_clash_result(self, Game.ClashResult.TIE)
	elif my_power > other_power:
		if ratio < 1.5:
			apply_clash_result(other, Game.ClashResult.WIN_WEAK)
			other.apply_clash_result(self, Game.ClashResult.NONE)
		else:
			apply_clash_result(other, Game.ClashResult.WIN_STRONG)
			other.apply_clash_result(self, Game.ClashResult.NONE)
	else:
		if ratio < 1.5:
			other.apply_clash_result(self, Game.ClashResult.WIN_WEAK)
			apply_clash_result(other, Game.ClashResult.NONE)
		else:
			other.apply_clash_result(self, Game.ClashResult.WIN_STRONG)
			apply_clash_result(other, Game.ClashResult.NONE)

func get_effective_clash_power() -> int:
	var attacker_power: int = 0
	if attacker != null and attacker.has_method("get_power"):
		attacker_power = attacker.get_power()

	return attacker_power + power

func apply_clash_result(other: Hitbox, result: int) -> void:
	match result:
		Game.ClashResult.TIE:
			deactivate()
			other.deactivate()

			if attacker != null and attacker.has_method("on_clash_tied"):
				attacker.on_clash_tied(self, other)

			if other.attacker != null and other.attacker.has_method("on_clash_tied"):
				other.attacker.on_clash_tied(other, self)

		Game.ClashResult.WIN_WEAK:
			damage = max(1, roundi(damage * 0.6))
			other.deactivate()

			if other.attacker != null and other.attacker.has_method("on_clash_lost_weak"):
				if other.can_daze_attacker_on_clash():
					other.attacker.on_clash_lost_weak(other, self)
				else:
					other.attacker.on_clash_lost_weak_non_melee(other, self)

			if attacker != null and attacker.has_method("on_clash_won_weak"):
				attacker.on_clash_won_weak(self, other)

		Game.ClashResult.WIN_STRONG:
			other.deactivate()

			if other.attacker != null and other.attacker.has_method("on_clash_lost_strong"):
				if other.can_daze_attacker_on_clash():
					other.attacker.on_clash_lost_strong(other, self)
				else:
					other.attacker.on_clash_lost_strong_non_melee(other, self)

			if attacker != null and attacker.has_method("on_clash_won_strong"):
				attacker.on_clash_won_strong(self, other)

		Game.ClashResult.NONE:
			pass
