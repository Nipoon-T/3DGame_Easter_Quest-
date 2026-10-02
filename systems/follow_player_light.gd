extends OmniLight3D
## แสงสลัวรอบตัวผู้เล่น ช่วยให้ห้องมืดไม่มืดสนิทจนเล่นไม่ได้
## ไม่ได้แก้ Player — แค่ตามตำแหน่ง node ใน group "player"
## (ถ้าคนที่ 1 ทำไฟฉายติดตัวผู้เล่นแล้ว ลบ node นี้ออกจากด่านได้เลย)

@export var offset := Vector3(0, 1.7, 0)


func _process(_delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player:
		global_position = player.global_position + offset
