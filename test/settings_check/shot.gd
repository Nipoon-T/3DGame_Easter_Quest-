extends Node
## ถ่ายภาพแผง Settings (ต้องมีหน้าต่าง): godot --path . res://test/settings_check/shot.tscn -- <menu|pause> <out.png> <กว้าง> <สูง> [fps]
func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	var size := Vector2i(int(a[2]), int(a[3]))
	var window := get_window()
	window.size = size
	await get_tree().process_frame
	GameSettings.ensure_setup()
	var scene_path := "res://ui/main_menu.tscn" if a[0] == "menu" else "res://ui/pause_menu.tscn"
	var scene: Node = load(scene_path).instantiate()
	get_tree().root.add_child(scene)
	window.size = size
	for i in 40: await get_tree().process_frame
	if a[0] == "pause":
		GameManager.set_paused(true)
		for i in 30: await get_tree().process_frame
	GameSettings.set_volume("Master", 0.6)
	GameSettings.set_fps_shown("fps" in a)
	scene.settings_panel.open()
	for i in 40: await get_tree().process_frame
	if "fps" in a: scene.settings_panel.fps_switch.set_on(true)
	await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(a[1])
	print("saved ", a[1], " ", get_viewport().get_visible_rect().size)
	get_tree().quit()
