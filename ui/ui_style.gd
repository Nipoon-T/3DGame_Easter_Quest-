extends RefCounted
## ตัวช่วยสไตล์ปุ่มที่ใช้ร่วมกัน (ใช้ผ่าน const UIStyle := preload("res://ui/ui_style.gd"))
## หน้าตาเหมือน main_menu.gd: มุมมน เงาเบา ๆ ขยาย 1.06 ตอน hover


static func style_button(button: Button, base: Color, text_color: Color, border_color: Color,
		font: Font, font_size: int, scale_factor: float = 1.0) -> void:
	button.add_theme_stylebox_override("normal", make_box(base, border_color, false, scale_factor))
	button.add_theme_stylebox_override("hover", make_box(base.lightened(0.15), border_color, false, scale_factor))
	button.add_theme_stylebox_override("pressed", make_box(base.darkened(0.12), border_color, true, scale_factor))
	button.add_theme_stylebox_override("focus", make_focus_box())

	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, text_color)
	button.add_theme_color_override("font_outline_color", border_color)
	button.add_theme_constant_override("outline_size", roundi(10 * scale_factor))

	if font:
		button.add_theme_font_override("font", font)
	button.add_theme_font_size_override("font_size", font_size)


static func make_box(color: Color, border_color: Color, pressed: bool, scale_factor: float = 1.0) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(roundi(24 * scale_factor))
	box.set_border_width_all(4)
	box.border_color = border_color
	box.shadow_color = Color(0, 0, 0, 0.3)
	box.shadow_size = 2 if pressed else 6
	box.shadow_offset = Vector2(0, 2 if pressed else 6)
	box.content_margin_left = 24
	box.content_margin_right = 24
	return box


static func make_focus_box() -> StyleBoxFlat:
	# กรอบขาวรอบปุ่มเวลาเลือกด้วยคีย์บอร์ด/จอย
	var box := StyleBoxFlat.new()
	box.draw_center = false
	box.set_corner_radius_all(28)
	box.set_border_width_all(4)
	box.border_color = Color.WHITE
	box.set_expand_margin_all(6)
	return box


## ให้ปุ่มขยายจากตรงกลางตอน hover/focus  on_hover(button, hovered) ใช้เล่นเสียงหรือเช็คกันกดซ้ำ
static func setup_hover(button: Button, on_hover: Callable) -> void:
	button.resized.connect(func() -> void: button.pivot_offset = button.size / 2.0)
	button.pivot_offset = button.size / 2.0
	button.mouse_entered.connect(on_hover.bind(button, true))
	button.mouse_exited.connect(on_hover.bind(button, false))
	button.focus_entered.connect(on_hover.bind(button, true))
	button.focus_exited.connect(on_hover.bind(button, false))


static func hover_tween(button: Button, hovered: bool) -> void:
	var target := Vector2.ONE * (1.06 if hovered else 1.0)
	button.create_tween().tween_property(button, "scale", target, 0.12) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
