extends CharacterBody2D
class_name TestCharacter

const SPEED = 500.0
var nearby_object = null
@export var team = Game.Team.BLUE
var hitbox
var carried_object: Throwable = null

func _ready():
	$Hitbox.attacker = self
	$Hitbox.damage = 10
	hitbox = $Hitbox
	
func _physics_process(delta: float) -> void:
	var input_dir = Vector2.ZERO
	
	if Input.is_action_pressed("move_upwards"):
		input_dir.y -= 1
	if Input.is_action_pressed("move_downwards"):
		input_dir.y += 1
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1

	input_dir = input_dir.normalized()
	velocity = input_dir * SPEED
	
	if Input.is_action_just_pressed("attack"):
		if carried_object:
			throw_object()
		elif nearby_object:
			use()
		else:
			attack(hitbox)

	move_and_slide()

func throw_object():
	if carried_object:
		var dir = get_facing_direction()
		carried_object.throw(dir)
		carried_object = null

func use():
	if nearby_object:
		nearby_object.interact(self)

func attack(hitbox : Hitbox):
	hitbox.activate()
	await get_tree().create_timer(0.1).timeout
	hitbox.deactivate()


func get_facing_direction():
	var dir = Vector2.ZERO
	
	if Input.is_action_pressed("move_right"):
		dir.x = 1
	elif Input.is_action_pressed("move_left"):
		dir.x = -1
	
	if Input.is_action_pressed("move_downwards"):
		dir.y = 1
	elif Input.is_action_pressed("move_upwards"):
		dir.y = -1
	
	if dir == Vector2.ZERO:
		dir = Vector2.RIGHT
	
	return dir.normalized()


func _on_interaction_box_area_entered(area: Area2D):
	if area is InteractionArea:
		nearby_object = area.object_owner
	print("Detected:", area)

func _on_interaction_box_area_exited(area: Area2D) -> void:
	if area is InteractionArea and area.object_owner == nearby_object:
		nearby_object = null
