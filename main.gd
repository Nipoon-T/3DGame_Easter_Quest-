extends Node
## จุดเริ่มเกม (run/main_scene) — เจ้าของ: คนที่ 1
## ถ้ามีเมนูหลักของคนที่ 3 (ui/main_menu.tscn) จะไปหน้านั้นก่อน
## ถ้ายังไม่มี จะเริ่มด่าน 1 เลยเพื่อให้ทดสอบได้

const MAIN_MENU := "res://ui/main_menu.tscn"


func _ready() -> void:
	if ResourceLoader.exists(MAIN_MENU):
		get_tree().change_scene_to_file.call_deferred(MAIN_MENU)
	else:
		GameManager.start_new_game()
