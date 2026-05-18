extends Node2D
class_name Pickup

func _ready():
	add_to_group("pickup")

func interact(target):
	print("Item used!")
	queue_free()
