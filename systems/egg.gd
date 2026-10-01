extends Area3D
class_name Egg

## =========================================================
## Egg
## =========================================================
## ไข่อีสเตอร์ที่เก็บได้
## ผู้เล่นต้องเล็งไปที่ไข่แล้วกด E
##
## Scene:
## Egg (Area3D)
## ├── Mesh (MeshInstance3D)
## ├── CollisionShape3D
## └── HintLight (OmniLight3D)
## =========================================================


# =========================================================
# Settings
# =========================================================

@export var is_mystery: bool = false
@export var spin_speed: float = 1.5
@export var egg_color: Color = Color(1.0, 0.75, 0.85)


# =========================================================
# Variables
# =========================================================

var collected: bool = false

var _base_y: float = 0.0
var _hint_tween: Tween


# =========================================================
# Nodes
# =========================================================

@onready var mesh: MeshInstance3D = $Mesh
@onready var hint_light: OmniLight3D = $HintLight


# =========================================================
# Ready
# =========================================================

func _ready() -> void:

	# ให้ GameManager หาไข่จาก group "egg"
	add_to_group("egg")

	# จำตำแหน่ง Y เดิม
	if is_instance_valid(mesh):

		_base_y = mesh.position.y

		# ---------------------------------------------------
		# เปลี่ยนสีไข่โดยสร้าง Material แยก
		# ---------------------------------------------------

		var mat: Material = mesh.get_active_material(0)

		if mat != null:

			var new_mat: Material = mat.duplicate()

			if new_mat is StandardMaterial3D:

				var standard_mat := new_mat as StandardMaterial3D

				standard_mat.albedo_color = egg_color

				mesh.set_surface_override_material(
					0,
					standard_mat
				)


# =========================================================
# Animation
# =========================================================

func _process(delta: float) -> void:

	if collected:
		return

	if is_instance_valid(mesh):
		mesh.rotate_y(spin_speed * delta)


# =========================================================
# Pickup
# =========================================================
## Player จะเรียกฟังก์ชันนี้เมื่อกด E
##
## Player.gd:
##     egg.try_collect(self)
##
## ไม่ตรวจระยะซ้ำตรงนี้
## เพราะ Player Raycast ตรวจระยะจากกล้องอยู่แล้ว
# =========================================================

func try_collect(player: Node) -> void:

	# -------------------------------------------------------
	# เก็บไปแล้ว
	# -------------------------------------------------------

	if collected:
		return


	# -------------------------------------------------------
	# ตรวจว่าเป็น Player จริง
	# -------------------------------------------------------

	if not player.is_in_group("player"):
		print("Egg: สิ่งที่เรียก try_collect ไม่ใช่ Player")
		return


	# -------------------------------------------------------
	# ผ่านแล้ว -> เก็บทันที
	# -------------------------------------------------------

	print("Egg: รับคำสั่งเก็บไข่ -> ", name)

	collect()


# =========================================================
# Collect
# =========================================================

func collect() -> void:

	if collected:
		return

	collected = true

	print("Egg: COLLECTED -> ", name)


	# -------------------------------------------------------
	# ปิด Collision
	# -------------------------------------------------------

	set_deferred("monitoring", false)
	set_deferred("monitorable", false)


	# -------------------------------------------------------
	# ปิด Hint Light
	# -------------------------------------------------------

	if is_instance_valid(hint_light):
		hint_light.visible = false


	# -------------------------------------------------------
	# แจ้ง GameManager
	# -------------------------------------------------------

	if is_instance_valid(GameManager):

		GameManager.collect_egg(self)

	else:

		push_error("Egg: ไม่พบ GameManager Autoload")


	# -------------------------------------------------------
	# Animation เก็บไข่
	# -------------------------------------------------------

	if not is_instance_valid(mesh):

		queue_free()
		return


	var tw := create_tween()


	# ลอยขึ้น

	tw.tween_property(
		mesh,
		"position:y",
		_base_y + 0.8,
		0.2
	)


	# ย่อจนหาย

	tw.tween_property(
		mesh,
		"scale",
		Vector3.ZERO,
		0.2
	)


	# ลบ Egg

	tw.tween_callback(queue_free)


# =========================================================
# Hint
# =========================================================

func show_hint(duration: float = 4.0) -> void:

	if collected:
		return

	if not is_instance_valid(mesh):
		return


	# -------------------------------------------------------
	# หยุด Tween เก่า
	# -------------------------------------------------------

	if _hint_tween != null:
		_hint_tween.kill()


	# -------------------------------------------------------
	# เปิดไฟ Hint
	# -------------------------------------------------------

	if is_instance_valid(hint_light):
		hint_light.visible = true


	# -------------------------------------------------------
	# จำนวนรอบ
	# -------------------------------------------------------

	var loops: int = max(
		1,
		int(duration / 0.5)
	)


	_hint_tween = create_tween().set_loops(loops)


	# ขึ้น

	_hint_tween.tween_property(
		mesh,
		"position:y",
		_base_y + 0.4,
		0.25
	)


	# ลง

	_hint_tween.tween_property(
		mesh,
		"position:y",
		_base_y,
		0.25
	)


	_hint_tween.finished.connect(
		_on_hint_finished
	)


# =========================================================
# Hint Finished
# =========================================================

func _on_hint_finished() -> void:

	if collected:
		return

	if is_instance_valid(hint_light):
		hint_light.visible = false
