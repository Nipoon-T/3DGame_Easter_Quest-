extends Control
## แผง Settings ที่ใช้ซ้ำได้ (main_menu และ pause_menu)
## open() เปิด, close() ปิด  signal opened / closed / button_hovered ให้ฝั่งที่เรียกใช้เล่นเสียงหรือล็อกโฟกัส
## ทำงานได้ตอนเกม pause (process_mode = Always ตั้งใน .tscn)

const UIStyle := preload("res://ui/ui_style.gd")

signal opened
signal closed
signal button_hovered

@export var button_font: Font
@export var font_size: int = 48
@export var close_color := Color("a8e6cf")   # เขียวมินต์
@export var text_color := Color("fff6e0")    # ครีม
@export var border_color := Color("7a4a22")  # น้ำตาลไม้

@onready var panel: PanelContainer = %Panel
@onready var volume_slider: HSlider = %VolumeSlider
@onready var close_button: Button = %CloseButton


func _ready() -> void:
	_style_panel()
	_style_slider()
	UIStyle.style_button(close_button, close_color, text_color, border_color, button_font, font_size)
	UIStyle.setup_hover(close_button, _on_hover)

	close_button.pressed.connect(close)
	volume_slider.value_changed.connect(_on_volume_changed)

	volume_slider.min_value = 0.0
	volume_slider.max_value = 1.0
	volume_slider.step = 0.05
	_sync_volume()

	# ขังโฟกัสไว้ในแผง: เลื่อนขึ้น/ลง/Tab วนระหว่าง slider กับปุ่ม CLOSE
	var slider_path := volume_slider.get_path()
	var close_path := close_button.get_path()
	volume_slider.focus_neighbor_top = close_path
	volume_slider.focus_neighbor_bottom = close_path
	volume_slider.focus_next = close_path
	volume_slider.focus_previous = close_path
	close_button.focus_neighbor_top = slider_path
	close_button.focus_neighbor_bottom = slider_path
	close_button.focus_neighbor_left = close_path
	close_button.focus_neighbor_right = close_path
	close_button.focus_next = slider_path
	close_button.focus_previous = slider_path

	hide()


func is_open() -> bool:
	return visible


func open() -> void:
	if visible:
		return
	_sync_volume()
	# ฉากมืด (Dim, mouse filter Stop) กันคลิกโดนปุ่มข้างหลัง
	show()
	panel.pivot_offset = panel.size / 2.0
	panel.scale = Vector2(0.8, 0.8)
	panel.modulate.a = 0.0
	var t := create_tween().set_parallel()
	t.tween_property(panel, "scale", Vector2.ONE, 0.2) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(panel, "modulate:a", 1.0, 0.15)
	volume_slider.grab_focus()
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


func _sync_volume() -> void:
	# ค่า slider = ระดับเสียงปัจจุบันของบัส Master (ไม่ยิง signal จะได้ไม่ปัดค่าเสียงเอง)
	volume_slider.set_value_no_signal(db_to_linear(AudioServer.get_bus_volume_db(0)))


func _on_volume_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(value))
	AudioServer.set_bus_mute(0, value <= 0.0)


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
func _style_slider() -> void:
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
	volume_slider.add_theme_stylebox_override("slider", track)
	volume_slider.add_theme_stylebox_override("grabber_area", filled)
	volume_slider.add_theme_stylebox_override("grabber_area_highlight", filled)
	var knob := _make_knob(52)
	volume_slider.add_theme_icon_override("grabber", knob)
	volume_slider.add_theme_icon_override("grabber_highlight", knob)
	volume_slider.add_theme_icon_override("grabber_disabled", knob)


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
