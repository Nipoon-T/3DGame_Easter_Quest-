extends CanvasLayer
## เมนู Pause: แผงไข่ + ปุ่ม RESUME / SETTINGS / CONTROLS / MAIN MENU
## ตามสถานะของ GameManager เท่านั้น (signal paused_changed) ไม่รับปุ่ม P เอง
## GameManager รับ P / action "pause" และเป็นคนสั่ง get_tree().paused + mouse mode
## ปุ่มในเมนูแค่เรียก GameManager.set_paused(false)

const UIStyle := preload("res://ui/ui_style.gd")
const SettingsPanelScript := preload("res://ui/settings_panel.gd")
const ControlsPanelScript := preload("res://ui/controls_panel.gd")

# ---------- ขนาด ----------
## ความสูงแผงไข่เทียบกับความสูงจอ
@export_range(0.3, 1.0) var panel_height_ratio: float = 0.85
## ความสูงแผงที่ font_size ด้านล่างถูกออกแบบไว้ (จอ 648 สูง x 0.85) ถ้าแผงสูงขึ้นฟอนต์จะขยายตาม
@export var reference_panel_height: float = 550.0
@export var title_font_size: int = 56
@export var button_font_size: int = 28
@export var button_font: Font

# ---------- สี ----------
@export var resume_color := Color("a8e6cf")     # เขียวมินต์
@export var settings_color := Color("f7e08a")   # เหลือง
@export var controls_color := Color("a8d8f0")   # ฟ้า
@export var menu_color := Color("f2b8dc")       # ชมพู
@export var text_color := Color("fff6e0")       # ครีม
@export var border_color := Color("7a4a22")     # น้ำตาลไม้

@export var fade_time: float = 0.5   # เฟดดำตอนกลับเมนูหลัก
@export var open_time: float = 0.2
@export var close_time: float = 0.15

@onready var root: Control = %Root
@onready var egg: TextureRect = %Egg
@onready var title_label: Label = %TitleLabel
@onready var resume_button: Button = %ResumeButton
@onready var settings_button: Button = %SettingsButton
@onready var controls_button: Button = %ControlsButton
@onready var menu_button: Button = %MenuButton
@onready var settings_panel: SettingsPanelScript = %SettingsPanel
@onready var controls_panel: ControlsPanelScript = %ControlsPanel
@onready var fade_rect: ColorRect = %FadeRect
@onready var hover_sound: AudioStreamPlayer = %HoverSound
@onready var click_sound: AudioStreamPlayer = %ClickSound

var _tween: Tween
var _closing := false   # กำลังเฟดปิดเมนู
var _leaving := false   # กำลังกลับเมนูหลัก (กันกดซ้ำ)


