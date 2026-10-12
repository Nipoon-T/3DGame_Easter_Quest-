extends Control
## แผนที่เลือกเลเวล — ปุ่มวงกลมลอยบนภาพแผนที่ ข้อมูลเลเวลอยู่ใน @export levels (ดู level_info.gd)
## เลเวลที่ปลดล็อก: กดแล้วขึ้นแผงยืนยัน -> PLAY -> GameManager.start_new_game()
## เลเวลที่ล็อก: กดแล้วปุ่มสั่น + ป้าย "Coming Soon!"

const UIStyle := preload("res://ui/ui_style.gd")
const LevelInfo := preload("res://ui/level_info.gd")

const MAIN_MENU_SCENE := "res://ui/main_menu.tscn"

# ---------- ข้อมูลเลเวล ----------
@export var levels: Array[LevelInfo] = []

# ---------- หน้าตา ----------
@export var button_font: Font
@export var circle_size: float = 150.0
@export var number_font_size: int = 72
@export var name_font_size: int = 36
@export var panel_title_font_size: int = 52
@export var panel_desc_font_size: int = 30
@export var play_font_size: int = 48
@export var title_font_size: int = 88
@export var back_font_size: int = 44
@export var unlocked_color := Color("f7e08a")   # เหลือง (เลเวลที่เล่นได้)
@export var locked_color := Color("cfc8b4")     # เทาอมครีม (เลเวลที่ล็อก)
@export var play_color := Color("a8e6cf")       # มินต์ (ปุ่ม PLAY)
@export var back_color := Color("f2b8dc")       # ชมพู (ปุ่ม BACK)
@export var text_color := Color("fff6e0")       # ครีม
@export var border_color := Color("7a4a22")     # น้ำตาลไม้
@export var path_color := Color("fff6e0")       # เส้นประทางเดิน

@export var bounce_height: float = 9.0
@export var bounce_speed: float = 2.4           ## rad/s (ยิ่งน้อยยิ่งช้า)
@export var fade_time: float = 0.5

@onready var stage: Control = %Stage
@onready var path_layer: Control = %PathLayer
@onready var slot_layer: Control = %SlotLayer
@onready var confirm_panel: PanelContainer = %ConfirmPanel
@onready var panel_title: Label = %PanelTitle
@onready var panel_desc: Label = %PanelDesc
@onready var play_button: Button = %PlayButton
@onready var title_label: Label = %TitleLabel
@onready var back_button: Button = %BackButton
@onready var fade_rect: ColorRect = %FadeRect
@onready var hover_sound: AudioStreamPlayer = %HoverSound
@onready var click_sound: AudioStreamPlayer = %ClickSound

var _slots: Array[Control] = []
var _buttons: Array[Button] = []
var _lines: Array[Line2D] = []
var _bubbles: Dictionary = {}     # Button -> Label ป้าย Coming Soon! ที่กำลังโชว์
var _selected := -1               # เลเวลที่เปิดแผงยืนยันอยู่
var _time := 0.0
var _busy := false


func _ready() -> void:
	GameSettings.ensure_setup()
	# ตอนเล่นเมาส์ถูกซ่อนและเกมอาจ pause อยู่ ต้องคืนค่าไม่งั้นคลิกปุ่มไม่ได้
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = false

	_style_title()
	UIStyle.style_button(back_button, back_color, text_color, border_color, button_font, back_font_size)
	UIStyle.setup_hover(back_button, _on_hover)
	back_button.pressed.connect(_on_back_pressed)

	_build_confirm_panel()
	_build_levels()
	_set_focus_neighbors()

	stage.resized.connect(_layout_stage)
	_layout_stage()

	# ---- เฟดเข้า ----
	fade_rect.show()
	fade_rect.modulate.a = 1.0
	create_tween().tween_property(fade_rect, "modulate:a", 0.0, fade_time)

	# ให้เล่นด้วยคีย์บอร์ด/จอยได้ทันที: focus ที่ Level 1
	if not _buttons.is_empty():
		_buttons[0].grab_focus.call_deferred()


