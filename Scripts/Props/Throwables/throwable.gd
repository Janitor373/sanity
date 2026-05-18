extends RigidBody2D
class_name Throwable

enum State {
	FREE,
	CARRIED,
	THROWN
}

var _health := 100
@export var max_health := 100

var health:
	get:
		return _health
	set(value):
		_health = clamp(value, 0, max_health)

@export var team = Game.Team.NONE
@export var defense := 0

@export var throw_speed: float = 800.0
@export var throw_spin: float = 8.0
@export var min_throw_damage_speed: float = 120.0
@export var bounce_enabled: bool = true

var carried_by: Character = null
var state: State = State.FREE

@onready var hitbox: Hitbox = $Hitbox
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	health = max_health

	if hitbox != null:
		hitbox.attacker = self
		hitbox.deactivate()

	contact_monitor = true
	max_contacts_reported = 4

func _process(_delta: float) -> void:
	if state == State.CARRIED and carried_by != null:
		follow_carrier()

func interact(actor) -> void:
	if carried_by != null:
		return

	if actor == null:
		return

	carried_by = actor
	actor.carried_object = self
	state = State.CARRIED

	freeze = true
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0

	if hitbox != null:
		hitbox.deactivate()
		hitbox.attacker = actor

func follow_carrier() -> void:
	if carried_by == null:
		return

	var carry_point = carried_by.get_node_or_null("CarryPoint")
	if carry_point == null:
		return

	global_position = carry_point.global_position
	rotation = 0.0

func throw(direction: Vector2) -> void:
	if carried_by == null:
		return

	var thrower := carried_by

	carried_by = null
	state = State.THROWN

	freeze = false
	sleeping = false

	if direction.length() <= 0.01:
		direction = Vector2.RIGHT

	linear_velocity = direction.normalized() * throw_speed
	angular_velocity = throw_spin * sign(direction.x if direction.x != 0.0 else 1.0)

	if hitbox != null:
		hitbox.attacker = thrower
		hitbox.damage = 30
		hitbox.activate()

func swing() -> void:
	if carried_by == null:
		return

	if hitbox == null:
		return

	hitbox.attacker = carried_by
	hitbox.damage = 20
	hitbox.activate()
	await get_tree().create_timer(0.1).timeout
	hitbox.deactivate()

func _integrate_forces(_state) -> void:
	if state == State.THROWN and hitbox != null:
		if linear_velocity.length() < min_throw_damage_speed:
			hitbox.deactivate()

func die(attacker) -> void:
	print("Broken!")
	queue_free()

func on_hit(attacker) -> void:
	print("(Throwable) Hit! HP: ", health)

func take_damage(amount, attacker) -> void:
	var final_damage = amount - defense
	final_damage = max(int(round(final_damage)), 0)

	health -= final_damage
	on_hit(attacker)

	if health <= 0:
		die(attacker)

func heal(amount) -> void:
	health += amount

func _on_hurtbox_area_entered(area: Area2D) -> void:
	if not area.is_in_group("hitbox"):
		return

	var attacker = area.attacker
	if attacker == null:
		return

	if "team" in attacker and attacker.team == team:
		return

	take_damage(area.damage, attacker)
