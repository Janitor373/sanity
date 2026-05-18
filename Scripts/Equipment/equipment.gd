extends Node2D
class_name Equipment

@export var data: EquipmentData

func get_sprite_variants() -> Dictionary:
	var variants: Dictionary = {}

	for child in get_children():
		if child is Sprite2D:
			variants[StringName(child.name.to_lower())] = child

	return variants

func apply_data_transform() -> void:
	if data == null:
		return

	position = data.local_offset
	rotation = deg_to_rad(data.local_rotation_degrees)
	z_index = data.local_z_index_offset

func get_equipment_type() -> int:
	if data == null:
		return EquipmentData.EquipmentType.NONE
	return data.equipment_type

func get_attachment_point() -> StringName:
	if data == null:
		return &""
	return data.attachment_point
