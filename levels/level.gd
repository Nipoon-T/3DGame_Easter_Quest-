extends Node3D
## แปะ script นี้ที่ node รากของทุกด่าน (รวมถึง final_area.tscn)
## แล้วตั้งค่าใน Inspector ได้เลย ไม่ต้องแก้โค้ด

@export var time_limit := 180.0   ## เวลาของด่าน (วินาที) ใส่ 0 = ไม่จับเวลา (เช่นพื้นที่สุดท้าย)
@export var eggs_required := 0    ## จำนวนไข่ที่ต้องเก็บ ใส่ 0 = ต้องเก็บทุกใบในด่าน


func _ready() -> void:
	# node ลูก (ไข่ทั้งหมด) _ready ก่อน node พ่อเสมอ จึงนับไข่ได้ครบตรงนี้
	GameManager.start_level(self, time_limit, eggs_required)
