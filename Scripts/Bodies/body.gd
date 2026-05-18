extends Node2D
class_name Body

@export var default_clip: AnimationClip
@export var idle_enabled: bool = true
@export var hitbox_scene: PackedScene

var active_hitboxes: Array = []
var sprite_variant_map: Dictionary = {}
var default_part_z: Dictionary = {}
var default_part_position: Dictionary = {}

var equipped_weapon: Equipment = null
var equipped_shield: Equipment = null

var current_clip: AnimationClip = null
var current_move: Move = null

var clip_time: float = 0.0
var move_time: float = 0.0

var is_playing_clip: bool = false
var is_playing_move: bool = false

var owner_character = null
var move_input: Vector2 = Vector2.ZERO
var facing: int = 1

var attachment_map: Dictionary = {}

func _ready() -> void:
	cache_parts()

	if default_clip != null:
		play_clip(default_clip, true)

func _process(delta: float) -> void:
	apply_rest_pose()

	if is_moving():
		apply_locomotion_pose(delta)
	elif idle_enabled:
		apply_idle_pose(delta)

	if is_playing_move and current_move != null:
		update_move(delta)
		apply_current_move()
	elif is_playing_clip and current_clip != null:
		update_clip(delta)
		apply_current_clip()

	apply_constraints()
	apply_facing()

func cache_parts() -> void:
	pass

func apply_rest_pose() -> void:
	pass

func apply_idle_pose(_delta: float) -> void:
	pass

func apply_current_clip() -> void:
	if current_clip == null:
		return

	apply_clip(current_clip, get_clip_normalized_time())

func apply_current_move() -> void:
	if current_move == null:
		return

	if current_move.animation_clip != null:
		apply_clip(current_move.animation_clip, get_move_normalized_time())

func apply_constraints() -> void:
	pass

func apply_locomotion_pose(_delta: float) -> void:
	pass

func set_owner_character(value) -> void:
	owner_character = value
	assign_hurtbox_owners()

func assign_hurtbox_owners() -> void:
	for child in find_children("*"):
		if child is Hurtbox:
			child.owner_character = owner_character

func is_moving() -> bool:
	return move_input.length() > 0.01

func play_clip(clip: AnimationClip, restart: bool = true) -> void:
	if clip == null:
		return

	current_move = null
	is_playing_move = false
	move_time = 0.0
	clear_active_hitboxes()

	current_clip = clip
	is_playing_clip = true

	if restart:
		clip_time = 0.0

func play_move(move: Move, restart: bool = true) -> void:
	if move == null:
		return

	current_clip = move.animation_clip
	current_move = move

	is_playing_clip = false
	is_playing_move = true

	if restart:
		clip_time = 0.0
		move_time = 0.0

	clear_active_hitboxes()
	setup_move_hitboxes(move)

func stop_clip() -> void:
	is_playing_clip = false
	current_clip = null
	clip_time = 0.0

func stop_move() -> void:
	is_playing_move = false
	current_move = null
	move_time = 0.0
	clear_active_hitboxes()

func update_clip(delta: float) -> void:
	if current_clip == null:
		return

	clip_time += delta

	if clip_time > current_clip.duration:
		if current_clip.looping:
			clip_time = 0.0
		else:
			clip_time = current_clip.duration
			is_playing_clip = false

func update_move(delta: float) -> void:
	if current_move == null:
		return

	move_time += delta
	clip_time = move_time

	update_move_hitboxes()

	if move_time > current_move.duration:
		move_time = current_move.duration
		is_playing_move = false
		clear_active_hitboxes()

func get_clip_normalized_time() -> float:
	if current_clip == null or current_clip.duration <= 0.0:
		return 0.0
	return clamp(clip_time / current_clip.duration, 0.0, 1.0)

func get_move_normalized_time() -> float:
	if current_move == null or current_move.duration <= 0.0:
		return 0.0
	return clamp(move_time / current_move.duration, 0.0, 1.0)

func set_move_input(value: Vector2) -> void:
	move_input = value

