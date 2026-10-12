extends Control
## แผง Settings ที่ใช้ซ้ำได้ (main_menu และ pause_menu)
## open() เปิด, close() ปิด  signal opened / closed / button_hovered ให้ฝั่งที่เรียกใช้เล่นเสียงหรือล็อกโฟกัส
## ทำงานได้ตอนเกม pause (process_mode = Always ตั้งใน .tscn)

const UIStyle := preload("res://ui/ui_style.gd")
const ToggleSwitch := preload("res://ui/toggle_switch.gd")
const GS := preload("res://ui/game_settings.gd")

signal opened
signal closed
signal button_hovered

@export var button_font: Font
@export var font_size: int = 48
@export var close_color := Color("a8e6cf")   # เขียวมินต์
@export var reset_color := Color("f7a39a")   # ส้มอมชมพู
@export var text_color := Color("fff6e0")    # ครีม
@export var border_color := Color("7a4a22")  # น้ำตาลไม้

@onready var panel: PanelContainer = %Panel
@onready var master_slider: HSlider = %MasterSlider
@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SfxSlider
@onready var master_percent: Label = %MasterPercent
@onready var music_percent: Label = %MusicPercent
@onready var sfx_percent: Label = %SfxPercent
@onready var fullscreen_switch: ToggleSwitch = %FullscreenSwitch
@onready var fps_switch: ToggleSwitch = %FpsSwitch
@onready var reset_button: Button = %ResetButton
@onready var close_button: Button = %CloseButton

var _sliders: Array[HSlider] = []
var _buses: Array[String] = [GS.MASTER, GS.MUSIC, GS.SFX]


func _ready() -> void:
	GS.ensure_setup()
	_sliders = [master_slider, music_slider, sfx_slider]
	_style_panel()
	for s in _sliders:
		_style_slider(s)
		s.min_value = 0.0
		s.max_value = 1.0
		s.step = 0.05
		s.value_changed.connect(_on_volume_changed.bind(s))
	UIStyle.style_button(close_button, close_color, text_color, border_color, button_font, font_size)
	UIStyle.style_button(reset_button, reset_color, text_color, border_color, button_font, font_size)
	UIStyle.setup_hover(close_button, _on_hover)
	UIStyle.setup_hover(reset_button, _on_hover)

	close_button.pressed.connect(close)
	reset_button.pressed.connect(_on_reset_pressed)
	fullscreen_switch.toggled.connect(_on_fullscreen_toggled)
	fps_switch.toggled.connect(_on_fps_toggled)
	for sw: ToggleSwitch in [fullscreen_switch, fps_switch]:
		sw.mouse_entered.connect(button_hovered.emit)
		sw.focus_entered.connect(button_hovered.emit)

	_sync_all()
	_setup_focus()
	hide()


## ขังโฟกัสไว้ในแผง: ขึ้น/ลง/Tab วนตามลำดับแถว  ซ้าย/ขวาบน slider ปรับค่า
func _setup_focus() -> void:
	var order: Array[Control] = [master_slider, music_slider, sfx_slider,
		fullscreen_switch, fps_switch, reset_button, close_button]
	for i in order.size():
		var c := order[i]
		var up := order[(i - 1 + order.size()) % order.size()]
		var down := order[(i + 1) % order.size()]
		c.focus_neighbor_top = up.get_path()
		c.focus_neighbor_bottom = down.get_path()
		c.focus_previous = up.get_path()
		c.focus_next = down.get_path()
		c.focus_neighbor_left = c.get_path()
		c.focus_neighbor_right = c.get_path()
	# แถวปุ่มล่าง: ซ้าย/ขวาสลับ RESET <-> CLOSE, ขึ้นจากทั้งสองไปที่สวิตช์ FPS
	reset_button.focus_neighbor_right = close_button.get_path()
	close_button.focus_neighbor_left = reset_button.get_path()
	reset_button.focus_neighbor_bottom = master_slider.get_path()
	close_button.focus_neighbor_top = fps_switch.get_path()
	close_button.focus_previous = reset_button.get_path()
	reset_button.focus_next = close_button.get_path()
	close_button.focus_next = master_slider.get_path()


