extends Body
class_name HumanoidBody

var locomotion_time: float = 0.0

@export var max_head_hp: float = 100.0
@export var max_torso_hp: float = 150.0
@export var max_arm_hp: float = 75.0
@export var max_leg_hp: float = 90.0

var head_hp: float = 0.0
var torso_hp: float = 0.0
var arm_l_hp: float = 0.0
var arm_r_hp: float = 0.0
var leg_l_hp: float = 0.0
var leg_r_hp: float = 0.0

@export var walk_cycle_speed: float = 6.0
#@export var walk_leg_swing_degrees: float = 30.0
#@export var walk_foot_tilt_degrees: float = 8.0
#@export var walk_arm_swing_degrees: float = 20.0
@export var walk_bob_amount: float = 3.0
@export var walk_torso_tilt_degrees: float = 3.0
@export var walk_hip_swing_degrees: float = 3.0
@onready var hip_sprite: Sprite2D = $HumanoidSkeleton/Root/Hip/HipSprite

@export var walk_hand_swing_x: float = 10.0
@export var walk_hand_swing_y: float = 3.0
@export var walk_foot_swing_x: float = 4.0
@export var walk_foot_lift_y: float = 4.0

@export var idle_speed: float = 2.0
@export var idle_bob_amount: float = 2.0
@export var idle_sway_degrees: float = 2.0
@export var idle_head_counter_degrees: float = 2.0
@export var idle_skull_bob: float = 5.0

@onready var hip: Bone2D = $HumanoidSkeleton/Root/Hip
@onready var torso: Bone2D = $HumanoidSkeleton/Root/Hip/Torso
@onready var skull: Bone2D = $HumanoidSkeleton/Root/Hip/Torso/Skull

@onready var hand_l: Bone2D = $HumanoidSkeleton/Root/Hip/Torso/HandL
@onready var hand_r: Bone2D = $HumanoidSkeleton/Root/Hip/Torso/HandR
@onready var foot_l: Bone2D = $HumanoidSkeleton/Root/Hip/FootL
@onready var foot_r: Bone2D = $HumanoidSkeleton/Root/Hip/FootR


#@export var hitbox_scene: PackedScene

var time: float = 0.0
#var active_hitboxes: Array = []
#var sprite_variant_map: Dictionary = {}
#var default_part_z: Dictionary = {}
#var default_part_position: Dictionary = {}
var z_tracked_parts: Array[Node2D] = []
var position_tracked_parts: Array[Node2D] = []

@export var starting_weapon_scene: PackedScene
@export var starting_shield_scene: PackedScene

#var equipped_weapon: Equipment = null
#var equipped_shield: Equipment = null

func _ready() -> void:
	super._ready()

	head_hp = max_head_hp
	torso_hp = max_torso_hp
	arm_l_hp = max_arm_hp
	arm_r_hp = max_arm_hp
	leg_l_hp = max_leg_hp
	leg_r_hp = max_leg_hp

func _process(delta: float) -> void:
	time += delta
	
	if is_moving():
		locomotion_time += delta * walk_cycle_speed

	super._process(delta)

func cache_parts() -> void:
	attachment_map.clear()
	sprite_variant_map.clear()
	default_part_z.clear()
	default_part_position.clear()

	var bones := [
		hip,
		torso,
		skull,
		hand_l,
		hand_r,
		foot_l,
		foot_r
	]

	for bone in bones:
		attachment_map[bone.name] = bone
	
	attachment_map["HandRAttachmentPoint"] = $HumanoidSkeleton/Root/Hip/Torso/HandR/HandRAttachmentPoint
	attachment_map["HandLAttachmentPoint"] = $HumanoidSkeleton/Root/Hip/Torso/HandL/HandLAttachmentPoint
	
	sprite_variant_map["Torso"] = {
		"default": torso.get_node_or_null("Torso_Default"),
	}

	z_tracked_parts = [
		hip,
		torso,
		skull,
		hand_l,
		hand_r,
		foot_l,
		foot_r
	]

	for part in z_tracked_parts:
		default_part_z[part.name] = part.z_index

	position_tracked_parts = [
		hip,
		torso,
		skull,
		hand_l,
		hand_r,
		foot_l,
		foot_r
	]

	for part in position_tracked_parts:
		default_part_position[part.name] = part.position

