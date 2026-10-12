extends Node
## ทดสอบ Settings: godot --headless --path . res://test/settings_check/check.tscn --quit-after 600
var _fails := 0

func _ready() -> void:
	await get_tree().process_frame
	reparent(get_tree().root)
	get_tree().current_scene = null
	GameSettings.ensure_setup()
	GameSettings.ensure_setup()
	_check("bus Music/SFX มีและไม่ซ้ำ", AudioServer.get_bus_index("Music") > 0 and AudioServer.get_bus_index("SFX") > 0 and AudioServer.bus_count == 3)
	_check("ส่งเข้า Master", AudioServer.get_bus_send(AudioServer.get_bus_index("SFX")) == &"Master")
	for path in ["res://ui/title_screen.tscn", "res://ui/main_menu.tscn", "res://ui/level_map.tscn", "res://ui/settings_panel.tscn", "res://ui/pause_menu.tscn", "res://ui/hud.tscn"]:
		var s: Node = load(path).instantiate()
		get_tree().root.add_child(s)
		await get_tree().process_frame
		s.queue_free()
		await get_tree().process_frame
	var panel: Control = load("res://ui/settings_panel.tscn").instantiate()
	get_tree().root.add_child(panel)
	await get_tree().process_frame
	panel.music_slider.value = 0.4
	panel.sfx_slider.value = 0.25
	panel.fps_switch.button_pressed = true
	_check("music 0.4", is_equal_approx(GameSettings.get_volume("Music"), 0.4))
	_check("fps overlay เปิด", GameSettings.is_fps_shown() and get_tree().root.has_node("GameSettingsFps") and get_tree().root.get_node("GameSettingsFps").visible)
	panel.queue_free()
	await get_tree().process_frame
	var p2: Control = load("res://ui/settings_panel.tscn").instantiate()
	get_tree().root.add_child(p2)
	await get_tree().process_frame
	p2.open()
	_check("เปิดใหม่ค่ายังอยู่", is_equal_approx(p2.music_slider.value, 0.4) and is_equal_approx(p2.sfx_slider.value, 0.25) and p2.fps_switch.button_pressed and p2.music_percent.text == "40%")
	p2.reset_button.pressed.emit()
	_check("RESET", is_equal_approx(GameSettings.get_volume("Music"), 1.0) and is_equal_approx(GameSettings.get_volume("SFX"), 1.0) and not GameSettings.is_fps_shown() and not p2.fps_switch.button_pressed and p2.sfx_percent.text == "100%")
	print("FAILS: %d" % _fails)
	get_tree().quit(_fails)

func _check(n: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + n)
	if not ok: _fails += 1
