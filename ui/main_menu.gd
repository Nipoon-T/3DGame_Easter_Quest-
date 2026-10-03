extends Control
## เมนูหลัก Easter Quest
## ปุ่ม START / SETTINGS / QUIT วางทับป้ายไม้ในภาพพื้นหลัง

const SettingsPanelScript := preload("res://ui/settings_panel.gd")

# ---------- ปลายทาง ----------
## หน้าเลือกตัวละคร ถ้ายังไม่มีไฟล์นี้ ปุ่ม START จะเรียก GameManager.start_new_game() แทน
@export_file("*.tscn") var character_select_scene: String = "res://ui/character_select.tscn"

# ---------- หน้าตาปุ่ม ----------
@export var button_font: Font
@export var font_size: int = 44
@export var start_color := Color("f2b8dc")     # ชมพู
@export var settings_color := Color("a8d8f0")  # ฟ้า
@export var quit_color := Color("f7a39a")      # ส้มอมชมพู
@export var text_color := Color("fff6e0")      # ครีม
@export var border_color := Color("7a4a22")    # น้ำตาลไม้

@export var fade_time: float = 0.5

@onready var start_button: Button = %StartButton
@onready var settings_button: Button = %SettingsButton
@onready var quit_button: Button = %QuitButton
@onready var settings_panel: SettingsPanelScript = %SettingsPanel
@onready var fade_rect: ColorRect = %FadeRect
@onready var hover_sound: AudioStreamPlayer = %HoverSound
@onready var click_sound: AudioStreamPlayer = %ClickSound

var _busy := false


func _ready() -> void:
	# ---- หน้าตาปุ่ม ----
	_style_button(start_button, start_color)
	_style_button(settings_button, settings_color)
	_style_button(quit_button, quit_color)

	for b in [start_button, settings_button, quit_button]:
		_setup_hover(b)

	# ---- เชื่อมปุ่ม ----
	start_button.pressed.connect(_on_start_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	settings_panel.opened.connect(_set_menu_focusable.bind(false))
	settings_panel.closed.connect(_on_settings_closed)
	settings_panel.button_hovered.connect(_play_hover)

	# เกมบนเว็บปิดตัวเองไม่ได้ ซ่อนปุ่ม QUIT ไปเลย
	if OS.has_feature("web"):
		quit_button.hide()

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
	button.add_theme_constant_override("outline_size", 10)

	if button_font:
		button.add_theme_font_override("font", button_font)
	button.add_theme_font_size_override("font_size", font_size)


func _make_box(color: Color, pressed: bool) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(24)
	box.set_border_width_all(4)
	box.border_color = border_color
	box.shadow_color = Color(0, 0, 0, 0.3)
	box.shadow_size = 2 if pressed else 6
	box.shadow_offset = Vector2(0, 2 if pressed else 6)
	box.content_margin_left = 24
	box.content_margin_right = 24
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
	if ResourceLoader.exists(character_select_scene):
		_leave(func(): get_tree().change_scene_to_file(character_select_scene))
	else:
		_leave(_start_game_directly)


func _start_game_directly() -> void:
	var gm := get_node_or_null("/root/GameManager")
	if gm and gm.has_method("start_new_game"):
		gm.start_new_game()
	else:
		push_error("ไม่พบ GameManager.start_new_game() และยังไม่มีหน้าเลือกตัวละคร")
		_busy = false
		create_tween().tween_property(fade_rect, "modulate:a", 0.0, fade_time)


func _on_settings_pressed() -> void:
	if _busy:
		return
	_play_click()
	# ขังโฟกัสไว้ในแผง คีย์บอร์ด/จอยจะเลื่อนไปปุ่มเมนูข้างหลังไม่ได้ (ทำใน signal opened)
	settings_panel.open()


func _on_settings_closed() -> void:
	_play_click()
	_set_menu_focusable(true)
	settings_button.grab_focus()


func _set_menu_focusable(enabled: bool) -> void:
	var mode := Control.FOCUS_ALL if enabled else Control.FOCUS_NONE
	for b: Button in [start_button, settings_button, quit_button]:
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
