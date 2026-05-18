extends Resource
class_name EquipmentData

enum EquipmentType {
	NONE,
	AXE,
	SWORD,
	SPEAR,
	SHIELD,
	DAGGER,
	BOW
}

@export var equipment_type: EquipmentType = EquipmentType.NONE
@export var attachment_point: StringName = &"HandRAttachmentPoint"
@export var local_offset: Vector2 = Vector2.ZERO
@export var local_rotation_degrees: float = 0.0
@export var local_z_index_offset: int = 0
