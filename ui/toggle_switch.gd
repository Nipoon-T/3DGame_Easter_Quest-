extends Button
## สวิตช์มนสีพาสเทล วาดด้วยโค้ด (เปิด = มินต์, ปิด = เทาอมครีม)
## ใช้ toggle_mode ของ Button: Enter / คลิก สลับค่า, สัญญาณ toggled(on) ตามปกติ

@export var on_color := Color("a8e6cf")
@export var off_color := Color("d9d2bf")
@export var border_color := Color("7a4a22")
@export var knob_color := Color("fff6e0")

var _t := 0.0   # 0 = ปิด, 1 = เปิด (ใช้เลื่อนปุ่มกลมแบบนุ่ม ๆ)
var _tween: Tween


func _ready() -> void:
	toggle_mode = true
	flat = true
	focus_mode = Control.FOCUS_ALL
	custom_minimum_size = Vector2(150, 76)
	var empty := StyleBoxEmpty.new()
	for s in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		add_theme_stylebox_override(s, empty)
	add_theme_stylebox_override("focus", _focus_box())
	toggled.connect(_on_toggled)
	resized.connect(func() -> void: pivot_offset = size / 2.0)
	mouse_entered.connect(_hover.bind(true))
	mouse_exited.connect(_hover.bind(false))
	focus_entered.connect(_hover.bind(true))
	focus_exited.connect(_hover.bind(false))
	_t = 1.0 if button_pressed else 0.0


## ตั้งค่าโดยไม่ยิง signal และไม่เล่นอนิเมชัน (ใช้ตอนเปิดแผง)
func set_on(on: bool) -> void:
	set_pressed_no_signal(on)
	_t = 1.0 if on else 0.0
	queue_redraw()


func _on_toggled(on: bool) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_method(_set_t, _t, 1.0 if on else 0.0, 0.14)


func _set_t(value: float) -> void:
	_t = value
	queue_redraw()


func _hover(hovered: bool) -> void:
	create_tween().tween_property(self, "scale", Vector2.ONE * (1.06 if hovered else 1.0), 0.12) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _draw() -> void:
	var h := size.y
	var track := StyleBoxFlat.new()
	track.bg_color = off_color.lerp(on_color, _t)
	track.set_corner_radius_all(roundi(h / 2.0))
	track.set_border_width_all(5)
	track.border_color = border_color
	draw_style_box(track, Rect2(Vector2.ZERO, size))

	var r := h / 2.0 - 12.0
	var x := lerpf(h / 2.0, size.x - h / 2.0, _t)
	var c := Vector2(x, h / 2.0)
	draw_circle(c + Vector2(0, 3), r, Color(0, 0, 0, 0.18))
	draw_circle(c, r + 3.0, border_color)
	draw_circle(c, r, knob_color)


func _focus_box() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.draw_center = false
	box.set_corner_radius_all(44)
	box.set_border_width_all(4)
	box.border_color = Color("f7a39a")
	box.set_expand_margin_all(6)
	return box
