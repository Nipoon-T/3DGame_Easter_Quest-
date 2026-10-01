extends Node
## GameManager — ตั้งเป็น Autoload ชื่อ "GameManager"
## (Project > Project Settings > Globals > Autoload > path: res://systems/game_manager.gd)
##
## เจ้าของไฟล์: สมาชิกคนที่ 2 (Game Systems)
## คนอื่นเรียกใช้ได้ แต่ถ้าจะแก้ให้แจ้งเจ้าของก่อน
##
## วิธีใช้:
##   - ทุกด่านใช้ levels/level.gd เป็น script ของ node ราก -> ด่านจะเรียก start_level() เอง
##   - ไข่ (egg.tscn) จะเรียก collect_egg() เองเมื่อผู้เล่นเดินชน
##   - UI ฟัง signal ด้านล่างเพื่ออัปเดต HUD ไม่ต้องไปอ่านค่าจาก node อื่น

signal egg_collected(collected: int, required: int)
signal time_changed(seconds_left: float)
signal hints_changed(hints_left: int)
signal level_started(level_index: int)
signal level_completed(level_index: int)
signal game_won
signal game_lost

# ---- ลำดับด่าน (แก้ path ให้ตรงกับไฟล์จริง) ----
const LEVELS: Array[String] = [
	"res://levels/level1_dark_room.tscn",
	"res://levels/level2_funfair.tscn",
	"res://levels/level3_secret_garden.tscn",
]
const FINAL_AREA := "res://levels/final_area.tscn"
const WIN_SCREEN := "res://ui/win_screen.tscn"
const LOSE_SCREEN := "res://ui/lose_screen.tscn"

const START_HINTS := 3          # จำนวน Hint ตอนเริ่มเกม
const NEXT_LEVEL_DELAY := 1.5   # หน่วงก่อนเปลี่ยนด่าน (วินาที) ให้ UI โชว์ "ผ่านด่าน!"

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


# ================== เริ่ม / เปลี่ยนด่าน ==================

func start_new_game() -> void:
	total_eggs_collected = 0
	hints_left = START_HINTS
	load_level(0)


func load_level(index: int) -> void:
	current_level = index
	is_running = false
	get_tree().paused = false
	if index < LEVELS.size():
		get_tree().change_scene_to_file.call_deferred(LEVELS[index])
	else:
		get_tree().change_scene_to_file.call_deferred(FINAL_AREA)


func retry_level() -> void:
	load_level(max(current_level, 0))


## ถูกเรียกจาก level.gd ตอนด่านโหลดเสร็จ
func start_level(level: Node, time_limit: float, required: int) -> void:
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

	level_started.emit(current_level)
	egg_collected.emit(eggs_collected, eggs_required)
	hints_changed.emit(hints_left)
	if has_timer:
		time_changed.emit(time_left)


# ================== Timer ==================

func _process(delta: float) -> void:
	if not is_running or not has_timer:
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
	if InputMap.has_action("hint") and event.is_action_pressed("hint"):
		use_hint()


# ================== จบด่าน / ชนะ / แพ้ ==================

func _complete_level() -> void:
	is_running = false
	level_completed.emit(current_level)
	await get_tree().create_timer(NEXT_LEVEL_DELAY).timeout
	load_level(current_level + 1)   # ถ้าครบ 3 ด่านแล้วจะไป FINAL_AREA เอง


func _win() -> void:
	is_running = false
	game_won.emit()
	get_tree().change_scene_to_file.call_deferred(WIN_SCREEN)


func _lose() -> void:
	is_running = false
	game_lost.emit()
	get_tree().change_scene_to_file.call_deferred(LOSE_SCREEN)
