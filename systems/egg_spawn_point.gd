@tool
extends Marker3D
class_name EggSpawnPoint
## =========================================================
## จุดที่ "อาจ" มีไข่เกิด — วางไว้เป็นลูกของ EggSpawner
## ตอนเริ่มด่าน EggSpawner จะสุ่มเลือกบางจุดมาวางไข่จริง
## (เจ้าของไฟล์: คนที่ 2)
##
## วางให้ "ฐาน" ของไข่แตะพื้นผิว (แกน Y ของ Marker = ก้นไข่)
## ใน editor จะเห็นไข่โปร่งแสงให้กะตำแหน่งได้ง่าย ตอนเล่นจริงจะหายไป
## =========================================================

@export_range(0.2, 2.0, 0.05) var egg_scale := 0.6:
	set(v):
		egg_scale = v
		_update_preview()
## ถ้าเลือกสีเอง ให้ติ๊ก use_custom_color (ไม่ติ๊ก = สุ่มสีพาสเทล)
@export var use_custom_color := false
@export var egg_color := Color(1.0, 0.75, 0.85)
## โอกาสถูกเลือก (1 = ปกติ, 2 = มีโอกาสมากเป็นสองเท่า, 0 = ไม่เคยถูกเลือก)
@export_range(0.0, 5.0, 0.1) var weight := 1.0

var _preview: MeshInstance3D


func _ready() -> void:
	gizmo_extents = 0.3
	if Engine.is_editor_hint():
		_update_preview()


func _update_preview() -> void:
	if not Engine.is_editor_hint() or not is_inside_tree():
		return
	if _preview == null:
		_preview = MeshInstance3D.new()
		var m := SphereMesh.new()
		m.radius = 0.25
		m.height = 0.5
		var mat := StandardMaterial3D.new()
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color = Color(1, 0.6, 0.8, 0.45)
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.material = mat
		_preview.mesh = m
		add_child(_preview)   # ไม่ตั้ง owner -> ไม่ถูกเซฟลงไฟล์ scene
	_preview.transform = Transform3D(Basis().scaled(Vector3(egg_scale, egg_scale * 1.35, egg_scale)), Vector3(0, 0.35 * egg_scale, 0))
