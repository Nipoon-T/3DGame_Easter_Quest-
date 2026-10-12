@tool
extends Node3D
## ป้ายบอกทาง — ตั้งข้อความผ่าน @export (ด้านหน้าคือแกน +Z) ตัวหนังสือย่อให้พอดีแผ่นป้ายอัตโนมัติ

const U := preload("res://levels/level2/util.gd")

@export var sign_text: String = "THIS WAY":
	set(value):
		sign_text = value
		_apply()


func _ready() -> void:
	_apply()


func _apply() -> void:
	if not is_node_ready():
		return
	(%Label as Label3D).text = sign_text
	U.fit_label(%Label as Label3D, 1.6, 0.6, 40)
