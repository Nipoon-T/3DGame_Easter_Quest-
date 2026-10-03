extends Node
## GameManager — ตั้งเป็น Autoload ชื่อ "GameManager"
## (Project > Project Settings > Globals > Autoload > path: res://systems/game_manager.gd)
##
## เจ้าของไฟล์: สมาชิกคนที่ 2 (Game Systems)
## คนอื่นเรียกใช้ได้ แต่ถ้าจะแก้ให้แจ้งเจ้าของก่อน
##
## วิธีใช้:
##   - ทุกด่านใช้ levels/level.gd เป็น script ของ node ราก -> ด่านจะเรียก start_level() เอง
##   - ไข่ (egg.tscn) จะเรียก collect_egg() เองเมื่อผู้เล่นเล็งแล้วกด E (ปุ่ม interact)
##   - UI ฟัง signal ด้านล่างเพื่ออัปเดต HUD ไม่ต้องไปอ่านค่าจาก node อื่น

signal egg_collected(collected: int, required: int)
signal time_changed(seconds_left: float)
signal hints_changed(hints_left: int)
signal level_started(level_index: int)
signal level_completed(level_index: int)
signal game_won
signal game_lost
signal paused_changed(is_paused: bool)   ## UI ใช้โชว์/ซ่อนเมนู Pause

# ---- ลำดับด่าน (แก้ path ให้ตรงกับไฟล์จริง) ----
const LEVELS: Array[String] = [
	"res://levels/level1_dark_room.tscn",
	"res://levels/level2_funfair.tscn",
	"res://levels/level3_secret_garden.tscn",
]
const FINAL_AREA := "res://levels/final_area.tscn"
const WIN_SCREEN := "res://ui/win_screen.tscn"
const LOSE_SCREEN := "res://ui/lose_screen.tscn"
# เพิ่มโดยคนที่ 3 (UI) สำหรับปุ่ม Main Menu / ป้าย Time's Up
const MAIN_MENU := "res://ui/main_menu.tscn"

const START_HINTS := 3          # จำนวน Hint ตอนเริ่มเกม
const NEXT_LEVEL_DELAY := 1.5   # หน่วงก่อนเปลี่ยนด่าน (วินาที) ให้ UI โชว์ "ผ่านด่าน!"
# เพิ่มโดยคนที่ 3 (UI) สำหรับปุ่ม Main Menu / ป้าย Time's Up
const LOSE_DELAY := 1.5         # หน่วงก่อนไปหน้าแพ้ (วินาที) ให้ UI โชว์ "Time's Up!"

## Hint โบนัสที่ได้เพิ่มตอนเริ่มแต่ละด่าน (index ตรงกับ LEVELS) — ปรับตรงนี้ตอนบาลานซ์วันที่ 9
## เช่น [0, 1, 2] = ด่าน 1 ไม่ได้เพิ่ม, ด่าน 2 ได้ +1, ด่าน 3 (ยากสุด) ได้ +2
const LEVEL_BONUS_HINTS: Array[int] = [0, 1, 2]

# ---- สถานะเกม ----
var selected_character := "lily"   # "lily" หรือ "leo" — หน้าเลือกตัวละครตั้งค่านี้
var current_level := -1
var eggs_collected := 0
var eggs_required := 0
var total_eggs_collected := 0      # รวมทุกด่าน ใช้โชว์หน้าชนะ
var time_left := 0.0
var has_timer := false
var hints_left := START_HINTS
var is_running := false

# ค่าตอนเริ่มด่าน — ใช้คืนค่าเมื่อกดลองใหม่ (retry) ไม่ให้นับไข่/Hint ซ้ำ
var _total_at_level_start := 0
var _hints_at_level_start := START_HINTS
var _bonus_given_for := -1   # กันไม่ให้ได้โบนัสซ้ำเมื่อกดลองใหม่
# เพิ่มโดยคนที่ 3 (UI) สำหรับปุ่ม Main Menu / ป้าย Time's Up
var _lose_pending := false   # กำลังรอ LOSE_DELAY — quit_to_menu() ยกเลิกได้


func _ready() -> void:
	# GameManager ต้องทำงานตอน pause ด้วย ไม่งั้นกดปุ่ม unpause ไม่ได้
	process_mode = Node.PROCESS_MODE_ALWAYS


