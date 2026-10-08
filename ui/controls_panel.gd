extends Control
## แผง "How to Play" ที่ใช้ซ้ำได้ (main_menu, pause_menu)
## open() เปิด, close() ปิด  signal opened / closed / button_hovered
## ทำงานได้ตอนเกม pause (process_mode = Always ตั้งใน .tscn)
## ชื่อปุ่มอ่านจาก InputMap ตอน open() ทุกครั้ง (ดู controls_guide.gd)

const UIStyle := preload("res://ui/ui_style.gd")
const Guide := preload("res://ui/controls_guide.gd")

signal opened
signal closed
signal button_hovered

@export var button_font: Font
@export var font_size: int = 48
@export var key_size: int = 76
@export var row_font_size: int = 42
@export var close_color := Color("a8e6cf")   # เขียวมินต์
@export var text_color := Color("fff6e0")    # ครีม
@export var border_color := Color("7a4a22")  # น้ำตาลไม้

@onready var panel: PanelContainer = %Panel
@onready var rows: GridContainer = %Rows
@onready var close_button: Button = %CloseButton


func _ready() -> void:
	_style_panel()
	UIStyle.style_button(close_button, close_color, text_color, border_color, button_font, font_size)
	UIStyle.setup_hover(close_button, _on_hover)
	close_button.pressed.connect(close)

	# ขังโฟกัสไว้ในแผง: มีปุ่มเดียวคือ CLOSE
	var close_path := close_button.get_path()
	close_button.focus_neighbor_top = close_path
	close_button.focus_neighbor_bottom = close_path
	close_button.focus_neighbor_left = close_path
	close_button.focus_neighbor_right = close_path
	close_button.focus_next = close_path
	close_button.focus_previous = close_path

	hide()


func is_open() -> bool:
	return visible


func open() -> void:
	if visible:
		return
	_build_rows()
	# ฉากมืด (Dim, mouse filter Stop) กันคลิกโดนปุ่มข้างหลัง
	show()
	panel.reset_size()
	panel.pivot_offset = panel.size / 2.0
	panel.scale = Vector2(0.8, 0.8)
	panel.modulate.a = 0.0
	var t := create_tween().set_parallel()
	t.tween_property(panel, "scale", Vector2.ONE, 0.2) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(panel, "modulate:a", 1.0, 0.15)
	close_button.grab_focus()
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


func _build_rows() -> void:
	for c in rows.get_children():
		rows.remove_child(c)
		c.queue_free()
	for entry in Guide.ENTRIES:
		rows.add_child(Guide.build_row(entry, button_font, key_size, row_font_size, 280.0, border_color))


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