func set_facing(value: int) -> void:
	if value == 0:
		return
	facing = sign(value)

func apply_facing() -> void:
	scale.x = facing

func apply_part_presentation(part_name: StringName, sprite_mode: StringName, skew_degrees: float, z_index_offset: int, position_offset: Vector2) -> void:
	pass

func get_current_movement_multiplier() -> Vector2:
	if is_playing_move and current_move != null:
		return current_move.movement_multiplier
	return Vector2.ONE

func get_current_propulsion_velocity() -> Vector2:
	if not is_playing_move or current_move == null:
		return Vector2.ZERO

	if current_move.propulsion == null:
		return Vector2.ZERO

	return current_move.propulsion.sample(get_move_normalized_time())

func setup_move_hitboxes(move: Move) -> void:
	if move == null or hitbox_scene == null:
		return

	active_hitboxes.clear()

	for definition in move.hitboxes:
		var attachment_node: Node2D = attachment_map.get(definition.attachment_point)
		if attachment_node == null:
			push_warning("Missing attachment point: %s" % definition.attachment_point)
			continue

		var hitbox := hitbox_scene.instantiate() as Hitbox
		if hitbox == null:
			push_warning("Failed to instantiate hitbox scene.")
			continue

		attachment_node.add_child(hitbox)
		hitbox.configure_from_definition(definition, owner_character)

		active_hitboxes.append({
			"hitbox": hitbox,
			"definition": definition
		})

func update_move_hitboxes() -> void:
	for entry in active_hitboxes:
		var hitbox: Hitbox = entry["hitbox"]
		var definition: HitboxDefinition = entry["definition"]

		if hitbox == null or definition == null:
			continue

		var should_be_active := hitbox.is_active_at_time(move_time, definition)

		if should_be_active and not hitbox.is_active():
			hitbox.activate()
		elif not should_be_active and hitbox.is_active():
			hitbox.deactivate()

func clear_active_hitboxes() -> void:
	for entry in active_hitboxes:
		var hitbox: Hitbox = entry["hitbox"]
		if hitbox != null and is_instance_valid(hitbox):
			hitbox.queue_free()

	active_hitboxes.clear()

func equip_weapon_scene(scene: PackedScene) -> Equipment:
	if equipped_weapon != null and is_instance_valid(equipped_weapon):
		_unregister_equipment(&"Weapon", equipped_weapon)
		equipped_weapon.queue_free()
		equipped_weapon = null

	if scene == null:
		return null

	var instance := scene.instantiate() as Equipment
	if instance == null:
		push_warning("Failed to instantiate weapon equipment scene.")
		return null

	if not _attach_equipment(instance):
		instance.queue_free()
		return null

	equipped_weapon = instance
	_register_equipment(&"Weapon", instance)
	return equipped_weapon

func equip_shield_scene(scene: PackedScene) -> Equipment:
	if equipped_shield != null and is_instance_valid(equipped_shield):
		_unregister_equipment(&"Shield", equipped_shield)
		equipped_shield.queue_free()
		equipped_shield = null

	if scene == null:
		return null

	var instance := scene.instantiate() as Equipment
	if instance == null:
		push_warning("Failed to instantiate shield equipment scene.")
		return null

	if not _attach_equipment(instance):
		instance.queue_free()
		return null

	equipped_shield = instance
	_register_equipment(&"Shield", instance)
	return equipped_shield

func _attach_equipment(equipment: Equipment) -> bool:
	if equipment == null or equipment.data == null:
		push_warning("Equipment or EquipmentData is missing.")
		return false

	var attach: Node2D = attachment_map.get(equipment.data.attachment_point)
	if attach == null:
		push_warning("Missing attachment point: %s" % equipment.data.attachment_point)
		return false

	attach.add_child(equipment)
	equipment.apply_data_transform()
	return true

func _register_equipment(part_name: StringName, equipment: Equipment) -> void:
	if equipment == null:
		return

	attachment_map[part_name] = equipment
	sprite_variant_map[part_name] = equipment.get_sprite_variants()
	default_part_z[part_name] = equipment.z_index
	default_part_position[part_name] = equipment.position