func is_open() -> bool:
	return visible


func open() -> void:
	if visible:
		return
	_sync_all()
	# ฉากมืด (Dim, mouse filter Stop) กันคลิกโดนปุ่มข้างหลัง
	show()
	panel.pivot_offset = panel.size / 2.0
	panel.scale = Vector2(0.8, 0.8)
	panel.modulate.a = 0.0
	var t := create_tween().set_parallel()
	t.tween_property(panel, "scale", Vector2.ONE, 0.2) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(panel, "modulate:a", 1.0, 0.15)
	master_slider.grab_focus()
	opened.emit()


func close() -> void:
	if not visible:
		return
	hide()
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	# กด Esc เพื่อปิดแผง
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()


func _sync_all() -> void:
	# แสดงค่าจริงตอนนี้ (ไม่ยิง signal จะได้ไม่ปัดค่าเสียงเอง)
	for i in _sliders.size():
		var v := GS.get_volume(_buses[i])
		_sliders[i].set_value_no_signal(v)
		_update_percent(i)
	fullscreen_switch.set_on(GS.is_fullscreen())
	fps_switch.set_on(GS.is_fps_shown())


func _update_percent(i: int) -> void:
	var labels: Array[Label] = [master_percent, music_percent, sfx_percent]
	labels[i].text = "%d%%" % roundi(_sliders[i].value * 100.0)


func _on_volume_changed(value: float, slider: HSlider) -> void:
	var i := _sliders.find(slider)
	GS.set_volume(_buses[i], value)
	_update_percent(i)


func _on_fullscreen_toggled(on: bool) -> void:
	GS.set_fullscreen(on)


func _on_fps_toggled(on: bool) -> void:
	GS.set_fps_shown(on)


func _on_reset_pressed() -> void:
	GS.reset_all()
	_sync_all()


func _on_hover(button: Button, hovered: bool) -> void:
	UIStyle.hover_tween(button, hovered)
	if hovered:
		button_hovered.emit()


func _style_panel() -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = Color("fff6e0")
	box.set_corner_radius_all(42)
	box.set_border_width_all(9)
	box.border_color = border_color
	box.shadow_color = Color(0, 0, 0, 0.35)
	box.shadow_size = 18
	box.set_content_margin_all(52)
	panel.add_theme_stylebox_override("panel", box)


## slider หนาและมีหัวจับวงกลม (ค่าเริ่มต้นของ Godot บางและเล็กเกินไปที่จอ 1920x1080)
func _style_slider(slider: HSlider) -> void:
	var track := StyleBoxFlat.new()
	track.bg_color = Color(border_color, 0.25)
	track.set_corner_radius_all(14)
	track.content_margin_top = 14
	track.content_margin_bottom = 14
	var filled := StyleBoxFlat.new()
	filled.bg_color = close_color
	filled.set_corner_radius_all(14)
	filled.set_border_width_all(3)
	filled.border_color = border_color
	filled.content_margin_top = 14
	filled.content_margin_bottom = 14
	slider.add_theme_stylebox_override("slider", track)
	slider.add_theme_stylebox_override("grabber_area", filled)
	slider.add_theme_stylebox_override("grabber_area_highlight", filled)
	var knob := _make_knob(52)
	slider.add_theme_icon_override("grabber", knob)
	slider.add_theme_icon_override("grabber_highlight", knob)
	slider.add_theme_icon_override("grabber_disabled", knob)


func _make_knob(diameter: int) -> GradientTexture2D:
	var gradient := Gradient.new()
	var clear := Color(border_color, 0.0)
	gradient.offsets = PackedFloat32Array([0.0, 0.6, 0.64, 0.9, 0.94])
	gradient.colors = PackedColorArray([Color("fff6e0"), Color("fff6e0"), border_color, border_color, clear])
	var tex := GradientTexture2D.new()
	tex.gradient = gradient
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = diameter
	tex.height = diameter
	return tex
