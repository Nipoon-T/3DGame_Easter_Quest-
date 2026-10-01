extends Area3D
class_name Egg
## ไข่อีสเตอร์ที่เก็บได้ — ใช้ผ่าน systems/egg.tscn
## เจ้าของด่านลาก egg.tscn ไปวางในด่านได้เลย ไม่ต้องแก้ไฟล์นี้
##
## เงื่อนไข: node ของผู้เล่นต้องอยู่ใน group "player"
##           (ใน player.gd ใส่ add_to_group("player") ใน _ready)

@export var is_mystery := false        ## ติ๊กเฉพาะไข่ลับในพื้นที่สุดท้าย เก็บแล้วชนะเกม
@export var spin_speed := 1.5
@export var egg_color := Color(1.0, 0.75, 0.85)

var collected := false

@onready var mesh: MeshInstance3D = $Mesh
@onready var hint_light: OmniLight3D = $HintLight

var _base_y := 0.0
var _hint_tween: Tween


func _ready() -> void:
	add_to_group("egg")
	body_entered.connect(_on_body_entered)
	_base_y = mesh.position.y
	# ให้แต่ละใบมีสีของตัวเองได้โดยไม่กระทบใบอื่น
	var mat := mesh.get_active_material(0)
	if mat:
		mat = mat.duplicate()
		mat.albedo_color = egg_color
		mesh.set_surface_override_material(0, mat)


func _process(delta: float) -> void:
	mesh.rotate_y(spin_speed * delta)


func _on_body_entered(body: Node) -> void:
	if collected or not body.is_in_group("player"):
		return
	collected = true
	set_deferred("monitoring", false)
	hint_light.visible = false
	GameManager.collect_egg(self)
	# TODO (คนที่ 3): เล่นเสียงเก็บไข่ตรงนี้ เช่น $CollectSound.play()
	var tw := create_tween()
	tw.tween_property(mesh, "position:y", _base_y + 0.8, 0.2)
	tw.tween_property(mesh, "scale", Vector3.ZERO, 0.2)
	tw.tween_callback(queue_free)


## GameManager เรียกเมื่อผู้เล่นกด Hint
func show_hint(duration := 4.0) -> void:
	if collected:
		return
	if _hint_tween:
		_hint_tween.kill()
	hint_light.visible = true
	_hint_tween = create_tween().set_loops(int(duration / 0.5))
	_hint_tween.tween_property(mesh, "position:y", _base_y + 0.4, 0.25)
	_hint_tween.tween_property(mesh, "position:y", _base_y, 0.25)
	_hint_tween.finished.connect(func(): hint_light.visible = false)
