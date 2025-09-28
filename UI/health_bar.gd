extends ProgressBar

var health = 0 : set = _set_health
var max_health = 0

func _set_health(new_health):
	health = clamp(new_health, 0, max_health)
	value = health
	if health <= 0:
		queue_free()
		
func init_health(_health):
	max_health = _health
	max_value = _health
	health = _health
	value = _health
