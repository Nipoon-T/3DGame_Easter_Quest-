extends Control
## เมนูหลัก Easter Quest
## ปุ่ม START / SETTINGS / LEVELS วางทับป้ายไม้ในภาพพื้นหลัง  ปุ่มกลม ? และ QUIT อยู่มุมขวาบน

const SettingsPanelScript := preload("res://ui/settings_panel.gd")
const ControlsPanelScript := preload("res://ui/controls_panel.gd")

# ---------- ปลายทาง ----------
const LEVEL_MAP_SCENE := "res://ui/level_map.tscn"

# ---------- หน้าตาปุ่ม ----------
@export var button_font: Font
@export var font_size: int = 44
@export var start_color := Color("f2b8dc")     # ชมพู
@export var settings_color := Color("a8d8f0")  # ฟ้า
@export var levels_color := Color("f7a39a")    # ส้มอมชมพู (แผ่นที่ 3 LEVELS)
@export var quit_color := Color("f7a39a")      # ส้มอมชมพู (ปุ่มกลม QUIT มุมขวาบน)
@export var help_color := Color("f7e08a")      # เหลือง (ปุ่ม ? How to Play)
@export var text_color := Color("fff6e0")      # ครีม
@export var border_color := Color("7a4a22")    # น้ำตาลไม้

@export var fade_time: float = 0.5

@onready var start_button: Button = %StartButton
@onready var settings_button: Button = %SettingsButton
@onready var levels_button: Button = %LevelsButton
@onready var quit_button: Button = %QuitButton
@onready var help_button: Button = %HelpButton
@onready var settings_panel: SettingsPanelScript = %SettingsPanel
@onready var controls_panel: ControlsPanelScript = %ControlsPanel
@onready var fade_rect: ColorRect = %FadeRect
@onready var hover_sound: AudioStreamPlayer = %HoverSound
@onready var click_sound: AudioStreamPlayer = %ClickSound

var _busy := false


func _ready() -> void:
	# ---- หน้าตาปุ่ม ----
	_style_button(start_button, start_color)
	_style_button(settings_button, settings_color)
	_style_button(levels_button, levels_color)

	_style_round_button(help_button, help_color, 64)
	_style_round_button(quit_button, quit_color, 64)
	quit_button.get_node("Icon").draw.connect(_draw_power_icon.bind(quit_button.get_node("Icon")))

	for b in [start_button, settings_button, levels_button, quit_button, help_button]:
		_setup_hover(b)

	# ---- เชื่อมปุ่ม ----
	start_button.pressed.connect(_on_start_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	levels_button.pressed.connect(_on_levels_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	settings_panel.opened.connect(_set_menu_focusable.bind(false))
	settings_panel.closed.connect(_on_settings_closed)
	settings_panel.button_hovered.connect(_play_hover)
	help_button.pressed.connect(_on_help_pressed)
	controls_panel.opened.connect(_set_menu_focusable.bind(false))
	controls_panel.closed.connect(_on_controls_closed)
	controls_panel.button_hovered.connect(_play_hover)

	# เกมบนเว็บปิดตัวเองไม่ได้ ซ่อนปุ่ม QUIT ไปเลย (ปุ่ม ? อยู่ใน HBoxContainer จึงขยับชิดมุมเอง)
	if OS.has_feature("web"):
		quit_button.hide()

	_set_focus_neighbors()

	# ---- เฟดเข้า ----
	fade_rect.show()
	fade_rect.modulate.a = 1.0
	create_tween().tween_property(fade_rect, "modulate:a", 0.0, fade_time)

	# ให้เล่นด้วยคีย์บอร์ด/จอยได้ทันที
	start_button.grab_focus.call_deferred()


# ============ สไตล์ปุ่ม ============

func _style_button(button: Button, base: Color) -> void:
	button.add_theme_stylebox_override("normal", _make_box(base, false))
	button.add_theme_stylebox_override("hover", _make_box(base.lightened(0.15), false))
	button.add_theme_stylebox_override("pressed", _make_box(base.darkened(0.12), true))
	button.add_theme_stylebox_override("focus", _make_focus_box())

	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, text_color)
	button.add_theme_color_override("font_outline_color", border_color)
	button.add_theme_constant_override("outline_size", 14)

	if button_font:
		button.add_theme_font_override("font", button_font)
	button.add_theme_font_size_override("font_size", font_size)


func _make_box(color: Color, pressed: bool) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(32)
	box.set_border_width_all(6)
	box.border_color = border_color
	box.shadow_color = Color(0, 0, 0, 0.3)
	box.shadow_size = 3 if pressed else 9
	box.shadow_offset = Vector2(0, 3 if pressed else 9)
	box.content_margin_left = 32
	box.content_margin_right = 32
	return box


func _make_focus_box() -> StyleBoxFlat:
	# กรอบขาวรอบปุ่มเวลาเลือกด้วยคีย์บอร์ด/จอย
	var box := StyleBoxFlat.new()
	box.draw_center = false
	box.set_corner_radius_all(28)
	box.set_border_width_all(4)
	box.border_color = Color.WHITE
	box.set_expand_margin_all(6)
	return box


## ปุ่มกลมเล็กมุมขวาบน (? How to Play / QUIT) ป้ายไม้มีแค่ 3 แผ่น จึงไม่เพิ่มปุ่มบนป้าย
func _style_round_button(button: Button, base: Color, size_px: int) -> void:
	for state in ["normal", "hover", "pressed"]:
		var color := base
		if state == "hover":
			color = base.lightened(0.15)
		elif state == "pressed":
			color = base.darkened(0.12)
		var box := _make_box(color, state == "pressed")
		box.set_corner_radius_all(999)
		box.set_content_margin_all(0)
		button.add_theme_stylebox_override(state, box)
	button.add_theme_stylebox_override("focus", _make_focus_box())
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, border_color)
	if button_font:
		button.add_theme_font_override("font", button_font)
	button.add_theme_font_size_override("font_size", size_px)