func _process(delta: float) -> void:
	# ปุ่มเลเวลที่เล่นได้เด้งขึ้นลงเบา ๆ ช้า ๆ ตลอด (ขยับ position ไม่ชนกับ scale ตอน hover)
	_time += delta
	var wave := (sin(_time * bounce_speed) - 1.0) * 0.5 * bounce_height   # 0 .. -bounce_height
	for i in _buttons.size():
		if levels[i].unlocked:
			_buttons[i].position.y = -circle_size / 2.0 + wave


# ============ สร้างหน้า ============

func _style_title() -> void:
	if button_font:
		title_label.add_theme_font_override("font", button_font)
	title_label.add_theme_font_size_override("font_size", title_font_size)
	title_label.add_theme_color_override("font_color", text_color)
	title_label.add_theme_color_override("font_outline_color", border_color)
	title_label.add_theme_constant_override("outline_size", 24)
	title_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.35))
	title_label.add_theme_constant_override("shadow_offset_y", 4)


func _build_levels() -> void:
	for i in levels.size():
		var info := levels[i]

		# slot = จุดอ้างอิงขนาด 0 อยู่ที่ anchor ของเลเวลนั้น (ปุ่ม/ป้ายเป็นลูกของมัน)
		var slot := Control.new()
		slot.name = "Level%d" % (i + 1)
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.anchor_left = info.map_position.x
		slot.anchor_right = info.map_position.x
		slot.anchor_top = info.map_position.y
		slot.anchor_bottom = info.map_position.y
		slot_layer.add_child(slot)

		var button := Button.new()
		button.name = "Button"
		button.size = Vector2.ONE * circle_size
		button.position = -button.size / 2.0
		button.focus_mode = Control.FOCUS_ALL
		button.tooltip_text = info.level_name if info.unlocked else "Coming Soon"
		_style_circle(button, info.unlocked)
		slot.add_child(button)

		if info.unlocked:
			button.text = str(i + 1)
			var name_label := _make_name_label(info.level_name)
			name_label.name = "NameLabel"
			button.add_child(name_label)
		else:
			var lock := Control.new()
			lock.name = "Lock"
			lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
			lock.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			lock.draw.connect(_draw_lock.bind(lock))
			button.add_child(lock)

		UIStyle.setup_hover(button, _on_hover)
		button.pivot_offset = button.size / 2.0
		button.pressed.connect(_on_level_pressed.bind(i))

		_slots.append(slot)
		_buttons.append(button)

	# เส้นทางเดิน 1 -> 2 -> ... (เส้นที่ออกจากเลเวลที่ล็อกจะจางลง)
	var dash := _make_dash_texture()
	for i in range(levels.size() - 1):
		var line := Line2D.new()
		line.name = "Path%d" % (i + 1)
		line.texture = dash
		line.texture_mode = Line2D.LINE_TEXTURE_TILE
		line.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		line.width = 9.0
		line.antialiased = true
		line.default_color = path_color if levels[i].unlocked else Color(path_color, 0.35)
		path_layer.add_child(line)
		_lines.append(line)


func _style_circle(button: Button, unlocked: bool) -> void:
	var base := unlocked_color if unlocked else locked_color
	var states := {
		"normal": [base, false],
		"hover": [base.lightened(0.15), false],
		"pressed": [base.darkened(0.12), true],
	}
	for state: String in states:
		var box := UIStyle.make_box(states[state][0], border_color, states[state][1])
		box.set_corner_radius_all(999)
		box.set_border_width_all(7)
		box.set_content_margin_all(0)
		button.add_theme_stylebox_override(state, box)
	var focus := UIStyle.make_focus_box()
	focus.set_corner_radius_all(999)
	focus.set_expand_margin_all(8)
	button.add_theme_stylebox_override("focus", focus)

	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, border_color)
	if button_font:
		button.add_theme_font_override("font", button_font)
	button.add_theme_font_size_override("font_size", number_font_size)


