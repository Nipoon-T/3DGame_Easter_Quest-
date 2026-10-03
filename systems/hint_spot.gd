extends Area3D
## จุดเก็บ Hint ที่ซ่อนไว้ในด่าน — เดินชนแล้วได้ Hint เพิ่ม
## วิธีใช้: ลาก systems/hint_spot.tscn เข้าด่าน (หรือสร้าง Area3D + CollisionShape3D เองแล้วแปะ script นี้)

@export var hint_amount := 1
@export var spin_speed := 1.5   ## หมุน node ลูกชื่อ "Visual" (ถ้ามี)

@onready var _visual: Node3D = get_node_or_null("Visual")


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	if _visual:
		_visual.rotate_y(spin_speed * delta)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		GameManager.add_hint(hint_amount)
		queue_free()
