extends Node
## ทดสอบ HUD: จำลอง signal ผ่าน GameManager
## B = สลับพื้นหลังมืด/สว่าง  1 = เก็บไข่  2 = เวลาเหลือ 25 วิ (นับถอยหลัง)
## 3 = ใช้ Hint  4 = เริ่มด่านถัดไป  5 = ผ่านด่าน  6 = หมดเวลา (game_lost)
## 7 = สลับ pause/resume (เรียก GameManager.set_paused จึงเหมือนกด P จริง ๆ แต่ใช้ได้โดยไม่ต้องมีด่าน)

const REQUIRED: int = 10

@onready var background: ColorRect = %Background

var _dark: bool = true
var _collected: int = 0
var _hints: int = 3
var _level: int = 0
var _time_left: float = 0.0
var _counting: bool = false


func _ready() -> void:
	# ต้องรับปุ่มต่อได้ตอนเกม pause ไม่งั้นกด 7 เพื่อ resume ไม่ได้
	process_mode = Node.PROCESS_MODE_ALWAYS
	# HUD ฟัง signal เท่านั้น จึงต้องตั้งค่าสถานะที่ HUD อ่านเป็นค่าเริ่มต้นเอง
	GameManager.has_timer = true
	_apply_background()
	_start_level(0)


func _process(delta: float) -> void:
	if not _counting or get_tree().paused:
		return
	_time_left = maxf(_time_left - delta, 0.0)
	GameManager.time_left = _time_left
	GameManager.time_changed.emit(_time_left)
	if _time_left <= 0.0:
		_counting = false


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	match key.physical_keycode:
		KEY_B:
			_dark = not _dark
			_apply_background()
		KEY_1:
			_collected = mini(_collected + 1, REQUIRED)
			GameManager.eggs_collected = _collected
			GameManager.egg_collected.emit(_collected, REQUIRED)
		KEY_2:
			_time_left = 25.0
			_counting = true
		KEY_3:
			_hints = maxi(_hints - 1, 0)
			GameManager.hints_left = _hints
			GameManager.hints_changed.emit(_hints)
		KEY_4:
			_start_level((_level + 1) % 4)
		KEY_5:
			GameManager.level_completed.emit(_level)
		KEY_7:
			GameManager.set_paused(not get_tree().paused)
		KEY_6:
			_counting = false
			GameManager.game_lost.emit()


func _start_level(index: int) -> void:
	_level = index
	_collected = 0
	_hints = 3
	_time_left = 180.0
	_counting = false
	GameManager.current_level = index
	GameManager.eggs_collected = 0
	GameManager.eggs_required = REQUIRED
	GameManager.time_left = _time_left
	GameManager.hints_left = _hints
	GameManager.level_started.emit(index)
	GameManager.egg_collected.emit(0, REQUIRED)
	GameManager.hints_changed.emit(_hints)
	GameManager.time_changed.emit(_time_left)


func _apply_background() -> void:
	background.color = Color("0a0a14") if _dark else Color("bfe8ff")