func _make_name_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.custom_minimum_size = Vector2(420, 0)
	label.size = Vector2(420, 50)
	label.position = Vector2((circle_size - 420.0) / 2.0, circle_size + 10.0)
	if button_font:
		label.add_theme_font_override("font", button_font)
	label.add_theme_font_size_override("font_size", name_font_size)
	label.add_theme_color_override("font_color", text_color)
	label.add_theme_color_override("font_outline_color", border_color)
	label.add_theme_constant_override("outline_size", 14)
	return label


## รูปกุญแจวาดด้วยโค้ด (ไม่ใช้ไฟล์ภาพ) ตัวกุญแจสีน้ำตาล รูกุญแจสีครีม
func _draw_lock(lock: Control) -> void:
	var c := lock.size / 2.0
	var shackle_r := 20.0
	var shackle_center := c + Vector2(0, -8)
	lock.draw_arc(shackle_center, shackle_r, PI, TAU, 24, border_color, 9.0, true)
	lock.draw_line(shackle_center + Vector2(-shackle_r, 0), shackle_center + Vector2(-shackle_r, 14), border_color, 9.0)
	lock.draw_line(shackle_center + Vector2(shackle_r, 0), shackle_center + Vector2(shackle_r, 14), border_color, 9.0)

	var body := StyleBoxFlat.new()
	body.bg_color = border_color
	body.set_corner_radius_all(10)
	lock.draw_style_box(body, Rect2(c + Vector2(-34, 4), Vector2(68, 50)))

	lock.draw_circle(c + Vector2(0, 24), 7.0, text_color)
	lock.draw_rect(Rect2(c + Vector2(-3, 26), Vector2(6, 16)), text_color)


## เท็กซ์เจอร์เส้นประสร้างจากโค้ด (ขีด 20 ช่องว่าง 12) ใช้กับ Line2D แบบ tile
func _make_dash_texture() -> ImageTexture:
	var img := Image.create(32, 8, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 1, 1, 0))
	for x in 20:
		for y in 8:
			img.set_pixel(x, y, Color.WHITE)
	return ImageTexture.create_from_image(img)


func _build_confirm_panel() -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = Color("fff6e0")
	box.set_corner_radius_all(36)
	box.set_border_width_all(7)
	box.border_color = border_color
	box.shadow_color = Color(0, 0, 0, 0.35)
	box.shadow_size = 12
	box.shadow_offset = Vector2(0, 8)
	box.set_content_margin_all(32)
	confirm_panel.add_theme_stylebox_override("panel", box)
	confirm_panel.hide()

	for label: Label in [panel_title, panel_desc]:
		if button_font:
			label.add_theme_font_override("font", button_font)
		label.add_theme_color_override("font_color", border_color)
	panel_title.add_theme_font_size_override("font_size", panel_title_font_size)
	panel_desc.add_theme_font_size_override("font_size", panel_desc_font_size)

	UIStyle.style_button(play_button, play_color, text_color, border_color, button_font, play_font_size)
	UIStyle.setup_hover(play_button, _on_hover)
	play_button.pressed.connect(_on_play_pressed)


## ลูกศรซ้าย/ขวาเลื่อนระหว่างเลเวล (วนรอบ) ลูกศรขึ้นไปปุ่ม BACK
func _set_focus_neighbors() -> void:
	var n := _buttons.size()
	for i in n:
		var b := _buttons[i]
		b.focus_neighbor_left = _buttons[(i - 1 + n) % n].get_path()
		b.focus_neighbor_right = _buttons[(i + 1) % n].get_path()
		b.focus_neighbor_top = back_button.get_path()
		b.focus_neighbor_bottom = b.get_path()
	if n > 0:
		back_button.focus_neighbor_bottom = _buttons[0].get_path()
		back_button.focus_neighbor_right = _buttons[0].get_path()
	back_button.focus_neighbor_left = back_button.get_path()
	back_button.focus_neighbor_top = back_button.get_path()
	# แผงยืนยัน: มีปุ่มเดียว ล็อกโฟกัสไว้ที่ปุ่ม PLAY
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		play_button.set_focus_neighbor(side, play_button.get_path())