func _unregister_equipment(part_name: StringName, equipment: Equipment) -> void:
	if attachment_map.get(part_name) == equipment:
		attachment_map.erase(part_name)

	if sprite_variant_map.has(part_name):
		sprite_variant_map.erase(part_name)

	if default_part_z.has(part_name):
		default_part_z.erase(part_name)

	if default_part_position.has(part_name):
		default_part_position.erase(part_name)

func sample_track(track: BoneTrack, normalized_time: float) -> Dictionary:
	if track.keyframes.is_empty():
		return {
			"rotation_degrees": 0.0,
			"skew_degrees": 0.0,
			"sprite_mode": &"default",
			"z_index_offset": 0,
			"position_offset": Vector2.ZERO
		}

	if track.keyframes.size() == 1:
		return {
			"rotation_degrees": track.keyframes[0].rotation_degrees,
			"skew_degrees": track.keyframes[0].skew_degrees,
			"sprite_mode": track.keyframes[0].sprite_mode,
			"z_index_offset": track.keyframes[0].z_index_offset,
			"position_offset": track.keyframes[0].position_offset
		}

	var keys := track.keyframes

	if normalized_time <= keys[0].time:
		return {
			"rotation_degrees": keys[0].rotation_degrees,
			"skew_degrees": keys[0].skew_degrees,
			"sprite_mode": keys[0].sprite_mode,
			"z_index_offset": keys[0].z_index_offset,
			"position_offset": keys[0].position_offset
		}

	if normalized_time >= keys[keys.size() - 1].time:
		var last := keys[keys.size() - 1]
		return {
			"rotation_degrees": last.rotation_degrees,
			"skew_degrees": last.skew_degrees,
			"sprite_mode": last.sprite_mode,
			"z_index_offset": last.z_index_offset,
			"position_offset": last.position_offset
		}

	for i in range(keys.size() - 1):
		var a: BoneKeyframe = keys[i]
		var b: BoneKeyframe = keys[i + 1]

		if normalized_time >= a.time and normalized_time <= b.time:
			var span := b.time - a.time
			if is_zero_approx(span):
				return {
					"rotation_degrees": b.rotation_degrees,
					"skew_degrees": b.skew_degrees,
					"sprite_mode": b.sprite_mode,
					"z_index_offset": b.z_index_offset,
					"position_offset": b.position_offset
				}

			var local_t := (normalized_time - a.time) / span

			return {
				"rotation_degrees": lerp(a.rotation_degrees, b.rotation_degrees, local_t),
				"skew_degrees": lerp(a.skew_degrees, b.skew_degrees, local_t),
				"sprite_mode": a.sprite_mode,
				"z_index_offset": a.z_index_offset,
				"position_offset": a.position_offset.lerp(b.position_offset, local_t)
			}

	var fallback := keys[keys.size() - 1]
	return {
		"rotation_degrees": fallback.rotation_degrees,
		"skew_degrees": fallback.skew_degrees,
		"sprite_mode": fallback.sprite_mode,
		"z_index_offset": fallback.z_index_offset,
		"position_offset": fallback.position_offset
	}

func apply_clip(clip: AnimationClip, normalized_time: float) -> void:
	normalized_time = clamp(normalized_time, 0.0, 1.0)

	for track in clip.tracks:
		var part: Node2D = attachment_map.get(track.bone_name)
		if part == null:
			continue

		var sampled := sample_track(track, normalized_time)
		var rotation_deg: float = sampled["rotation_degrees"]
		var skew_deg: float = sampled["skew_degrees"]
		var sprite_mode: StringName = sampled["sprite_mode"]
		var z_index_offset: int = sampled["z_index_offset"]
		var position_offset: Vector2 = sampled["position_offset"]

		if clip.additive:
			part.rotation += deg_to_rad(rotation_deg)
		else:
			part.rotation = deg_to_rad(rotation_deg)

		apply_part_presentation(track.bone_name, sprite_mode, skew_deg, z_index_offset, position_offset)
