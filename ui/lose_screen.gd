extends "res://ui/end_screen.gd"
## หน้าแพ้ (เวลาหมด) — ปุ่ม TRY AGAIN เรียก GameManager.retry_level(), MAIN MENU กลับเมนูหลัก

@export var star_count: int = 45
@export var title_drop: float = 40.0

@onready var subtitle_label: Label = %SubtitleLabel


func _ready() -> void:
	subtitle_label.modulate.a = 0.0
	if button_font:
		subtitle_label.add_theme_font_override("font", button_font)
	subtitle_label.add_theme_font_size_override("font_size", 28)
	subtitle_label.add_theme_color_override("font_color", text_color)
	subtitle_label.add_theme_color_override("font_outline_color", title_outline_color)
	subtitle_label.add_theme_constant_override("outline_size", 8)
	super()


func _on_primary_pressed() -> void:
	_leave_to_game_manager(&"retry_level")


# ============ พื้นหลังสำรอง ============

func _build_fallback_background() -> void:
	# ไล่สี: น้ำเงินเข้มด้านบน -> ม่วงอ่อนด้านล่าง
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 1.0])
	g.colors = PackedColorArray([Color("1c2250"), Color("b9a4e3")])
	var sky := _make_gradient_rect(g)
	sky.name = "FallbackSky"
	_add_behind_ui(sky)

	# ดาวกะพริบเบา ๆ
	var stars := Control.new()
	stars.name = "FallbackStars"
	stars.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stars.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_add_behind_ui(stars, 1)

	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in star_count:
		var s := ColorRect.new()
		s.mouse_filter = Control.MOUSE_FILTER_IGNORE
		s.color = Color("fff6e0")
		var size := rng.randf_range(3.0, 6.0)
		var ax := rng.randf()
		var ay := rng.randf_range(0.0, 0.75)   # ดาวอยู่ฟ้าครึ่งบน/กลาง
		s.anchor_left = ax
		s.anchor_right = ax
		s.anchor_top = ay
		s.anchor_bottom = ay
		s.offset_right = size
		s.offset_bottom = size
		s.modulate.a = rng.randf_range(0.2, 1.0)
		stars.add_child(s)

		var t := s.create_tween().set_loops()
		t.tween_interval(rng.randf_range(0.0, 2.0))
		t.tween_property(s, "modulate:a", 0.15, rng.randf_range(1.0, 2.2)) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		t.tween_property(s, "modulate:a", 1.0, rng.randf_range(1.0, 2.2)) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


# ============ แอนิเมชันเปิดหน้า ============

func _play_intro() -> void:
	# หัวข้อจางเข้าพร้อมลอยลงเล็กน้อย (ขยับด้วย offset จึงไม่ต้องรอ layout)
	title_label.modulate.a = 0.0
	_set_title_offset(-title_drop)
	var t := create_tween().set_parallel()
	t.tween_property(title_label, "modulate:a", 1.0, 1.1).set_delay(0.3)
	t.tween_method(_set_title_offset, -title_drop, 0.0, 1.4).set_delay(0.3) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(subtitle_label, "modulate:a", 1.0, 0.9).set_delay(1.3)


func _set_title_offset(y: float) -> void:
	title_label.offset_top = y
	title_label.offset_bottom = y