# ================== เริ่ม / เปลี่ยนด่าน ==================

func start_new_game() -> void:
	total_eggs_collected = 0
	hints_left = START_HINTS
	_total_at_level_start = 0
	_hints_at_level_start = START_HINTS
	_bonus_given_for = -1
	load_level(0)


func load_level(index: int) -> void:
	# ข้ามด่านที่ยังไม่มีไฟล์ (ช่วงที่เพื่อนยังทำด่านไม่เสร็จ) เกมจะได้ไม่พัง
	while index < LEVELS.size() and not ResourceLoader.exists(LEVELS[index]):
		push_warning("GameManager: ยังไม่มีไฟล์ด่าน %s -> ข้ามไปด่านถัดไป" % LEVELS[index])
		index += 1

	current_level = index
	is_running = false
	set_paused(false)
	_total_at_level_start = total_eggs_collected
	_hints_at_level_start = hints_left

	if index < LEVELS.size():
		get_tree().change_scene_to_file.call_deferred(LEVELS[index])
	else:
		_change_scene_safe(FINAL_AREA)


## ลองด่านเดิมใหม่ — คืนค่าไข่รวมและ Hint กลับเป็นตอนเริ่มด่าน
func retry_level() -> void:
	total_eggs_collected = _total_at_level_start
	hints_left = _hints_at_level_start
	load_level(max(current_level, 0))


## ถูกเรียกจาก level.gd ตอนด่านโหลดเสร็จ
func start_level(level: Node, time_limit: float, required: int) -> void:
	# เปิด scene ด่านตรงๆ ด้วย F6 (ไม่ผ่านเมนู) -> หาเลขด่านจากชื่อไฟล์เอง
	var path := level.scene_file_path
	var idx := LEVELS.find(path)
	if idx != -1:
		current_level = idx
	elif path == FINAL_AREA:
		current_level = LEVELS.size()

	var eggs_in_level := 0
	for e in get_tree().get_nodes_in_group("egg"):
		if e is Egg and not e.is_mystery:
			eggs_in_level += 1

	eggs_collected = 0
	eggs_required = required if required > 0 else eggs_in_level
	if eggs_required > eggs_in_level:
		push_warning("%s: ต้องเก็บ %d ใบ แต่ในด่านมีแค่ %d ใบ" % [level.name, eggs_required, eggs_in_level])
		eggs_required = eggs_in_level

	has_timer = time_limit > 0.0
	time_left = time_limit
	is_running = true

	# Hint โบนัสประจำด่าน (ให้ครั้งเดียวต่อด่าน แม้จะกดลองใหม่)
	if current_level < LEVEL_BONUS_HINTS.size() and _bonus_given_for != current_level:
		_bonus_given_for = current_level
		hints_left += LEVEL_BONUS_HINTS[current_level]
		_hints_at_level_start = hints_left

	level_started.emit(current_level)
	egg_collected.emit(eggs_collected, eggs_required)
	hints_changed.emit(hints_left)
	if has_timer:
		time_changed.emit(time_left)


# ================== Timer ==================

func _process(delta: float) -> void:
	if not is_running or not has_timer or get_tree().paused:
		return
	time_left = max(time_left - delta, 0.0)
	time_changed.emit(time_left)
	if time_left <= 0.0:
		_lose()


# ================== เก็บไข่ ==================

func collect_egg(egg: Egg) -> void:
	if not is_running:
		return
	if egg.is_mystery:
		_win()
		return
	eggs_collected += 1
	total_eggs_collected += 1
	egg_collected.emit(eggs_collected, eggs_required)
	if eggs_required > 0 and eggs_collected >= eggs_required:
		_complete_level()


# ================== Hint ==================

func add_hint(amount: int = 1) -> void:
	hints_left += amount
	hints_changed.emit(hints_left)


