extends Pickup
class_name HealthPotion

func interact(actor):
	print("Healed target!")
	queue_free()
