extends Node
## GameManager — ตั้งเป็น Autoload ชื่อ "GameManager"
## (Project > Project Settings > Globals > Autoload > path: res://systems/game_manager.gd)
<<<<<<< Updated upstream
##
## เจ้าของไฟล์: สมาชิกคนที่ 2 (Game Systems)
## คนอื่นเรียกใช้ได้ แต่ถ้าจะแก้ให้แจ้งเจ้าของก่อน
##
## วิธีใช้:
##   - ทุกด่านใช้ levels/level.gd เป็น script ของ node ราก -> ด่านจะเรียก start_level() เอง
##   - ไข่ (egg.tscn) จะเรียก collect_egg() เองเมื่อผู้เล่นเดินชน
##   - UI ฟัง signal ด้านล่างเพื่ออัปเดต HUD ไม่ต้องไปอ่านค่าจาก node อื่น
=======
>>>>>>> Stashed changes

signal egg_collected(collected: int, required: int)
signal time_changed(seconds_left: float)
signal hints_changed(hints_left: int)
signal level_started(level_index: int)
signal level_completed(level_index: int)
signal game_won
signal game_lost
<<<<<<< Updated upstream
=======
signal paused_changed(is_paused: bool)
>>>>>>> Stashed changes

# ---- ลำดับด่าน ----
const LEVELS: Array[String] = [
	"res://levels/level1_dark_room.tscn",
	"res://levels/level2_funfair.tscn",
	"res://levels/level3_secret_garden.tscn",
]

const FINAL_AREA := "res://levels/final_area.tscn"
const WIN_SCREEN := "res://ui/win_screen.tscn"
const LOSE_SCREEN := "res://ui/lose_screen.tscn"

const START_HINTS := 3
const NEXT_LEVEL_DELAY := 1.5

<<<<<<< Updated upstream
=======
const LEVEL_BONUS_HINTS: Array[int] = [0, 1, 2]

>>>>>>> Stashed changes
# ---- สถานะเกม ----
var selected_character := "lily"
var current_level := -1
var eggs_collected := 0
var eggs_required := 0
var total_eggs_collected := 0
var time_left := 0.0
var has_timer := false
var hints_left := START_HINTS
var is_running := false

<<<<<<< Updated upstream
=======
# ---- ค่าตอนเริ่มด่าน ----
var _total_at_level_start := 0
var _hints_at_level_start := START_HINTS
var _bonus_given_for := -1


func _ready() -> void:
	# GameManager ต้องทำงานแม้เกมถูก pause
	process_mode = Node.PROCESS_MODE_ALWAYS

	# =========================================================
	# ตั้งค่าหน้าต่างเกม Windows
	# =========================================================
	var window := get_window()

	# ต้องเป็น Windowed
	window.mode = Window.MODE_WINDOWED

	# ต้องมีกรอบหน้าต่าง Windows
	window.borderless = false

	# อนุญาตให้ resize
	window.unresizable = false

	# เปิดปุ่ม Minimize / Maximize / Close
	DisplayServer.window_set_flag(
		DisplayServer.WINDOW_FLAG_MINIMIZE_DISABLED,
		false
	)

	DisplayServer.window_set_flag(
		DisplayServer.WINDOW_FLAG_MAXIMIZE_DISABLED,
		false
	)

	# ยืนยันว่าไม่ปิดการ resize
	DisplayServer.window_set_flag(
		DisplayServer.WINDOW_FLAG_RESIZE_DISABLED,
		false
	)

	# ขนาดหน้าต่าง
	window.size = Vector2i(1280, 720)

	# จัดหน้าต่างไว้กลางจอ
	var screen_size := DisplayServer.screen_get_size()

	window.position = Vector2i(
		(screen_size.x - window.size.x) / 2,
		(screen_size.y - window.size.y) / 2
	)

>>>>>>> Stashed changes

# ================== เริ่ม / เปลี่ยนด่าน ==================

func start_new_game() -> void:
	total_eggs_collected = 0
	hints_left = START_HINTS
	load_level(0)


func load_level(index: int) -> void:
<<<<<<< Updated upstream
	current_level = index
	is_running = false
	get_tree().paused = false
=======
	# ข้ามด่านที่ยังไม่มีไฟล์
	while index < LEVELS.size() and not ResourceLoader.exists(LEVELS[index]):
		push_warning(
			"GameManager: ยังไม่มีไฟล์ด่าน %s -> ข้ามไปด่านถัดไป"
			% LEVELS[index]
		)
		index += 1

	current_level = index
	is_running = false
	set_paused(false)

	_total_at_level_start = total_eggs_collected
	_hints_at_level_start = hints_left

>>>>>>> Stashed changes
	if index < LEVELS.size():
		get_tree().change_scene_to_file.call_deferred(LEVELS[index])
	else:
		get_tree().change_scene_to_file.call_deferred(FINAL_AREA)


<<<<<<< Updated upstream
=======
## ลองด่านเดิมใหม่
>>>>>>> Stashed changes
func retry_level() -> void:
	load_level(max(current_level, 0))