## เรียกจากปุ่ม Hint ใน HUD หรือกดปุ่ม "hint" บนคีย์บอร์ด
## ไข่ที่ใกล้ผู้เล่นที่สุดจะเด้งและเรืองแสงสักครู่
func use_hint() -> bool:
	if not is_running or hints_left <= 0:
		return false
	var player := get_tree().get_first_node_in_group("player") as Node3D
	var best: Egg = null
	var best_dist := INF
	for e in get_tree().get_nodes_in_group("egg"):
		if not (e is Egg) or e.collected:
			continue
		# ในด่านปกติไม่ชี้ไข่ลับ (ไข่ลับมีแค่พื้นที่สุดท้าย)
		if e.is_mystery and current_level < LEVELS.size():
			continue
		var d := 0.0
		if player:
			d = player.global_position.distance_to(e.global_position)
		if d < best_dist:
			best_dist = d
			best = e
	if best == null:
		return false
	hints_left -= 1
	hints_changed.emit(hints_left)
	best.show_hint()
	return true


func _unhandled_input(event: InputEvent) -> void:
	# ---- Pause: ใช้ action "pause" ถ้ามี ไม่มีก็ใช้ปุ่ม P ไปก่อน (ESC ใช้ปล่อยเมาส์อยู่แล้ว) ----
	if InputMap.has_action("pause"):
		if event.is_action_pressed("pause"):
			toggle_pause()
			return
	elif event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_P:
		toggle_pause()
		return

	if get_tree().paused:
		return

	if InputMap.has_action("hint"):
		if event.is_action_pressed("hint"):
			use_hint()
	# ยังไม่มี action "hint" ใน Input Map (คนที่ 1 ตั้งใน project.godot) -> ใช้ปุ่ม H ไปก่อน
	elif event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_H:
		use_hint()


# ================== Pause ==================

## UI เรียกใช้ได้เลย เช่น ปุ่ม "เล่นต่อ" -> GameManager.set_paused(false)
func set_paused(value: bool) -> void:
	if get_tree().paused == value:
		return
	get_tree().paused = value
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if value else Input.MOUSE_MODE_CAPTURED
	paused_changed.emit(value)


func toggle_pause() -> void:
	# pause ได้เฉพาะตอนกำลังเล่นด่าน
	if not is_running and not get_tree().paused:
		return
	set_paused(not get_tree().paused)


# ================== จบด่าน / ชนะ / แพ้ ==================

func _complete_level() -> void:
	is_running = false
	level_completed.emit(current_level)
	await get_tree().create_timer(NEXT_LEVEL_DELAY).timeout
	load_level(current_level + 1)   # ถ้าครบ 3 ด่านแล้วจะไป FINAL_AREA เอง


func _win() -> void:
	is_running = false
	game_won.emit()
	if not _change_scene_safe(WIN_SCREEN):
		print("GameManager: ชนะแล้ว! (ยังไม่มี win_screen.tscn) ไข่รวม = %d" % total_eggs_collected)


func _lose() -> void:
	if _lose_pending:
		return
	is_running = false
	_lose_pending = true
	game_lost.emit()
	await get_tree().create_timer(LOSE_DELAY).timeout
	if not _lose_pending:   # ผู้เล่นกด Main Menu ระหว่างรอ -> ไม่ไปหน้าแพ้
		return
	_lose_pending = false
	if not _change_scene_safe(LOSE_SCREEN):
		# ยังไม่มีหน้าแพ้ของคนที่ 3 -> รอสักครู่แล้วเริ่มด่านเดิมใหม่ให้ทดสอบต่อได้
		print("GameManager: หมดเวลา! (ยังไม่มี lose_screen.tscn) เริ่มด่านใหม่ใน 2 วินาที")
		await get_tree().create_timer(2.0).timeout
		retry_level()


# เพิ่มโดยคนที่ 3 (UI) สำหรับปุ่ม Main Menu / ป้าย Time's Up
## กลับเมนูหลัก (ปุ่ม MAIN MENU ใน Pause / หน้าแพ้ / หน้าชนะ)
func quit_to_menu() -> void:
	is_running = false
	_lose_pending = false
	set_paused(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE   # set_paused(false) จับเมาส์กลับ แต่เมนูหลักต้องใช้เมาส์
	_change_scene_safe(MAIN_MENU)


## เปลี่ยน scene เฉพาะเมื่อไฟล์มีอยู่จริง คืนค่า false ถ้าไม่มีไฟล์
func _change_scene_safe(path: String) -> bool:
	if not ResourceLoader.exists(path):
		push_warning("GameManager: ไม่พบไฟล์ %s" % path)
		return false
	get_tree().change_scene_to_file.call_deferred(path)
	return true
