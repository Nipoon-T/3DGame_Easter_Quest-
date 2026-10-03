extends Control
## ฐานของหน้าแพ้/ชนะ (lose_screen.gd, win_screen.gd สืบทอดไฟล์นี้)
## ทำหน้าที่: พื้นหลัง (ภาพจริง/สำรอง), สไตล์ปุ่ม, hover, เฟด, กันกดซ้ำ, ปุ่ม MAIN MENU
## ปุ่มแรก (PrimaryButton) ให้คลาสลูกกำหนดการทำงานเองใน _on_primary_pressed()

const MAIN_MENU_SCENE := "res://ui/main_menu.tscn"

# ---------- พื้นหลัง ----------
## ถ้าใส่ภาพ จะแสดงภาพนี้ ถ้าว่างจะใช้พื้นหลังสำรองที่วาดด้วยโค้ด
@export var background_texture: Texture2D

# ---------- หน้าตา ----------
@export var button_font: Font
@export var button_font_size: int = 34
@export var title_font_size: int = 56
@export var primary_color := Color("a8d8f0")   # ฟ้า
@export var menu_color := Color("f2b8dc")      # ชมพู
@export var text_color := Color("fff6e0")      # ครีม
@export var border_color := Color("7a4a22")    # น้ำตาลไม้
@export var title_color := Color("fff6e0")
@export var title_outline_color := Color("7a4a22")

@export var fade_time: float = 0.5

@onready var stage: Control = %Stage
@onready var background: TextureRect = %Background
@onready var title_label: Label = %TitleLabel
@onready var primary_button: Button = %PrimaryButton
@onready var menu_button: Button = %MenuButton
@onready var fade_rect: ColorRect = %FadeRect
@onready var hover_sound: AudioStreamPlayer = %HoverSound
@onready var click_sound: AudioStreamPlayer = %ClickSound

var _busy := false


func _ready() -> void:
	# ตอนเล่นเมาส์ถูกซ่อนและเกมอาจ pause อยู่ ต้องคืนค่าไม่งั้นคลิกปุ่มไม่ได้
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = false

	# ---- พื้นหลัง ----
	background.texture = background_texture
	if background_texture == null:
		background.hide()
		_build_fallback_background()

	# ---- หน้าตา ----
	_style_title()
	_style_button(primary_button, primary_color)
	_style_button(menu_button, menu_color)
	for b in [primary_button, menu_button]:
		_setup_hover(b)

	primary_button.pressed.connect(_on_primary_pressed)
	menu_button.pressed.connect(_on_menu_pressed)

	# ---- เฟดเข้า ----
	fade_rect.show()
	fade_rect.modulate.a = 1.0
	create_tween().tween_property(fade_rect, "modulate:a", 0.0, fade_time)

	# ให้เล่นด้วยคีย์บอร์ด/จอยได้ทันที
	primary_button.grab_focus.call_deferred()

	_play_intro()


# ============ จุดให้คลาสลูก override ============

## วาดพื้นหลังสำรอง (เรียกเมื่อไม่มี background_texture) ใส่เป็นลูกของ stage แล้วใช้ _add_behind_ui()
func _build_fallback_background() -> void:
	pass


## แอนิเมชันตอนเปิดหน้า (หัวข้อ ฯลฯ)
func _play_intro() -> void:
	pass


func _on_primary_pressed() -> void:
	pass


# ============ พื้นหลังสำรอง ============

## วาง node ไว้เหนือ Background แต่ใต้ปุ่มและหัวข้อ
func _add_behind_ui(node: Node, order: int = 0) -> void:
	stage.add_child(node)
	stage.move_child(node, background.get_index() + 1 + order)


func _make_gradient_rect(gradient: Gradient) -> TextureRect:
	var tex := GradientTexture2D.new()
	tex.gradient = gradient
	tex.fill_from = Vector2(0, 0)
	tex.fill_to = Vector2(0, 1)
	var rect := TextureRect.new()
	rect.texture = tex
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return rect


# ============ สไตล์ ============

func _style_title() -> void:
	if button_font:
		title_label.add_theme_font_override("font", button_font)
	title_label.add_theme_font_size_override("font_size", title_font_size)
	title_label.add_theme_color_override("font_color", title_color)
	title_label.add_theme_color_override("font_outline_color", title_outline_color)
	title_label.add_theme_constant_override("outline_size", 16)
	title_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.35))
	title_label.add_theme_constant_override("shadow_offset_y", 4)
	title_label.resized.connect(func() -> void: title_label.pivot_offset = title_label.size / 2.0)
	title_label.pivot_offset = title_label.size / 2.0


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
	button.add_theme_font_size_override("font_size", button_font_size)


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
	button.resized.connect(func() -> void: button.pivot_offset = button.size / 2.0)
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
	if hovered and hover_sound.stream:
		hover_sound.play()


# ============ การทำงานของปุ่ม ============

func _on_menu_pressed() -> void:
	# ผ่าน quit_to_menu() เพื่อให้ GameManager ล้างสถานะ (เปิดหน้านี้ตรง ๆ ด้วย F6 ก็ยังไม่ค้าง ดู _call_game_manager)
	_leave_to_game_manager(&"quit_to_menu")


## เรียกฟังก์ชันของ GameManager หลังเฟดดำ (ใช้จากคลาสลูก)
func _leave_to_game_manager(method: StringName) -> void:
	_play_click()
	_leave(_call_game_manager.bind(method))


func _call_game_manager(method: StringName) -> void:
	var gm := get_node_or_null("/root/GameManager")
	if gm and gm.has_method(method):
		gm.call(method)
	else:
		# เปิดหน้านี้ตรง ๆ (F6) โดยไม่มี GameManager -> ไม่ค้างดำ ให้กดใหม่ได้
		push_error("ไม่พบ GameManager.%s()" % method)
		_busy = false
		create_tween().tween_property(fade_rect, "modulate:a", 0.0, fade_time)


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
