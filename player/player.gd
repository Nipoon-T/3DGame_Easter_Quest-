extends CharacterBody3D
class_name Player

## First Person Player
## เดิน / วิ่ง / กระโดด / Mouse Look
## มองลงแล้วเห็นตัวละคร
## กด E เพื่อหยิบของ
## กด ESC เพื่อปล่อยเมาส์


# =========================================================
# Movement
# =========================================================

@export_group("Movement")
@export var walk_speed: float = 5.0
@export var sprint_speed: float = 8.0
@export var jump_velocity: float = 6.0
@export var ground_accel: float = 40.0
@export var air_accel: float = 12.0


# =========================================================
# First Person Camera
# =========================================================

@export_group("First Person Camera")
@export var mouse_sensitivity: float = 0.0025

@export var min_pitch: float = -80.0
@export var max_pitch: float = 80.0
@export var camera_height: float = 1.20


# =========================================================
# Interaction
# =========================================================

@export_group("Interaction")
@export var interact_distance: float = 2.5


# =========================================================
# Constants
# =========================================================

const COYOTE_TIME: float = 0.12
const JUMP_BUFFER: float = 0.12
const FALL_LIMIT: float = -30.0


# =========================================================
# Variables
# =========================================================

var _gravity: float = ProjectSettings.get_setting(
	"physics/3d/default_gravity"
)

var _coyote: float = 0.0
var _jump_buffer: float = 0.0
var _spawn_position: Vector3 = Vector3.ZERO

var _yaw: float = 0.0
var _pitch: float = -0.15


# =========================================================
# Nodes
# =========================================================

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D
@onready var model: Node3D = $Character_Animated


# =========================================================
# Ready
# =========================================================

func _ready() -> void:

	add_to_group("player")

	_spawn_position = global_position

	camera.position = Vector3(0.0, 1.35, 0.05)
	model.visible = true

	camera.current = true

	rotation.y = _yaw

	GameManager.game_won.connect(release_mouse)
	GameManager.game_lost.connect(release_mouse)

	capture_mouse()


# =========================================================
# Mouse Look / Input
# =========================================================

func _unhandled_input(event: InputEvent) -> void:

	if event is InputEventMouseMotion:

		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:

			_yaw -= event.relative.x * mouse_sensitivity

			_pitch += event.relative.y * mouse_sensitivity

			_pitch = clampf(
				_pitch,
				deg_to_rad(min_pitch),
				deg_to_rad(max_pitch)
			)

			camera_pivot.rotation.x = _pitch

			rotation.y = _yaw

		return


	if event is InputEventKey:

		if event.pressed and not event.echo:

			if event.keycode == KEY_ESCAPE:

				if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
					release_mouse()
				else:
					capture_mouse()

				return


	# =====================================================
	# E = หยิบของ
	# =====================================================

	if event.is_action_pressed("interact"):

		try_interact()

		return


	if event is InputEventMouseButton:

		if event.pressed:

			if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:

				if not get_tree().paused:
					capture_mouse()


# =========================================================
# Movement
# =========================================================

func _physics_process(delta: float) -> void:

	# -------------------------------------------------------
	# Gravity
	# -------------------------------------------------------

	if is_on_floor():

		_coyote = COYOTE_TIME

	else:

		_coyote -= delta
		velocity.y -= _gravity * delta


	# -------------------------------------------------------
	# Jump Buffer
	# -------------------------------------------------------

	if Input.is_action_just_pressed("jump"):

		_jump_buffer = JUMP_BUFFER

	else:

		_jump_buffer -= delta


	if _jump_buffer > 0.0 and _coyote > 0.0:

		velocity.y = jump_velocity

		_jump_buffer = 0.0
		_coyote = 0.0


	# -------------------------------------------------------
	# รับ Input WASD
	# -------------------------------------------------------

	var input_x: float = 0.0
	var input_y: float = 0.0

	if Input.is_action_pressed("move_left"):
		input_x += 1.0

	if Input.is_action_pressed("move_right"):
		input_x -= 1.0

	if Input.is_action_pressed("move_forward"):
		input_y -= 1.0

	if Input.is_action_pressed("move_back"):
		input_y += 1.0


	var input_dir: Vector2 = Vector2(
		input_x,
		input_y
	)


	if input_dir.length() > 1.0:
		input_dir = input_dir.normalized()


	# -------------------------------------------------------
	# ทิศทางเดินตามตัวละคร
	# -------------------------------------------------------

	var forward: Vector3 = -global_transform.basis.z
	var right: Vector3 = global_transform.basis.x

	var dir: Vector3 = (
		right * input_dir.x +
		forward * input_dir.y
	)

	dir.y = 0.0


	if dir.length() > 1.0:
		dir = dir.normalized()


	# -------------------------------------------------------
	# Speed
	# -------------------------------------------------------

	var speed: float = walk_speed

	if Input.is_action_pressed("sprint"):
		speed = sprint_speed


	# -------------------------------------------------------
	# Acceleration
	# -------------------------------------------------------

	var accel: float = ground_accel

	if not is_on_floor():
		accel = air_accel


	var target_velocity: Vector3 = dir * speed


	velocity.x = move_toward(
		velocity.x,
		target_velocity.x,
		accel * delta
	)

	velocity.z = move_toward(
		velocity.z,
		target_velocity.z,
		accel * delta
	)


	# -------------------------------------------------------
	# เคลื่อนที่
	# -------------------------------------------------------

	move_and_slide()


	# -------------------------------------------------------
	# ตกจากฉาก
	# -------------------------------------------------------

	if global_position.y < FALL_LIMIT:

		global_position = _spawn_position
		velocity = Vector3.ZERO


# =========================================================
# Interaction / Pickup
# =========================================================

func try_interact() -> void:

	# ต้องจับเมาส์อยู่
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return


	# -------------------------------------------------------
	# จุดเริ่ม Ray = ตรงกลางกล้อง
	# -------------------------------------------------------

	var from: Vector3 = camera.global_position


	# -------------------------------------------------------
	# จุดปลาย Ray = ด้านหน้ากล้อง
	# -------------------------------------------------------

	var to: Vector3 = (
		from
		- camera.global_transform.basis.z
		* interact_distance
	)


	# -------------------------------------------------------
	# สร้าง Ray
	# -------------------------------------------------------

	var query := PhysicsRayQueryParameters3D.create(
		from,
		to
	)


	# -------------------------------------------------------
	# ไม่ให้ Ray ชน Player
	# -------------------------------------------------------

	query.exclude = [self]

	# ตรวจ Area3D
	query.collide_with_areas = true

	# ตรวจ PhysicsBody3D
	query.collide_with_bodies = true


	# -------------------------------------------------------
	# ยิง Ray
	# -------------------------------------------------------

	var result: Dictionary = (
		get_world_3d()
		.direct_space_state
		.intersect_ray(query)
	)


	# -------------------------------------------------------
	# ไม่โดนอะไร
	# -------------------------------------------------------

	if result.is_empty():
		return


	# -------------------------------------------------------
	# ตรวจสิ่งที่โดน
	# -------------------------------------------------------

	var hit: Object = result.get("collider")


	# -------------------------------------------------------
	# ถ้าโดน Egg
	# -------------------------------------------------------

	if hit is Egg:

		var egg := hit as Egg


		# ป้องกันเก็บซ้ำ
		if egg.collected:
			return


		# ให้ Egg ตรวจระยะและเก็บตัวเอง
		egg.try_collect(self)


# =========================================================
# Mouse
# =========================================================

func capture_mouse() -> void:

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func release_mouse() -> void:

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _exit_tree() -> void:

	release_mouse()
