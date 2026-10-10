extends "res://ui/end_screen.gd"
## หน้าชนะ — ปุ่ม PLAY AGAIN เรียก GameManager.start_new_game(), MAIN MENU กลับเมนูหลัก

@export var ray_count: int = 14
@export var ray_alpha: float = 0.16
@export var ray_spin_seconds: float = 45.0
@export var confetti_amount: int = 90

@onready var confetti: CPUParticles2D = %Confetti

const CONFETTI_COLORS: Array[Color] = [
	Color("f2b8dc"), Color("a8d8f0"), Color("f7a39a"),
	Color("a8e6cf"), Color("fff6e0"), Color("ffd54a"),
]


func _ready() -> void:
	_setup_confetti()
	super()


func _on_primary_pressed() -> void:
	_leave_to_game_manager(&"start_new_game")


# ============ คอนเฟตตี ============

func _setup_confetti() -> void:
	# สุ่มสีต่อชิ้นจาก ramp แบบแยกสี (ไม่ไล่เฉด)
	var g := Gradient.new()
	g.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	var offsets := PackedFloat32Array()
	var colors := PackedColorArray()
	for i in CONFETTI_COLORS.size():
		offsets.append(float(i) / CONFETTI_COLORS.size())
		colors.append(CONFETTI_COLORS[i])
	g.offsets = offsets
	g.colors = colors

	confetti.amount = confetti_amount
	confetti.lifetime = 5.0
	confetti.preprocess = 3.0
	confetti.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	confetti.direction = Vector2.DOWN
	confetti.spread = 25.0
	confetti.gravity = Vector2(0, 140)
	confetti.initial_velocity_min = 40.0
	confetti.initial_velocity_max = 120.0
	confetti.angle_min = 0.0
	confetti.angle_max = 360.0
	confetti.angular_velocity_min = -240.0
	confetti.angular_velocity_max = 240.0
	confetti.scale_amount_min = 5.0
	confetti.scale_amount_max = 11.0
	confetti.color_initial_ramp = g
	confetti.emitting = true

	# ให้คอนเฟตตีเริ่มตกจากขอบบนตามความกว้างจอจริง
	resized.connect(_place_confetti)
	_place_confetti()


func _place_confetti() -> void:
	confetti.position = Vector2(size.x / 2.0, -20.0)
	confetti.emission_rect_extents = Vector2(size.x / 2.0, 10.0)


# ============ พื้นหลังสำรอง ============

func _build_fallback_background() -> void:
	# ไล่สีทอง-ส้มพระอาทิตย์ตก
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	g.colors = PackedColorArray([Color("e8806a"), Color("ffc15e"), Color("ffe9a8")])
	var sky := _make_gradient_rect(g)
	sky.name = "FallbackSky"
	_add_behind_ui(sky)

	# ลำแสงหมุนช้า ๆ จากกลางจอ (Control ขนาด 0 ที่กลางจอ หมุนรอบจุดตัวเอง)
	var rays := Control.new()
	rays.name = "FallbackRays"
	rays.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rays.anchor_left = 0.5
	rays.anchor_right = 0.5
	rays.anchor_top = 0.45
	rays.anchor_bottom = 0.45
	_add_behind_ui(rays, 1)

	var length := 2500.0
	var step := TAU / float(ray_count)
	for i in ray_count:
		if i % 2 == 1:
			continue   # เว้นช่องสลับกัน ได้เป็นซี่แสง
		var a1 := step * i
		var a2 := step * (i + 1)
		var wedge := Polygon2D.new()
		wedge.polygon = PackedVector2Array([
			Vector2.ZERO,
			Vector2(cos(a1), sin(a1)) * length,
			Vector2(cos(a2), sin(a2)) * length,
		])
		wedge.color = Color(1, 1, 1, ray_alpha)
		rays.add_child(wedge)

	rays.create_tween().set_loops() \
		.tween_property(rays, "rotation", TAU, ray_spin_seconds).from(0.0)


# ============ แอนิเมชันเปิดหน้า ============

func _play_intro() -> void:
	# หัวข้อเด้งเข้ามา แล้วพองเบา ๆ ต่อเนื่อง
	title_label.scale = Vector2.ZERO
	title_label.modulate.a = 0.0
	var t := create_tween()
	t.tween_interval(0.3)
	t.tween_property(title_label, "modulate:a", 1.0, 0.1)
	t.parallel().tween_property(title_label, "scale", Vector2.ONE, 0.8) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	t.tween_callback(_start_title_pulse)


func _start_title_pulse() -> void:
	var p := create_tween().set_loops()
	p.tween_property(title_label, "scale", Vector2.ONE * 1.04, 0.9) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	p.tween_property(title_label, "scale", Vector2.ONE, 0.9) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
