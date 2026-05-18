extends Prop
class_name Old_Throwable

var carried_by : Character = null
@onready var hitbox = $Hitbox
var velocity: Vector2 = Vector2.ZERO
var is_thrown := false
var gravity = 1200

func _ready():
	hitbox.attacker = self
	hitbox.deactivate()

func _process(delta):
	if carried_by:
		follow_carrier()
	elif is_thrown:
		move_thrown(delta)

func move_thrown(delta):
	velocity.y += gravity * delta
	global_position += velocity * delta

func interact(actor):
	if not carried_by:
		carried_by = actor
		actor.carried_object = self
		set_collision(false)

func follow_carrier():
	var carry_point = carried_by.get_node("CarryPoint")
	global_position = carry_point.global_position

func set_collision(enabled: bool):
	$StaticBody2D/CollisionShape2D.disabled = not enabled

func swing():
	hitbox.attacker = carried_by
	hitbox.damage = 20
	take_damage(hitbox.damage,self)
	
	hitbox.activate()
	await get_tree().create_timer(0.1).timeout
	hitbox.deactivate()

func throw(direction: Vector2):
	hitbox.attacker = carried_by
	carried_by = null
	is_thrown = true
	
	velocity = direction.normalized() * 800
	
	set_collision(true)

	hitbox.damage = 30
	hitbox.activate()

	
func die(attacker):
	print("Broken!")
	queue_free()