## จัดเส้นทางใหม่ทุกครั้งที่ Stage เปลี่ยนขนาด (ตำแหน่งจริง = anchor x ขนาด Stage)
func _layout_stage() -> void:
	for i in _lines.size():
		var a := _slot_center(i)
		var b := _slot_center(i + 1)
		var mid := (a + b) / 2.0
		var perp := (b - a).orthogonal().normalized()
		var bend := (b - a).length() * 0.12 * (1.0 if i % 2 == 0 else -1.0)
		var ctrl := mid + perp * bend
		var points := PackedVector2Array()
		for s in 25:
			var t := float(s) / 24.0
			points.append(a.lerp(ctrl, t).lerp(ctrl.lerp(b, t), t))
		_lines[i].points = points
	if _selected >= 0 and confirm_panel.visible:
		_place_confirm_panel()


func _slot_center(index: int) -> Vector2:
	return levels[index].map_position * stage.size


# ============ เอฟเฟกต์ hover ============

func _on_hover(button: Button, hovered: bool) -> void:
	if _busy:
		return
	UIStyle.hover_tween(button, hovered)
	if hovered:
		_play_hover()


func _play_hover() -> void:
	if hover_sound.stream:
		hover_sound.play()


# ============ การทำงานของปุ่ม ============

func _on_level_pressed(index: int) -> void:
	if _busy:
		return
	if levels[index].unlocked:
		_play_click()
		_open_confirm(index)
	else:
		_play_click()
		_shake_locked(index)


func _shake_locked(index: int) -> void:
	var button := _buttons[index]
	button.pivot_offset = button.size / 2.0
	var t := button.create_tween()
	for angle in [0.12, -0.12, 0.08, -0.05, 0.0]:
		t.tween_property(button, "rotation", angle, 0.05)
	_show_coming_soon(index)


func _show_coming_soon(index: int) -> void:
	var button := _buttons[index]
	if _bubbles.has(button) and is_instance_valid(_bubbles[button]):
		_bubbles[button].queue_free()

	var bubble := Label.new()
	bubble.text = "Coming Soon!"
	bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bubble.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bubble.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if button_font:
		bubble.add_theme_font_override("font", button_font)
	bubble.add_theme_font_size_override("font_size", name_font_size)
	bubble.add_theme_color_override("font_color", border_color)
	var box := StyleBoxFlat.new()
	box.bg_color = Color("fff6e0")
	box.set_corner_radius_all(26)
	box.set_border_width_all(5)
	box.border_color = border_color
	box.shadow_color = Color(0, 0, 0, 0.3)
	box.shadow_size = 6
	box.shadow_offset = Vector2(0, 5)
	box.content_margin_left = 24
	box.content_margin_right = 24
	box.content_margin_top = 8
	box.content_margin_bottom = 8
	bubble.add_theme_stylebox_override("normal", box)
	button.add_child(bubble)
	bubble.reset_size()
	bubble.position = Vector2((circle_size - bubble.size.x) / 2.0, -bubble.size.y - 16.0)
	bubble.pivot_offset = Vector2(bubble.size.x / 2.0, bubble.size.y)
	bubble.scale = Vector2.ONE * 0.4
	bubble.modulate.a = 0.0
	_bubbles[button] = bubble

	var t := bubble.create_tween()
	t.tween_property(bubble, "scale", Vector2.ONE, 0.25) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(bubble, "modulate:a", 1.0, 0.12)
	t.tween_interval(1.0)
	t.tween_property(bubble, "modulate:a", 0.0, 0.3)
	t.tween_callback(bubble.queue_free)