## ไอคอน power วาดด้วยโค้ด (วงแหวนเปิดด้านบน + ขีดตรงกลาง) สีน้ำตาลไม้
func _draw_power_icon(icon: Control) -> void:
	var c := icon.size / 2.0 + Vector2(0, 3)
	var r := 22.0
	icon.draw_arc(c, r, deg_to_rad(-60.0), deg_to_rad(240.0), 32, border_color, 8.0, true)
	icon.draw_line(c + Vector2(0, -r - 6), c + Vector2(0, -2), border_color, 8.0, true)
	icon.draw_circle(c + Vector2(0, -r - 6), 4.0, border_color)
	icon.draw_circle(c + Vector2(0, -2), 4.0, border_color)
	var a := deg_to_rad(-60.0)
	icon.draw_circle(c + Vector2(cos(a), sin(a)) * r, 4.0, border_color)
	a = deg_to_rad(240.0)
	icon.draw_circle(c + Vector2(cos(a), sin(a)) * r, 4.0, border_color)


## ลูกศรขึ้น/ลงวน START -> SETTINGS -> LEVELS ลูกศรขวาไปปุ่มมุมขวาบน ลูกศรซ้ายกลับมาแผ่นไม้
func _set_focus_neighbors() -> void:
	var planks: Array[Button] = [start_button, settings_button, levels_button]
	for i in planks.size():
		var b := planks[i]
		b.focus_neighbor_top = planks[(i - 1 + planks.size()) % planks.size()].get_path()
		b.focus_neighbor_bottom = planks[(i + 1) % planks.size()].get_path()
		b.focus_neighbor_left = b.get_path()
		b.focus_neighbor_right = help_button.get_path()

	var corner: Array[Button] = [help_button]
	if quit_button.visible:
		corner.append(quit_button)
	for i in corner.size():
		var b := corner[i]
		b.focus_neighbor_left = (corner[i - 1] if i > 0 else start_button).get_path()
		b.focus_neighbor_right = (corner[i + 1] if i < corner.size() - 1 else b).get_path()
		b.focus_neighbor_top = b.get_path()
		b.focus_neighbor_bottom = start_button.get_path()


# ============ เอฟเฟกต์ hover ============

func _setup_hover(button: Button) -> void:
	# ให้ปุ่มขยายจากตรงกลาง
	button.resized.connect(func(): button.pivot_offset = button.size / 2.0)
	button.pivot_offset = button.size / 2.0

	button.mouse_entered.connect(_on_hover.bind(button, true))
	button.mouse_exited.connect(_on_hover.bind(button, false))
	button.focus_entered.connect(_on_hover.bind(button, true))
	button.focus_exited.connect(_on_hover.bind(button, false))


func _on_hover(button: Button, hovered: bool) -> void:
	if _busy:
		return
	var target := Vector2.ONE * (1.06 if hovered else 1.0)
	create_tween().tween_property(button, "scale", target, 0.12) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if hovered:
		_play_hover()


func _play_hover() -> void:
	if hover_sound.stream:
		hover_sound.play()


# ============ การทำงานของปุ่ม ============

func _on_start_pressed() -> void:
	_play_click()
	_leave(_start_game_directly)


func _start_game_directly() -> void:
	var gm := get_node_or_null("/root/GameManager")
	if gm and gm.has_method("start_new_game"):
		gm.start_new_game()
	else:
		push_error("ไม่พบ GameManager.start_new_game()")
		_busy = false
		create_tween().tween_property(fade_rect, "modulate:a", 0.0, fade_time)


func _on_settings_pressed() -> void:
	if _busy:
		return
	_play_click()
	# ขังโฟกัสไว้ในแผง คีย์บอร์ด/จอยจะเลื่อนไปปุ่มเมนูข้างหลังไม่ได้ (ทำใน signal opened)
	settings_panel.open()


func _on_levels_pressed() -> void:
	_play_click()
	_leave(func(): get_tree().change_scene_to_file(LEVEL_MAP_SCENE))


func _on_settings_closed() -> void:
	_play_click()
	_set_menu_focusable(true)
	settings_button.grab_focus()


func _on_help_pressed() -> void:
	if _busy:
		return
	_play_click()
	controls_panel.open()


func _on_controls_closed() -> void:
	_play_click()
	_set_menu_focusable(true)
	help_button.grab_focus()


func _set_menu_focusable(enabled: bool) -> void:
	var mode := Control.FOCUS_ALL if enabled else Control.FOCUS_NONE
	for b: Button in [start_button, settings_button, levels_button, quit_button, help_button]:
		b.focus_mode = mode


func _on_quit_pressed() -> void:
	_play_click()
	_leave(func(): get_tree().quit())


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
