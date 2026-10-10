extends RefCounted
## ตัวช่วยวาดไกด์ปุ่มควบคุม ใช้ร่วมกันระหว่าง controls_panel (แผงเต็ม) และ HUD (การ์ดย่อ)
## ชื่อปุ่มอ่านจาก InputMap ตอนรันจริง ถ้าไม่มี action ใช้ปุ่มสำรองที่โค้ดเกมใช้จริง
## (GameManager: hint = H, pause = P / player.gd: Esc = ปล่อยเมาส์)

const BROWN := Color("7a4a22")
const CREAM := Color("fff6e0")

## kind: "wasd" | "mouse" | "key"   action/fallback ใช้กับ kind "key"
## compact = true จะอยู่ในการ์ดย่อบน HUD
const ENTRIES: Array[Dictionary] = [
	{"name": "Move", "kind": "wasd", "compact": true},
	{"name": "Look", "kind": "mouse", "compact": true},
	{"name": "Jump", "kind": "key", "action": &"jump", "fallback": KEY_SPACE, "compact": true},
	{"name": "Sprint", "kind": "key", "action": &"sprint", "fallback": KEY_SHIFT, "compact": true},
	{"name": "Pick up egg", "kind": "key", "action": &"interact", "fallback": KEY_E, "compact": true},
	{"name": "Hint", "kind": "key", "action": &"hint", "fallback": KEY_H, "compact": false},
	{"name": "Pause", "kind": "key", "action": &"pause", "fallback": KEY_P, "compact": false},
	{"name": "Free mouse", "kind": "key", "action": &"", "fallback": KEY_ESCAPE, "compact": false},
]


## ชื่อปุ่มของ action จาก InputMap (เฉพาะปุ่มคีย์บอร์ด) ถ้าไม่มีใช้ fallback
static func key_text(action: StringName, fallback: Key) -> String:
	if action != &"" and InputMap.has_action(action):
		for event in InputMap.action_get_events(action):
			if event is InputEventKey:
				var key := event as InputEventKey
				var code: Key = key.keycode
				if code == KEY_NONE:
					code = key.physical_keycode
					# แปลงเป็นตัวอักษรตามเลย์เอาต์คีย์บอร์ดจริง (headless ไม่รองรับ ใช้ค่าตรง ๆ)
					if DisplayServer.get_name() != "headless":
						code = DisplayServer.keyboard_get_keycode_from_physical(code)
				return _short_name(code)
	return _short_name(fallback)


static func _short_name(code: Key) -> String:
	if code == KEY_ESCAPE:
		return "ESC"
	return OS.get_keycode_string(code).to_upper()


## แถวหนึ่ง: [รูปปุ่ม] [ชื่อท่า]
static func build_row(entry: Dictionary, font: Font, key_size: int, label_size: int,
		key_column_width: float, label_color: Color) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 20)
	row.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	var keys := HBoxContainer.new()
	keys.mouse_filter = Control.MOUSE_FILTER_IGNORE
	keys.custom_minimum_size = Vector2(key_column_width, 0)
	keys.alignment = BoxContainer.ALIGNMENT_CENTER
	match entry["kind"]:
		"wasd":
			keys.add_child(make_wasd(font, key_size))
		"mouse":
			keys.add_child(make_mouse_icon(key_size))
		_:
			keys.add_child(make_keycap(key_text(entry["action"], entry["fallback"]), font, key_size))
	row.add_child(keys)

	var label := Label.new()
	label.text = entry["name"]
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if font:
		label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", label_size)
	label.add_theme_color_override("font_color", label_color)
	row.add_child(label)
	return row


## keycap สีครีม มุมมน ขอบน้ำตาล ขอบล่างหนากว่าให้ดูนูน  ปุ่มยาว (Shift/Space) กว้างกว่าปกติ
static func make_keycap(text: String, font: Font, key_size: int) -> PanelContainer:
	var cap := PanelContainer.new()
	cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var wide := text.length() > 1
	cap.custom_minimum_size = Vector2(key_size * (2.4 if wide else 1.0), key_size)

	var box := StyleBoxFlat.new()
	box.bg_color = CREAM
	box.set_corner_radius_all(roundi(key_size * 0.22))
	box.set_border_width_all(3)
	box.border_width_bottom = maxi(roundi(key_size * 0.16), 6)   # ด้านล่างหนา = เงาให้ปุ่มนูน
	box.border_color = BROWN
	box.shadow_color = Color(0, 0, 0, 0.25)
	box.shadow_size = 3
	box.shadow_offset = Vector2(0, 3)
	box.set_content_margin_all(2)
	cap.add_theme_stylebox_override("panel", box)

	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if font:
		label.add_theme_font_override("font", font)
	var fs := roundi(key_size * (0.46 if wide else 0.55))
	label.add_theme_font_size_override("font_size", fs)
	label.add_theme_color_override("font_color", BROWN)
	cap.add_child(label)
	return cap


## WASD แบบแป้นจริง: W อยู่บน A S D อยู่ล่าง
static func make_wasd(font: Font, key_size: int) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 4)
	var top := HBoxContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.alignment = BoxContainer.ALIGNMENT_CENTER
	top.add_child(make_keycap(key_text(&"move_forward", KEY_W), font, key_size))
	box.add_child(top)
	var bottom := HBoxContainer.new()
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom.add_theme_constant_override("separation", 4)
	bottom.add_child(make_keycap(key_text(&"move_left", KEY_A), font, key_size))
	bottom.add_child(make_keycap(key_text(&"move_back", KEY_S), font, key_size))
	bottom.add_child(make_keycap(key_text(&"move_right", KEY_D), font, key_size))
	box.add_child(bottom)
	return box


static func make_mouse_icon(key_size: int) -> Control:
	var icon := MouseIcon.new()
	icon.custom_minimum_size = Vector2(key_size * 0.8, key_size * 1.1)
	return icon


## ไอคอนเมาส์วาดด้วยโค้ด
class MouseIcon extends Control:
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var w := size.x
		var h := size.y
		var body := StyleBoxFlat.new()
		body.bg_color = CREAM
		body.set_corner_radius_all(roundi(w * 0.5))
		body.set_border_width_all(3)
		body.border_color = BROWN
		draw_style_box(body, Rect2(Vector2.ZERO, size))
		# เส้นแบ่งปุ่มซ้าย/ขวา และลูกกลิ้ง
		draw_line(Vector2(0, h * 0.42), Vector2(w, h * 0.42), BROWN, 3.0)
		draw_line(Vector2(w * 0.5, 2), Vector2(w * 0.5, h * 0.42), BROWN, 3.0)
		var wheel := StyleBoxFlat.new()
		wheel.bg_color = BROWN
		wheel.set_corner_radius_all(4)
		draw_style_box(wheel, Rect2(w * 0.5 - 3, h * 0.12, 6, h * 0.2))
