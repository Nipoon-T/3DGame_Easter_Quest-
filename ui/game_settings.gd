class_name GameSettings
extends RefCounted
## ตัวช่วยกลางของหน้า Settings (static ทั้งหมด ไม่ใช้ Autoload)
## - สร้าง bus "Music" และ "SFX" ด้วยโค้ด ส่งเข้า Master
## - จำค่าระหว่างเล่น (ไม่บันทึกไฟล์) / Fullscreen / ตัวเลข FPS มุมซ้ายล่าง
## ensure_setup() เรียกซ้ำได้ปลอดภัย: title_screen, main_menu, hud, level_map, pause_menu, settings_panel

const MASTER := "Master"
const MUSIC := "Music"
const SFX := "SFX"

const DEFAULT_VOLUME := 1.0
const FONT_PATH := "res://ui/fonts/Fredoka-SemiBold.ttf"
const FPS_FONT_SIZE := 30
const FPS_MARGIN := 28.0
const FPS_UPDATE_TIME := 0.25

static var _ready_done := false
static var _fps_shown := false
static var _fps_layer: CanvasLayer
static var _fps_label: Label
static var _windowed_size := Vector2i.ZERO
static var _windowed_pos := Vector2i.ZERO


static func ensure_setup() -> void:
	if _ready_done:
		return
	_ready_done = true
	for bus_name: String in [MUSIC, SFX]:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			var idx := AudioServer.bus_count - 1
			AudioServer.set_bus_name(idx, bus_name)
			AudioServer.set_bus_send(idx, MASTER)
	_build_fps_overlay()


# ---------------- เสียง ----------------

static func get_volume(bus_name: String) -> float:
	ensure_setup()
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1 or AudioServer.is_bus_mute(idx):
		return 0.0
	return db_to_linear(AudioServer.get_bus_volume_db(idx))


static func set_volume(bus_name: String, value: float) -> void:
	ensure_setup()
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	AudioServer.set_bus_volume_db(idx, linear_to_db(value))
	AudioServer.set_bus_mute(idx, value <= 0.0)


# ---------------- Fullscreen ----------------

static func is_fullscreen() -> bool:
	var mode := DisplayServer.window_get_mode()
	return mode == DisplayServer.WINDOW_MODE_FULLSCREEN \
		or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN


static func set_fullscreen(on: bool) -> void:
	if on == is_fullscreen():
		return
	var web := OS.has_feature("web")
	if on:
		if not web:
			_windowed_size = DisplayServer.window_get_size()
			_windowed_pos = DisplayServer.window_get_position()
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		# คืนขนาด/ตำแหน่งเดิมก่อนเข้าเต็มจอ (ไม่งั้นบางเครื่องหน้าต่างเพี้ยน)
		if not web and _windowed_size != Vector2i.ZERO:
			DisplayServer.window_set_size(_windowed_size)
			DisplayServer.window_set_position(_windowed_pos)


# ---------------- FPS ----------------

static func is_fps_shown() -> bool:
	return _fps_shown


static func set_fps_shown(on: bool) -> void:
	ensure_setup()
	_fps_shown = on
	if is_instance_valid(_fps_layer):
		_fps_layer.visible = on
		_update_fps()


# ---------------- คืนค่าเริ่มต้น ----------------

static func reset_all() -> void:
	for bus_name: String in [MASTER, MUSIC, SFX]:
		set_volume(bus_name, DEFAULT_VOLUME)
	set_fullscreen(false)
	set_fps_shown(false)


# ---------------- ภายใน ----------------

static func _build_fps_overlay() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	var font := load(FONT_PATH) as Font
	var brown := Color("7a4a22")

	_fps_layer = CanvasLayer.new()
	_fps_layer.name = "GameSettingsFps"
	_fps_layer.layer = 128
	_fps_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	_fps_layer.visible = _fps_shown

	var box := StyleBoxFlat.new()
	box.bg_color = Color("fff6e0")
	box.set_corner_radius_all(18)
	box.set_border_width_all(4)
	box.border_color = brown
	box.content_margin_left = 18
	box.content_margin_right = 18
	box.content_margin_top = 4
	box.content_margin_bottom = 4

	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", box)
	panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	panel.offset_left = FPS_MARGIN
	panel.offset_bottom = -FPS_MARGIN
	_fps_layer.add_child(panel)

	_fps_label = Label.new()
	_fps_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fps_label.add_theme_color_override("font_color", brown)
	_fps_label.add_theme_font_size_override("font_size", FPS_FONT_SIZE)
	if font:
		_fps_label.add_theme_font_override("font", font)
	_fps_label.text = "FPS 00"
	panel.add_child(_fps_label)

	var timer := Timer.new()
	timer.wait_time = FPS_UPDATE_TIME
	timer.autostart = true
	timer.timeout.connect(_update_fps)
	_fps_layer.add_child(timer)

	# ฝากไว้ใต้ root เพื่อให้อยู่ข้ามการเปลี่ยน scene (เลี่ยง "parent busy" ด้วย deferred)
	tree.root.add_child.call_deferred(_fps_layer)


static func _update_fps() -> void:
	if _fps_shown and is_instance_valid(_fps_label):
		_fps_label.text = "FPS %d" % Engine.get_frames_per_second()
