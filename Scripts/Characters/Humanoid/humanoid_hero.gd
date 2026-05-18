extends HumanoidCharacter
class_name HumanoidHero

var mana: float = 0.0

func _ready() -> void:
	super._ready()

	if stats is HeroStats:
		mana = stats.max_mana

func can_carry_throwables() -> bool:
	return true

func get_max_mana() -> float:
	if stats is HeroStats:
		return (stats as HeroStats).max_mana
	return 0.0
