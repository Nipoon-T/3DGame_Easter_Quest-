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
		"Hello! I'm the Easter Spirit.",
		"{eggs} Easter eggs are hidden in this dark room.",
		"Aim at an egg and press E to collect it.",
		"Stuck? Use a Hint! Golden stars give you extra hints.",
		"You have {time} seconds. Good luck!",
	],
	[
		"Welcome to the Funfair!",
		"{eggs} eggs are hidden around the rides, tables and signs.",
		"You have {time} seconds. Let's go!",
	],
	[
		"This is the Secret Garden, the hardest level!",
		"{eggs} eggs are hidden behind rocks and bushes.",
		"You have {time} seconds.",
	],
	[
		"You made it! The last mystery egg is here.",
		"Find the golden egg to finish your quest.",
	],
]

# ---- ธีมเดียวกับ UI ของคนที่ 3 (ครีม + ขอบน้ำตาลไม้ + ฟอนต์ Fredoka) ----
const UI_FONT := preload("res://ui/fonts/Fredoka-SemiBold.ttf")
const CREAM := Color("fff6e0")
const BROWN := Color("7a4a22")
const MINT := Color("a8e6cf")
const PINK := Color("f2b8dc")
const BLUE := Color("a8d8f0")
const YELLOW := Color("f7e08a")
const GOLD := Color("f5b800")


static func _panel_box(radius: int, pad: int, alpha := 0.95) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(CREAM, alpha)
	box.set_corner_radius_all(radius)
	box.set_border_width_all(6)
	box.border_color = BROWN
	box.shadow_color = Color(0, 0, 0, 0.3)
	box.shadow_size = 9
	box.shadow_offset = Vector2(0, 6)
	box.content_margin_left = pad + 6
	box.content_margin_right = pad + 6
	box.content_margin_top = pad - 4
	box.content_margin_bottom = pad - 4
	return box


static func _style_label(label: Label, size: int, color := BROWN, outline := 0, outline_color := BROWN) -> void:
	label.add_theme_font_override("font", UI_FONT)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_constant_override("outline_size", outline)
	label.add_theme_color_override("font_outline_color", outline_color)


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
	_apply_theme()
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


func _apply_theme() -> void:
	# กล่องข้อความล่างจอ ขนาดอิงจอ 1920x1080 เหมือน HUD
	panel.add_theme_stylebox_override("panel", _panel_box(36, 26))
	panel.offset_left = -560.0
	panel.offset_right = 560.0
	panel.offset_top = -215.0
	panel.offset_bottom = -44.0
	var margin := $Dialogue/Panel/Margin as MarginContainer
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 0)
	var name_label := $Dialogue/Panel/Margin/VBox/Name as Label
	_style_label(name_label, 34, PINK, 10, BROWN)
	_style_label(text_label, 40, BROWN)


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
		say(["Just one more egg!"])
	elif collected < required:
		say(["Great job! %d more to go." % (required - collected)])


func _on_time_changed(seconds_left: float) -> void:
	if low_time_warning > 0.0 and not _warned_low_time and seconds_left <= low_time_warning:
		_warned_low_time = true
		say(["Hurry! Only %d seconds left!" % int(seconds_left)], false)


func _on_level_completed(_level_index: int) -> void:
	say(["Amazing! You found them all!"])


func _on_game_lost() -> void:
	say(["Time's up... Let's try again!"])
