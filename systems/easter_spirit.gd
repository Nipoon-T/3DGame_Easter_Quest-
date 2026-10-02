extends Node3D
class_name EasterSpirit
## =========================================================
## Easter Spirit — ภูติอีสเตอร์ที่พูดอธิบายภารกิจตอนเริ่มด่าน
## เจ้าของไฟล์: คนที่ 2 (Game Systems)
##
## วิธีใช้: ลาก systems/easter_spirit.tscn เข้าไปในด่าน วางใกล้จุดเกิดของผู้เล่น
##   - ฟัง signal จาก GameManager อย่างเดียว ไม่แตะ Player / UI ของคนอื่น
##   - บทพูดแก้ได้ใน Inspector (intro_lines) ถ้าเว้นว่างจะใช้บทพูดตั้งต้นตามเลขด่าน
##   - ในข้อความใช้ {eggs} = จำนวนไข่ที่ต้องเก็บ, {time} = เวลาของด่าน (วินาที)
## =========================================================

@export_multiline var intro_lines: PackedStringArray = []
@export var seconds_per_line := 3.2      ## เวลาที่แต่ละประโยคค้างบนจอ
@export var chars_per_second := 40.0     ## ความเร็วตัวพิมพ์
@export var low_time_warning := 30.0     ## เตือนเมื่อเวลาเหลือเท่านี้ (วินาที) 0 = ไม่เตือน
@export var bob_height := 0.15
@export var bob_speed := 2.0

## บทพูดตั้งต้นของแต่ละด่าน (index ตรงกับ GameManager.LEVELS, ตัวสุดท้าย = พื้นที่ลับ)
const DEFAULT_LINES := [
	[
		"สวัสดีจ้ะ ฉันคือภูติแห่งอีสเตอร์",
		"ไข่อีสเตอร์ {eggs} ใบถูกซ่อนอยู่ในห้องมืดแห่งนี้",
		"เล็งไปที่ไข่แล้วกด E เพื่อเก็บ ไข่จะเรืองแสงจางๆ ในความมืด",
		"หาไม่เจอก็ใช้ Hint ได้ และมีดาวสีทองซ่อนอยู่ เก็บแล้วได้ Hint เพิ่ม",
		"เวลามี {time} วินาที ขอให้โชคดีนะ!",
	],
	[
		"ยินดีต้อนรับสู่สวนสนุก!",
		"ไข่ {eggs} ใบซ่อนอยู่ตามเครื่องเล่น ใต้โต๊ะ และหลังป้าย",
		"มีเวลา {time} วินาที ลุยเลย!",
	],
	[
		"นี่คือสวนลับ ด่านที่ยากที่สุด",
		"ไข่ {eggs} ใบซ่อนอยู่ในพุ่มไม้และบนต้นไม้ ลองกระโดดดูนะ",
		"มีเวลา {time} วินาที",
	],
	[
		"เธอทำได้! ไข่ปริศนาใบสุดท้ายอยู่ที่นี่",
		"ตามหาไข่สีทองให้เจอ แล้วภารกิจจะสำเร็จ",
	],
]

var _queue: Array[String] = []
var _line_timer := 0.0
var _typing := false
var _warned_low_time := false
var _said_last_egg := false
var _t := 0.0
var _base_y := 0.0

@onready var body: Node3D = $Body
@onready var panel: Control = $Dialogue/Panel
@onready var text_label: Label = $Dialogue/Panel/Margin/VBox/Text


func _ready() -> void:
	_base_y = body.position.y
	panel.visible = false
	GameManager.level_started.connect(_on_level_started)
	GameManager.egg_collected.connect(_on_egg_collected)
	GameManager.time_changed.connect(_on_time_changed)
	GameManager.level_completed.connect(_on_level_completed)
	GameManager.game_lost.connect(_on_game_lost)


func _process(delta: float) -> void:
	# ลอยขึ้นลง + หันหน้าหาผู้เล่น
	_t += delta
	body.position.y = _base_y + sin(_t * bob_speed) * bob_height
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player:
		var target := player.global_position
		target.y = body.global_position.y
		if body.global_position.distance_to(target) > 0.1:
			body.look_at(target, Vector3.UP, true)

	# กล่องข้อความ
	if not panel.visible:
		return
	if _typing:
		text_label.visible_characters += max(1, int(chars_per_second * delta))
		if text_label.visible_characters >= text_label.get_total_character_count():
			text_label.visible_characters = -1
			_typing = false
	_line_timer -= delta
	if _line_timer <= 0.0:
		_next_line()


## ให้ภูติพูดประโยคใหม่ (ระบบอื่นเรียกใช้ได้ เช่น EasterSpirit.say("..."))
func say(lines: Array, interrupt := true) -> void:
	if interrupt:
		_queue.clear()
	for l in lines:
		_queue.append(_format(str(l)))
	if interrupt or not panel.visible:
		_next_line()


func _next_line() -> void:
	if _queue.is_empty():
		panel.visible = false
		return
	text_label.text = _queue.pop_front()
	text_label.visible_characters = 0
	_typing = true
	_line_timer = seconds_per_line + text_label.text.length() / chars_per_second
	panel.visible = true


func _format(line: String) -> String:
	return line.format({
		"eggs": GameManager.eggs_required,
		"time": int(GameManager.time_left),
	})


# ---------------- GameManager signals ----------------

func _on_level_started(level_index: int) -> void:
	_warned_low_time = false
	_said_last_egg = false
	var lines: Array = Array(intro_lines)
	if lines.is_empty() and level_index >= 0 and level_index < DEFAULT_LINES.size():
		lines = DEFAULT_LINES[level_index]
	if not lines.is_empty():
		say(lines)


func _on_egg_collected(collected: int, required: int) -> void:
	if collected == 0:
		return
	if required - collected == 1 and not _said_last_egg:
		_said_last_egg = true
		say(["อีกใบเดียวเท่านั้น!"])
	elif collected < required:
		say(["เก่งมาก! เหลืออีก %d ใบ" % (required - collected)])


func _on_time_changed(seconds_left: float) -> void:
	if low_time_warning > 0.0 and not _warned_low_time and seconds_left <= low_time_warning:
		_warned_low_time = true
		say(["รีบหน่อย! เหลือเวลาอีก %d วินาที" % int(seconds_left)], false)


func _on_level_completed(_level_index: int) -> void:
	say(["เยี่ยมมาก! เก็บไข่ครบแล้ว ไปด่านต่อไปกัน!"])


func _on_game_lost() -> void:
	say(["หมดเวลาแล้ว... ลองใหม่อีกครั้งนะ"])
