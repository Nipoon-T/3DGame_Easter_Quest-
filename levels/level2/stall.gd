@tool
extends Node3D
## ซุ้มขายของ — ตั้งสีและข้อความป้ายใน Inspector ได้ ใช้ scene เดียวทำได้หลายซุ้ม
## ด้านหน้าซุ้มคือแกน +Z (หมุนด้วย rotation.y ตอนวางในด่าน)

const U := preload("res://levels/level2/util.gd")
const WOOD := Color("7A4A22")

@export var stall_text: String = "ICE CREAM":
	set(value):
		stall_text = value
		_apply()
@export var main_color: Color = Color("F2B8DC"):
	set(value):
		main_color = value
		_apply()
@export var alt_color: Color = Color("FFF6E0"):
	set(value):
		alt_color = value
		_apply()


func _ready() -> void:
	_apply()


func _apply() -> void:
	if not is_node_ready():
		return
	(%Awning as MeshInstance3D).material_override = U.stripes(main_color, alt_color, 8.0, false)
	(%Counter as MeshInstance3D).material_override = U.flat(main_color)
	(%SignBoard as MeshInstance3D).material_override = U.flat(alt_color)
	(%Label as Label3D).text = stall_text
	(%Label as Label3D).modulate = WOOD
	U.fit_label(%Label as Label3D, 2.3, 0.42, 56)
