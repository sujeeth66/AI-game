extends ProgressBar

var stamina = 0 : set = _set_stamina
var max_stamina = 0

func _set_stamina(new_stamina):
	stamina = clamp(new_stamina, 0, max_stamina)
	value = stamina
	if stamina <= 0:
		queue_free()
	
func init_stamina(_stamina):
	max_stamina = _stamina
	max_value = _stamina
	stamina = _stamina
	value = _stamina
	
