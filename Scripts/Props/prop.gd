extends Node2D
class_name Prop

var _health = 100
@export var max_health = 100

var health:
	get:
		return _health
	set(value):
		_health = clamp(value, 0, max_health)

@export var team = Game.Team.NONE
@export var defense = 0

func _ready() -> void:
	health = max_health

func _process(delta: float) -> void:
	pass

func die(attacker):
	print("Died!")

func on_hit(attacker):
	print("(Prop) Hit! HP: ", health)

func take_damage(amount, attacker):
	
	var final_damage = amount - defense
	final_damage = max(int(round(final_damage)), 0)
	
	health -= final_damage
	
	on_hit(attacker)

func heal(amount):
	health += amount

func _on_hurtbox_area_entered(area: Area2D):
	if not area.is_in_group("hitbox"):
		return
	
	var attacker = area.attacker
	if attacker == null:
		return

	if attacker.team == team:
		return
	
	take_damage(area.damage,area.attacker)