## ถูกเรียกจาก level.gd ตอนด่านโหลดเสร็จ
<<<<<<< Updated upstream
func start_level(level: Node, time_limit: float, required: int) -> void:
=======
func start_level(
	level: Node,
	time_limit: float,
	required: int
) -> void:

	# เปิด scene ด่านตรงๆ ด้วย F6
	var path := level.scene_file_path
	var idx := LEVELS.find(path)

	if idx != -1:
		current_level = idx
	elif path == FINAL_AREA:
		current_level = LEVELS.size()

>>>>>>> Stashed changes
	var eggs_in_level := 0

	for e in get_tree().get_nodes_in_group("egg"):
		if e is Egg and not e.is_mystery:
			eggs_in_level += 1

	eggs_collected = 0

	eggs_required = (
		required
		if required > 0
		else eggs_in_level
	)

	if eggs_required > eggs_in_level:
		push_warning(
			"%s: ต้องเก็บ %d ใบ แต่ในด่านมีแค่ %d ใบ"
			% [
				level.name,
				eggs_required,
				eggs_in_level
			]
		)

		eggs_required = eggs_in_level

	has_timer = time_limit > 0.0
	time_left = time_limit
	is_running = true

<<<<<<< Updated upstream
=======
	# Hint โบนัสประจำด่าน
	if (
		current_level < LEVEL_BONUS_HINTS.size()
		and _bonus_given_for != current_level
	):
		_bonus_given_for = current_level
		hints_left += LEVEL_BONUS_HINTS[current_level]
		_hints_at_level_start = hints_left

>>>>>>> Stashed changes
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

	egg_collected.emit(
		eggs_collected,
		eggs_required
	)

	if (
		eggs_required > 0
		and eggs_collected >= eggs_required
	):
		_complete_level()


# ================== Hint ==================

func add_hint(amount: int = 1) -> void:
	hints_left += amount
	hints_changed.emit(hints_left)


func use_hint() -> bool:
	if not is_running or hints_left <= 0:
		return false

	var player := (
		get_tree().get_first_node_in_group("player")
		as Node3D
	)

	var best: Egg = null
	var best_dist := INF

	for e in get_tree().get_nodes_in_group("egg"):
		if not (e is Egg) or e.collected:
			continue
<<<<<<< Updated upstream
=======

		# ด่านปกติไม่ชี้ไข่ลับ
		if e.is_mystery and current_level < LEVELS.size():
			continue

>>>>>>> Stashed changes
		var d := 0.0

		if player:
			d = player.global_position.distance_to(
				e.global_position
			)

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
<<<<<<< Updated upstream
	if InputMap.has_action("hint") and event.is_action_pressed("hint"):
		use_hint()


=======
	# ---- Pause ----
	if InputMap.has_action("pause"):
		if event.is_action_pressed("pause"):
			toggle_pause()
			return

	elif (
		event is InputEventKey
		and event.pressed
		and not event.echo
		and event.physical_keycode == KEY_P
	):
		toggle_pause()
		return

	if get_tree().paused:
		return

	# ---- Hint ----
	if InputMap.has_action("hint"):
		if event.is_action_pressed("hint"):
			use_hint()

	elif (
		event is InputEventKey
		and event.pressed
		and not event.echo
		and event.physical_keycode == KEY_H
	):
		use_hint()


# ================== Pause ==================

func set_paused(value: bool) -> void:
	if get_tree().paused == value:
		return

	get_tree().paused = value

	Input.mouse_mode = (
		Input.MOUSE_MODE_VISIBLE
		if value
		else Input.MOUSE_MODE_CAPTURED
	)

	paused_changed.emit(value)


func toggle_pause() -> void:
	if not is_running and not get_tree().paused:
		return

	set_paused(not get_tree().paused)


>>>>>>> Stashed changes
# ================== จบด่าน / ชนะ / แพ้ ==================

func _complete_level() -> void:
	is_running = false
	level_completed.emit(current_level)

	await get_tree().create_timer(
		NEXT_LEVEL_DELAY
	).timeout

	load_level(current_level + 1)


func _win() -> void:
	is_running = false
	game_won.emit()
<<<<<<< Updated upstream
	get_tree().change_scene_to_file.call_deferred(WIN_SCREEN)
=======

	if not _change_scene_safe(WIN_SCREEN):
		print(
			"GameManager: ชนะแล้ว! "
			+ "(ยังไม่มี win_screen.tscn) "
			+ "ไข่รวม = %d"
			% total_eggs_collected
		)
>>>>>>> Stashed changes


func _lose() -> void:
	is_running = false
	game_lost.emit()
<<<<<<< Updated upstream
	get_tree().change_scene_to_file.call_deferred(LOSE_SCREEN)
=======

	if not _change_scene_safe(LOSE_SCREEN):
		print(
			"GameManager: หมดเวลา! "
			+ "(ยังไม่มี lose_screen.tscn) "
			+ "เริ่มด่านใหม่ใน 2 วินาที"
		)

		await get_tree().create_timer(2.0).timeout
		retry_level()


# ================== Scene Safe ==================

func _change_scene_safe(path: String) -> bool:
	if not ResourceLoader.exists(path):
		push_warning(
			"GameManager: ไม่พบไฟล์ %s" % path
		)
		return false

	get_tree().change_scene_to_file.call_deferred(path)
	return true
>>>>>>> Stashed changes
