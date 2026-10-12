extends Node3D
## ชิงช้าสวรรค์ A (ferris_wheel.glb ที่แยกชิ้นแล้ว) — วงล้อหมุนรอบแกน Z ส่วนกระเช้าห้อยตั้งตรงตลอด
## ขาอยู่นิ่ง มี collision เฉพาะขา

@export var seconds_per_rotation: float = 40.0   ## เวลาต่อรอบ (วินาที) ใส่ค่าติดลบ = หมุนกลับทิศ

@onready var _wheel: Node3D = %Wheel
@onready var _pivots: Array[Node] = %Cabins.get_children()


func _process(delta: float) -> void:
	if is_zero_approx(seconds_per_rotation):
		return
	_wheel.rotation.z = fmod(_wheel.rotation.z + TAU / seconds_per_rotation * delta, TAU)
	for p in _pivots:
		(p as Node3D).rotation.z = -_wheel.rotation.z
