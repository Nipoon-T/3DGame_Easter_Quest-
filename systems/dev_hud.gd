extends CanvasLayer
## =========================================================
## DevHUD — HUD ชั่วคราวสำหรับทดสอบด่าน (เจ้าของ: คนที่ 2)
## แสดงเวลา / จำนวนไข่ / Hint โดยฟัง signal จาก GameManager เท่านั้น
##
## เมื่อ HUD จริงของคนที่ 3 (ui/hud.tscn) เสร็จ:
##   ลบ node DevHUD ออกจากด่าน หรือปล่อยไว้ก็ได้ — มันจะซ่อนตัวเองถ้าเจอ node ใน group "hud"
## =========================================================

const LOW_TIME := 30.0

@onready var time_label: Label = $Top/TimeBox/Time
@onready var egg_label: Label = $Top/EggBox/HB/Eggs
@onready var hint_label: Label = $Top/HintBox/Hints
@onready var banner: Label = $Banner

var _banner_tween: Tween


func _ready() -> void:
	add_to_group("dev_hud")
	process_mode = Node.PROCESS_MODE_ALWAYS   # ให้โชว์ข้อความตอน pause ได้
	banner.visible = false
	$PauseLabel.visible = false
	GameManager.paused_changed.connect(func(p): $PauseLabel.visible = p)
	GameManager.time_changed.connect(_on_time_changed)
	GameManager.egg_collected.connect(_on_egg_collected)
	GameManager.hints_changed.connect(_on_hints_changed)
	GameManager.level_completed.connect(func(_i): _show_banner("ผ่านด่าน!", Color(0.6, 1, 0.6)))
	GameManager.game_lost.connect(func(): _show_banner("หมดเวลา!", Color(1, 0.45, 0.45)))
	# ค่าเริ่มต้น (กรณี signal ถูกส่งไปก่อน HUD พร้อม)
	_on_time_changed(GameManager.time_left)
	_on_egg_collected(GameManager.eggs_collected, GameManager.eggs_required)
	_on_hints_changed(GameManager.hints_left)
	$Top/TimeBox.visible = GameManager.has_timer
	# มี HUD จริงแล้ว -> ซ่อนตัวเอง
	await get_tree().process_frame
	if not get_tree().get_nodes_in_group("hud").is_empty():
		visible = false


func _on_time_changed(seconds_left: float) -> void:
	$Top/TimeBox.visible = GameManager.has_timer
	var s := int(ceil(seconds_left))
	time_label.text = "%d:%02d" % [s / 60, s % 60]
	if seconds_left <= LOW_TIME:
		# กะพริบสีแดงเมื่อเวลาใกล้หมด
		var blink := int(seconds_left * 2.0) % 2 == 0
		time_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3) if blink else Color(1, 0.75, 0.75))
	else:
		time_label.add_theme_color_override("font_color", Color.WHITE)


func _on_egg_collected(collected: int, required: int) -> void:
	egg_label.text = "%d / %d" % [collected, required]


func _on_hints_changed(hints_left: int) -> void:
	hint_label.text = "Hint %d  (กด H)   หยุด: P" % hints_left


func _show_banner(text: String, color: Color) -> void:
	banner.text = text
	banner.add_theme_color_override("font_color", color)
	banner.visible = true
	banner.modulate.a = 0.0
	if _banner_tween:
		_banner_tween.kill()
	_banner_tween = create_tween()
	_banner_tween.tween_property(banner, "modulate:a", 1.0, 0.25)
	_banner_tween.tween_interval(1.5)
	_banner_tween.tween_property(banner, "modulate:a", 0.0, 0.4)
