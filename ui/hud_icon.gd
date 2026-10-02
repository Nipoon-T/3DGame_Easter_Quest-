extends Control
## ไอคอนที่วาดด้วยโค้ด (ไม่ใช้ไฟล์ภาพ) ใช้ใน HUD: ไข่ และ พระอาทิตย์

enum Kind { EGG, SUN }

@export var kind: Kind = Kind.EGG:
	set(value):
		kind = value
		queue_redraw()
@export var fill_color := Color("f2b8dc"):
	set(value):
		fill_color = value
		queue_redraw()
@export var outline_color := Color("7a4a22"):
	set(value):
		outline_color = value
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	match kind:
		Kind.EGG:
			_draw_egg()
		Kind.SUN:
			_draw_sun()


func _draw_egg() -> void:
	var w := size.x
	var h := size.y
	# ไข่ = วงรีสูง ส่วนบนเรียวกว่าล่างเล็กน้อย
	var pts := PackedVector2Array()
	for i in 40:
		var a := TAU * float(i) / 40.0
		var s := sin(a)
		var c := cos(a)
		var narrow := 1.0 - 0.18 * (-c) if c < 0.0 else 1.0   # ด้านบน (c<0) เรียวลง
		pts.append(Vector2(w * 0.5 + s * w * 0.40 * narrow, h * 0.52 + c * h * 0.44))
	draw_colored_polygon(pts, fill_color)
	var closed := pts.duplicate()
	closed.append(pts[0])
	draw_polyline(closed, outline_color, maxf(2.0, w * 0.07), true)
	# ลายคาดบนไข่
	var stripe := Color(1, 1, 1, 0.7)
	draw_line(Vector2(w * 0.2, h * 0.5), Vector2(w * 0.8, h * 0.5), stripe, maxf(2.0, w * 0.08))
	draw_circle(Vector2(w * 0.38, h * 0.72), w * 0.06, stripe)
	draw_circle(Vector2(w * 0.62, h * 0.72), w * 0.06, stripe)


func _draw_sun() -> void:
	var center := size * 0.5
	var r := minf(size.x, size.y) * 0.5
	var line_w := maxf(2.0, r * 0.16)
	# รังสี
	for i in 8:
		var dir := Vector2.from_angle(TAU * float(i) / 8.0)
		draw_line(center + dir * r * 0.66, center + dir * r * 0.96, outline_color, line_w * 1.8, true)
		draw_line(center + dir * r * 0.66, center + dir * r * 0.96, fill_color, line_w, true)
	# ตัวพระอาทิตย์
	draw_circle(center, r * 0.5, outline_color)
	draw_circle(center, r * 0.5 - line_w * 0.7, fill_color)