func apply_rest_pose() -> void:
	for part in position_tracked_parts:
		part.position = default_part_position.get(part.name, part.position)

	for part in z_tracked_parts:
		part.z_index = default_part_z.get(part.name, part.z_index)

	hip.position.y = 0.0
	torso.rotation = 0.0
	skull.rotation = 0.0
	
	hip_sprite.rotation = 0.0
	
	hand_l.rotation = 0.0
	hand_r.rotation = 0.0
	foot_l.rotation = 0.0
	foot_r.rotation = 0.0
	
	torso.skew = 0.0
	apply_part_presentation("Torso", &"default", 0.0, 0, Vector2.ZERO)
	
	if equipped_weapon != null and is_instance_valid(equipped_weapon):
		equipped_weapon.position = equipped_weapon.data.local_offset if equipped_weapon.data != null else Vector2.ZERO
		equipped_weapon.skew = 0.0
		equipped_weapon.z_index = default_part_z.get("Weapon", equipped_weapon.z_index)

	if equipped_shield != null and is_instance_valid(equipped_shield):
		equipped_shield.position = equipped_shield.data.local_offset if equipped_shield.data != null else Vector2.ZERO
		equipped_shield.skew = 0.0
		equipped_shield.z_index = default_part_z.get("Shield", equipped_shield.z_index)

func apply_idle_pose(_delta: float) -> void:
	var hip_bob := sin(time * idle_speed) * idle_bob_amount
	var skull_bob := sin(time * idle_speed) * idle_skull_bob
	var sway := sin(time * idle_speed) * deg_to_rad(idle_sway_degrees)
	var counter := sin(time * idle_speed) * deg_to_rad(idle_head_counter_degrees)
	
	hip.position.y += hip_bob
	torso.rotation += sway * 0.5
	skull.position.y += skull_bob
	skull.rotation += counter

	hand_l.rotation += sway * 0.5
	hand_r.rotation += -sway * 0.5


func apply_part_presentation(part_name: StringName, sprite_mode: StringName, skew_degrees: float, z_index_offset: int, position_offset: Vector2) -> void:
	var part: Node2D = attachment_map.get(part_name)
	if part == null:
		return

	var base_position: Vector2 = default_part_position.get(part_name, part.position)
	part.position = base_position + position_offset

	part.skew = deg_to_rad(skew_degrees)

	var base_z: int = default_part_z.get(part_name, part.z_index)
	part.z_index = base_z + z_index_offset

	var variants: Dictionary = sprite_variant_map.get(part_name, {})
	if variants.is_empty():
		return

	for mode in variants.keys():
		var sprite = variants[mode]
		if sprite != null:
			sprite.visible = (StringName(mode) == sprite_mode)

func apply_constraints() -> void:
	clamp_bone_deg(skull, -35.0, 35.0)
	clamp_bone_deg(hand_l, -240.0, 240.0)
	clamp_bone_deg(hand_r, -240.0, 240.0)
	clamp_bone_deg(foot_l, -50.0, 50.0)
	clamp_bone_deg(foot_r, -50.0, 50.0)

func clamp_bone_deg(bone: Bone2D, min_deg: float, max_deg: float) -> void:
	var deg := rad_to_deg(bone.rotation)
	deg = clamp(deg, min_deg, max_deg)
	bone.rotation = deg_to_rad(deg)

func load_clip(path: String) -> AnimationClip:
	var clip := load(path) as AnimationClip
	if clip == null:
		push_warning("Failed to load AnimationClip at path: %s" % path)
	return clip

func apply_locomotion_pose(_delta: float) -> void:
	var cycle: float = sin(locomotion_time)
	var opposite: float = sin(locomotion_time + PI)

	var torso_tilt: float = deg_to_rad(walk_torso_tilt_degrees)
	var hip_sway: float = deg_to_rad(walk_hip_swing_degrees)
	var bob: float = abs(sin(locomotion_time)) * walk_bob_amount
	
	hip.position.y += bob
	hip_sprite.rotation += cycle * hip_sway

	var local_move_x: float = move_input.x * facing
	torso.rotation += local_move_x * torso_tilt

	foot_l.position.x += cycle * walk_foot_swing_x
	foot_r.position.x += opposite * walk_foot_swing_x

	foot_l.position.y -= abs(cycle) * walk_foot_lift_y
	foot_r.position.y -= abs(opposite) * walk_foot_lift_y

	hand_l.position.x += opposite * walk_hand_swing_x
	hand_r.position.x += cycle * walk_hand_swing_x

	hand_l.position.y += abs(opposite) * walk_hand_swing_y
	hand_r.position.y += abs(cycle) * walk_hand_swing_y