func _ready() -> void:
	layer = 20   # สูงกว่า HUD (10)
	process_mode = Node.PROCESS_MODE_ALWAYS

	UIStyle.setup_hover(resume_button, _on_hover)
	UIStyle.setup_hover(settings_button, _on_hover)
	UIStyle.setup_hover(controls_button, _on_hover)
	UIStyle.setup_hover(menu_button, _on_hover)

	resume_button.pressed.connect(_on_resume_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	controls_button.pressed.connect(_on_controls_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	settings_panel.opened.connect(_set_menu_focusable.bind(false))
	settings_panel.closed.connect(_on_settings_closed)
	settings_panel.button_hovered.connect(_play_hover)
	controls_panel.opened.connect(_set_menu_focusable.bind(false))
	controls_panel.closed.connect(_on_controls_closed)
	controls_panel.button_hovered.connect(_play_hover)

	root.hide()
	fade_rect.hide()

	get_viewport().size_changed.connect(_layout)
	_layout()

	GameManager.paused_changed.connect(_on_paused_changed)
	# โหลดมาตอนเกม pause อยู่แล้ว (เช่น เปลี่ยนฉากกลางคัน)
	if get_tree().paused:
		_show_menu()


# ============ เลย์เอาต์ ============

func _layout() -> void:
	# แผงไข่: คงสัดส่วนภาพ สูง panel_height_ratio ของจอ วางกลางจอ
	var screen := get_viewport().get_visible_rect().size
	var tex := egg.texture
	if tex == null:
		return
	var h := screen.y * panel_height_ratio
	var w := h * float(tex.get_width()) / float(tex.get_height())
	egg.offset_left = -w / 2.0
	egg.offset_right = w / 2.0
	egg.offset_top = -h / 2.0
	egg.offset_bottom = h / 2.0
	egg.pivot_offset = Vector2(w, h) / 2.0

	# ฟอนต์/ปุ่มขยายตามขนาดแผง
	var k := h / reference_panel_height
	if button_font:
		title_label.add_theme_font_override("font", button_font)
	title_label.add_theme_font_size_override("font_size", roundi(title_font_size * k))
	title_label.add_theme_color_override("font_color", text_color)
	title_label.add_theme_color_override("font_outline_color", border_color)
	title_label.add_theme_constant_override("outline_size", roundi(14 * k))
	var fs := roundi(button_font_size * k)
	UIStyle.style_button(resume_button, resume_color, text_color, border_color, button_font, fs, k)
	UIStyle.style_button(settings_button, settings_color, text_color, border_color, button_font, fs, k)
	UIStyle.style_button(controls_button, controls_color, text_color, border_color, button_font, fs, k)
	UIStyle.style_button(menu_button, menu_color, text_color, border_color, button_font, fs, k)


# ============ เปิด / ปิด ตามสถานะ GameManager ============

func _on_paused_changed(is_paused: bool) -> void:
	if is_paused:
		_show_menu()
	elif not _leaving:
		_hide_menu()


func _show_menu() -> void:
	if _tween:
		_tween.kill()
	_closing = false
	_set_menu_focusable(true)
	# GameManager ปล่อยเมาส์ให้แล้ว ย้ำอีกครั้งกันพลาด
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	root.show()
	root.modulate.a = 0.0
	egg.scale = Vector2(0.85, 0.85)
	_tween = create_tween().set_parallel()
	_tween.tween_property(root, "modulate:a", 1.0, open_time)
	_tween.tween_property(egg, "scale", Vector2.ONE, open_time + 0.05) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	resume_button.grab_focus.call_deferred()


func _hide_menu() -> void:
	if not root.visible or _closing:
		return
	_closing = true
	# เกมกลับมาเล่นแล้ว (GameManager คืนเมาส์/สถานะให้) แผง Settings ที่เปิดค้างต้องปิดด้วย
	settings_panel.close()
	controls_panel.close()
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(root, "modulate:a", 0.0, close_time)
	await _tween.finished
	root.hide()
	root.modulate.a = 1.0
	_closing = false


# ============ ปุ่ม ============

func _on_resume_pressed() -> void:
	if _closing or _leaving:
		return
	_play_click()
	GameManager.set_paused(false)   # สัญญาณ paused_changed จะพาไป _hide_menu() เอง


func _on_settings_pressed() -> void:
	if _closing or _leaving:
		return
	_play_click()
	settings_panel.open()


func _on_settings_closed() -> void:
	_play_click()
	_set_menu_focusable(true)
	settings_button.grab_focus()


func _on_controls_pressed() -> void:
	if _closing or _leaving:
		return
	_play_click()
	controls_panel.open()


func _on_controls_closed() -> void:
	_play_click()
	_set_menu_focusable(true)
	controls_button.grab_focus()


func _on_menu_pressed() -> void:
	if _closing or _leaving:
		return
	_leaving = true
	_play_click()
	fade_rect.show()
	fade_rect.modulate.a = 0.0
	var t := create_tween()
	t.tween_property(fade_rect, "modulate:a", 1.0, fade_time)
	await t.finished

	# quit_to_menu() หยุดนาฬิกา ยกเลิก pause คืนเมาส์ และเปลี่ยนไปเมนูหลักให้เอง
	GameManager.quit_to_menu()


func _unhandled_input(event: InputEvent) -> void:
	# Esc: แผง Settings ที่เปิดอยู่จัดการเอง (ปิดแผง) ไม่อย่างนั้น = Resume
	# ปุ่ม P / action "pause" ปล่อยให้ GameManager จัดการ เมนูตามสัญญาณ
	if not root.visible or _closing or _leaving or settings_panel.is_open() or controls_panel.is_open():
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_resume_pressed()


# ============ ตัวช่วย ============

func _set_menu_focusable(enabled: bool) -> void:
	var mode := Control.FOCUS_ALL if enabled else Control.FOCUS_NONE
	for b: Button in [resume_button, settings_button, controls_button, menu_button]:
		b.focus_mode = mode


func _on_hover(button: Button, hovered: bool) -> void:
	if _leaving:
		return
	UIStyle.hover_tween(button, hovered)
	if hovered:
		_play_hover()


func _play_hover() -> void:
	if hover_sound.stream:
		hover_sound.play()


func _play_click() -> void:
	if click_sound.stream:
		click_sound.play()
