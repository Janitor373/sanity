extends CharacterBody2D

@onready var hip: Bone2D = $HumanoidSkeleton/Root/Hip
@onready var torso: Bone2D = $HumanoidSkeleton/Root/Hip/Torso
@onready var neck: Bone2D = $HumanoidSkeleton/Root/Hip/Torso/Neck
@onready var skull: Bone2D = $HumanoidSkeleton/Root/Hip/Torso/Neck/Skull

@onready var upper_arm_l: Bone2D = $HumanoidSkeleton/Root/Hip/Torso/ShoulderL/UpperArmL
@onready var forearm_l: Bone2D = $HumanoidSkeleton/Root/Hip/Torso/ShoulderL/UpperArmL/ForeArmL
@onready var upper_arm_r: Bone2D = $HumanoidSkeleton/Root/Hip/Torso/ShoulderR/UpperArmR
@onready var forearm_r: Bone2D = $HumanoidSkeleton/Root/Hip/Torso/ShoulderR/UpperArmR/ForeArmR

var time := 0.0
var is_attacking := false
var attack_time := 0.0
var attack_duration := 0.30

@export var test_clip: AnimationClip
@export var play_test_clip := false
var clip_time := 0.0

var bone_map: Dictionary = {}

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("attack") and not is_attacking:
		is_attacking = true
		attack_time = 0.0
		
func _ready() -> void:
	cache_bones()

func _process(delta: float) -> void:
	#time += delta
	#update_attack(delta)
#
	#apply_rest_pose()
	#apply_idle_pose()
	#apply_attack_pose()
	#apply_constraints()
	
	apply_rest_pose()

	if play_test_clip and test_clip != null:
		update_clip(delta)
		apply_clip(test_clip, clip_time / test_clip.duration)

	apply_constraints()

func update_clip(delta: float) -> void:
	clip_time += delta

	if clip_time > test_clip.duration:
		if test_clip.looping:
			clip_time = 0.0
		else:
			clip_time = test_clip.duration

func apply_clip(clip: AnimationClip, normalized_time: float) -> void:
	normalized_time = clamp(normalized_time, 0.0, 1.0)

	for track in clip.tracks:
		var bone: Bone2D = bone_map.get(track.bone_name)
		if bone == null:
			continue

		var rotation_deg := sample_track(track, normalized_time)
		bone.rotation = deg_to_rad(rotation_deg)

func sample_track(track: BoneTrack, normalized_time: float) -> float:
	if track.keyframes.is_empty():
		return 0.0

	if track.keyframes.size() == 1:
		return track.keyframes[0].rotation_degrees

	var keys := track.keyframes

	if normalized_time <= keys[0].time:
		return keys[0].rotation_degrees

	if normalized_time >= keys[keys.size() - 1].time:
		return keys[keys.size() - 1].rotation_degrees

	for i in range(keys.size() - 1):
		var a: BoneKeyframe = keys[i]
		var b: BoneKeyframe = keys[i + 1]

		if normalized_time >= a.time and normalized_time <= b.time:
			var span := b.time - a.time
			if is_zero_approx(span):
				return b.rotation_degrees

			var local_t := (normalized_time - a.time) / span
			return lerp(a.rotation_degrees, b.rotation_degrees, local_t)

	return keys[keys.size() - 1].rotation_degrees

func update_attack(delta: float) -> void:
	if is_attacking:
		attack_time += delta
		if attack_time >= attack_duration:
			attack_time = attack_duration
			is_attacking = false

func apply_rest_pose() -> void:
	hip.position.y = 0.0
	torso.rotation = 0.0
	neck.rotation = 0.0
	skull.rotation = 0.0

	upper_arm_l.rotation = deg_to_rad(-5)
	forearm_l.rotation = deg_to_rad(-15)

	upper_arm_r.rotation = deg_to_rad(20)
	forearm_r.rotation = deg_to_rad(-35)

func apply_idle_pose() -> void:
	var bob := sin(time * 2.0) * 2.0
	var sway := sin(time * 2.0) * deg_to_rad(4.0)
	var counter := sin(time * 2.0) * deg_to_rad(2.0)

	hip.position.y += bob
	torso.rotation += sway * 0.5
	neck.rotation += -counter
	skull.rotation += counter

	upper_arm_l.rotation += sway
	forearm_l.rotation += sway * 0.5

	upper_arm_r.rotation += -sway
	forearm_r.rotation += -sway * 0.5

func apply_attack_pose() -> void:
	if not is_attacking:
		return

	var t := attack_time / attack_duration
	var swing := sin(t * PI)

	upper_arm_r.rotation += deg_to_rad(-80) * swing
	forearm_r.rotation += deg_to_rad(-20) * swing

func apply_constraints() -> void:
	clamp_bone_deg(neck, -25.0, 25.0)
	clamp_bone_deg(skull, -35.0, 35.0)

	clamp_bone_deg(upper_arm_l, -90.0, 90.0)
	clamp_bone_deg(forearm_l, -145.0, 0.0)

	clamp_bone_deg(upper_arm_r, -90.0, 90.0)
	clamp_bone_deg(forearm_r, -145.0, 0.0)

func clamp_bone_deg(bone: Bone2D, min_deg: float, max_deg: float) -> void:
	var deg := rad_to_deg(bone.rotation)
	deg = clamp(deg, min_deg, max_deg)
	bone.rotation = deg_to_rad(deg)

func cache_bones() -> void:
	bone_map.clear()

	var bones := [
		hip,
		torso,
		neck,
		skull,
		upper_arm_l,
		forearm_l,
		upper_arm_r,
		forearm_r,
	]

	for bone in bones:
		bone_map[bone.name] = bone