func _open_confirm(index: int) -> void:
	_selected = index
	panel_title.text = levels[index].level_name
	panel_desc.text = levels[index].description
	_set_levels_focusable(false)

	confirm_panel.modulate.a = 0.0
	confirm_panel.show()
	confirm_panel.reset_size()
	await get_tree().process_frame   # รอให้ขนาดแผงคำนวณเสร็จก่อนวางตำแหน่ง
	if _selected != index:
		return
	_place_confirm_panel()
	confirm_panel.pivot_offset = Vector2(0, confirm_panel.size.y / 2.0)
	confirm_panel.scale = Vector2.ONE * 0.85
	var t := confirm_panel.create_tween().set_parallel()
	t.tween_property(confirm_panel, "modulate:a", 1.0, 0.12)
	t.tween_property(confirm_panel, "scale", Vector2.ONE, 0.2) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	play_button.grab_focus()


## วางแผงไว้ข้างปุ่มเลเวล (ขวา ถ้าไม่พอที่ค่อยไปซ้าย) และไม่ให้ล้นขอบ Stage
func _place_confirm_panel() -> void:
	var center := _slot_center(_selected)
	var gap := circle_size / 2.0 + 36.0
	var p := Vector2(center.x + gap, center.y - confirm_panel.size.y / 2.0)
	if p.x + confirm_panel.size.x > stage.size.x - 24.0:
		p.x = center.x - gap - confirm_panel.size.x
	p.x = clampf(p.x, 24.0, maxf(24.0, stage.size.x - confirm_panel.size.x - 24.0))
	p.y = clampf(p.y, 24.0, maxf(24.0, stage.size.y - confirm_panel.size.y - 24.0))
	confirm_panel.position = p


func _close_confirm() -> void:
	var index := _selected
	_selected = -1
	confirm_panel.hide()
	_set_levels_focusable(true)
	if index >= 0:
		_buttons[index].grab_focus()


func _set_levels_focusable(enabled: bool) -> void:
	var mode := Control.FOCUS_ALL if enabled else Control.FOCUS_NONE
	for b in _buttons:
		b.focus_mode = mode
	back_button.focus_mode = mode


func _on_play_pressed() -> void:
	if _busy:
		return
	_play_click()
	_leave(_start_game)


func _start_game() -> void:
	var gm := get_node_or_null("/root/GameManager")
	if gm and gm.has_method("start_new_game"):
		gm.start_new_game()
	else:
		push_error("ไม่พบ GameManager.start_new_game()")
		_busy = false
		create_tween().tween_property(fade_rect, "modulate:a", 0.0, fade_time)


func _on_back_pressed() -> void:
	if _busy:
		return
	_play_click()
	_leave(func() -> void: get_tree().change_scene_to_file(MAIN_MENU_SCENE))


func _unhandled_input(event: InputEvent) -> void:
	if _busy:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if confirm_panel.visible:
			_play_click()
			_close_confirm()
		else:
			_on_back_pressed()
	elif confirm_panel.visible and event is InputEventMouseButton and event.pressed:
		# คลิกนอกแผง = ปิดแผง
		if not confirm_panel.get_global_rect().has_point(event.position):
			_play_click()
			_close_confirm()


# ============ ตัวช่วย ============

func _play_click() -> void:
	# กำลังเปลี่ยนหน้าอยู่ ไม่ต้องเล่นเสียงซ้ำ
	if _busy:
		return
	if click_sound.stream:
		click_sound.play()


func _leave(action: Callable) -> void:
	# กันกดซ้ำ แล้วเฟดดำก่อนทำ action
	if _busy:
		return
	_busy = true
	var t := create_tween()
	t.tween_property(fade_rect, "modulate:a", 1.0, fade_time)
	await t.finished
	action.call()
