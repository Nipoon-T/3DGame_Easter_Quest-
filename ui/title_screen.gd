extends Control
## หน้าเปิดเกม Easter Quest
## คลิกเมาส์ / กดคีย์ใดก็ได้ / แตะจอ / กดปุ่มจอย -> ไปหน้าเมนูหลัก

## scene ที่จะไปต่อ (เปลี่ยนได้ใน Inspector)
@export_file("*.tscn") var next_scene: String = "res://ui/main_menu.tscn"
## ความเร็วกะพริบของข้อความ (วินาทีต่อครึ่งรอบ)
@export var blink_time: float = 0.8
## เวลาเฟดดำตอนเข้า/ออก
@export var fade_time: float = 0.6

@onready var background: TextureRect = $Background
@onready var prompt_label: Label = $PromptLabel
@onready var fade_rect: ColorRect = $FadeRect
@onready var click_sound: AudioStreamPlayer = $ClickSound

var _is_leaving := false
var _blink_tween: Tween


func _ready() -> void:
	# เริ่มจากจอดำ แล้วค่อย ๆ สว่างขึ้น
	fade_rect.visible = true
	fade_rect.modulate.a = 1.0
	create_tween().tween_property(fade_rect, "modulate:a", 0.0, fade_time)

	_start_blink()
	_start_background_zoom()


func _start_blink() -> void:
	_blink_tween = create_tween().set_loops()
	_blink_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_blink_tween.tween_property(prompt_label, "modulate:a", 0.25, blink_time)
	_blink_tween.tween_property(prompt_label, "modulate:a", 1.0, blink_time)


func _start_background_zoom() -> void:
	# ซูมพื้นหลังเข้า-ออกช้า ๆ ให้ภาพดูมีชีวิต
	# อัปเดตจุดหมุนทุกครั้งที่ขนาดเปลี่ยน ไม่งั้นย่อ/ขยายหน้าต่างแล้วภาพจะซูมเบี้ยว
	background.resized.connect(_update_zoom_pivot)
	_update_zoom_pivot()
	var t := create_tween().set_loops()
	t.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(background, "scale", Vector2(1.04, 1.04), 8.0)
	t.tween_property(background, "scale", Vector2.ONE, 8.0)


func _update_zoom_pivot() -> void:
	background.pivot_offset = background.size / 2.0


func _input(event: InputEvent) -> void:
	if _is_leaving:
		return

	var should_start := false

	if event is InputEventMouseButton and event.pressed:
		# รับเฉพาะคลิกซ้าย/ขวา ไม่นับการหมุนลูกกลิ้งเมาส์
		should_start = event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]
	elif event is InputEventKey and event.pressed and not event.echo:
		should_start = true
	elif event is InputEventScreenTouch and event.pressed:
		should_start = true
	elif event is InputEventJoypadButton and event.pressed:
		should_start = true

	if should_start:
		get_viewport().set_input_as_handled()
		_go_to_next_scene()


func _go_to_next_scene() -> void:
	_is_leaving = true

	if _blink_tween:
		_blink_tween.kill()
	prompt_label.modulate.a = 1.0

	if click_sound.stream:
		click_sound.play()

	var t := create_tween()
	t.tween_property(fade_rect, "modulate:a", 1.0, fade_time)
	await t.finished

	if not ResourceLoader.exists(next_scene):
		push_error("ไม่พบ scene: %s" % next_scene)
		# เฟดกลับเข้ามาให้กดใหม่ได้ ไม่ค้างจอดำ
		var back := create_tween()
		back.tween_property(fade_rect, "modulate:a", 0.0, fade_time)
		await back.finished
		_start_blink()
		_is_leaving = false
		return

	get_tree().change_scene_to_file(next_scene)
