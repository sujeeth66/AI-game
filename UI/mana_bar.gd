extends ProgressBar

var mana = 0 : set = _set_mana
var max_mana = 0

func _set_mana(new_mana):
	mana = clamp(new_mana, 0, max_mana)
	value = mana
	if mana <= 0:
		queue_free()
		
func init_mana(_mana):
	max_mana = _mana
	max_value = _mana
	mana = _mana
	value = _mana
