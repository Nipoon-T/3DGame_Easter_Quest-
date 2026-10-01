extends Area3D
## จุดเก็บ Hint ที่ซ่อนไว้ในด่าน — เดินชนแล้วได้ Hint เพิ่ม
## วิธีใช้: สร้าง Area3D + CollisionShape3D + โมเดลอะไรก็ได้ แล้วแปะ script นี้

@export var hint_amount := 1


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		GameManager.add_hint(hint_amount)
		queue_free()
