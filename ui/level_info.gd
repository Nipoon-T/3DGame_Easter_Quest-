extends Resource
## ข้อมูลของ 1 เลเวลบนแผนที่ (ใช้กับ level_map.gd)
## เพิ่มเลเวลใหม่ = เพิ่มข้อมูลชุดนี้ใน Inspector ของ LevelMap > Levels ไม่ต้องแก้โค้ด

## ชื่อเลเวล (โชว์ใต้ปุ่มและในแผงยืนยัน)
@export var level_name: String = "Coming Soon"
## คำอธิบายสั้น ๆ (โชว์ในแผงยืนยัน)
@export var description: String = ""
## true = เล่นได้ / false = ล็อก (โชว์กุญแจ กดแล้วขึ้น Coming Soon!)
@export var unlocked: bool = false
## ตำแหน่งจุดกลางปุ่มบนภาพแผนที่ เป็นสัดส่วน 0..1 (x, y)
@export var map_position: Vector2 = Vector2(0.5, 0.5)
