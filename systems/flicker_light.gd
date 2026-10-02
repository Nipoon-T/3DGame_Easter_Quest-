extends Light3D
## ไฟกะพริบแบบหลอดไฟเก่า — แปะกับ OmniLight3D / SpotLight3D ได้เลย

@export var min_energy := 0.15
@export var max_energy := 1.0
@export var flicker_chance := 0.06   ## โอกาสกะพริบต่อเฟรม

var _base := 1.0


func _ready() -> void:
	_base = light_energy


func _process(_delta: float) -> void:
	if randf() < flicker_chance:
		light_energy = _base * randf_range(min_energy, max_energy * 0.6)
	else:
		light_energy = lerpf(light_energy, _base * max_energy, 0.15)
