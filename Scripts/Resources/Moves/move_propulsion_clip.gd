extends Resource
class_name MovePropulsionClip

@export var keys: Array[MovePropulsionKey] = []

func sample(normalized_time: float) -> Vector2:
	if keys.is_empty():
		return Vector2.ZERO

	if keys.size() == 1:
		return keys[0].velocity

	var sorted_keys := keys.duplicate()
	sorted_keys.sort_custom(func(a: MovePropulsionKey, b: MovePropulsionKey): return a.time < b.time)

	if normalized_time <= sorted_keys[0].time:
		return sorted_keys[0].velocity

	var last: MovePropulsionKey = sorted_keys[sorted_keys.size() - 1]
	if normalized_time >= last.time:
		return last.velocity

	for i in range(sorted_keys.size() - 1):
		var a: MovePropulsionKey = sorted_keys[i]
		var b: MovePropulsionKey = sorted_keys[i + 1]

		if normalized_time >= a.time and normalized_time <= b.time:
			var span := b.time - a.time
			if is_zero_approx(span):
				return b.velocity

			var local_t := (normalized_time - a.time) / span
			return a.velocity.lerp(b.velocity, local_t)

	return last.velocity
