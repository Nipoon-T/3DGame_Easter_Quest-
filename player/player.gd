extends CharacterBody3D
class_name Player

## =========================================================
## FIRST PERSON PLAYER
## =========================================================
## กล้องอยู่ที่ระดับตา
## มองขึ้น/ลงแบบมนุษย์
## หันซ้าย/ขวาได้ 360° แบบ FPS
## ก้มแล้วเห็นตัวละคร
## E = หยิบของ
## ESC = ปล่อยเมาส์
## =========================================================


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
# Crouch
# =========================================================

@export_group("Crouch")

@export var crouch_height: float = 1.0
@export var normal_height: float = 2.0


# =========================================================
# Human First Person Camera
# =========================================================

@export_group("Human First Person Camera")

@export var eye_position: Vector3 = Vector3(
	0.0,
	1.029,
	0.39
)


# ---------------------------------------------------------
# ก้ม / เงย
# ---------------------------------------------------------

@export_range(30.0, 80.0, 1.0)
var look_up_limit: float = 60.0

@export_range(30.0, 90.0, 1.0)
var look_down_limit: float = 70.0


# ---------------------------------------------------------
# Mouse
# ---------------------------------------------------------

@export var mouse_sensitivity: float = 0.0025


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


# =========================================================
# มุมมอง
# =========================================================

var _yaw: float = 0.0
var _pitch: float = 0.0


# =========================================================
# Nodes
# =========================================================

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D
@onready var model: Node3D = $Character_Animated
@onready var collision_shape: CollisionShape3D = $CollisionShape3D


# =========================================================
# Ready
# =========================================================

func _ready() -> void:

	add_to_group("player")

	_spawn_position = global_position

	# Duplicate Shape ก่อนแก้ขนาด
	# เพื่อไม่แก้ Resource ต้นฉบับที่อาจถูกแชร์
	collision_shape.shape = collision_shape.shape.duplicate()


	# =====================================================
	# CAMERA POSITION
	# =====================================================

	camera_pivot.position = Vector3.ZERO

	camera.position = eye_position


	# =====================================================
	# CAMERA ROTATION
	# =====================================================

	camera.rotation = Vector3(
		0.0,
		PI,
		0.0
	)

	camera.current = true


	# =====================================================
	# INITIAL LOOK
	# =====================================================

	_yaw = rotation.y
	_pitch = 0.0

	camera_pivot.rotation = Vector3.ZERO

	model.visible = true


	# =====================================================
	# GAME MANAGER
	# =====================================================

	GameManager.game_won.connect(release_mouse)
	GameManager.game_lost.connect(release_mouse)

	capture_mouse()


# =========================================================
# Mouse Look
# =========================================================

func _unhandled_input(event: InputEvent) -> void:

	# =====================================================
	# MOUSE LOOK
	# =====================================================

	if event is InputEventMouseMotion:

		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:

			# -------------------------------------------------
			# ซ้าย / ขวา
			# -------------------------------------------------

			_yaw -= (
				event.relative.x
				* mouse_sensitivity
			)

			rotation.y = _yaw


			# -------------------------------------------------
			# ขึ้น / ลง
			# -------------------------------------------------

			_pitch -= (
				event.relative.y
				* mouse_sensitivity
			)

			_pitch = clampf(
				_pitch,
				deg_to_rad(-look_up_limit),
				deg_to_rad(look_down_limit)
			)


			# -------------------------------------------------
			# ก้ม / เงยจาก "ดวงตา"
			# -------------------------------------------------

			camera.rotation.x = _pitch
			camera.rotation.y = PI
			camera.rotation.z = 0.0

		return


	# =====================================================
	# ESC
	# =====================================================

	if event is InputEventKey:

		if event.pressed and not event.echo:

			if event.keycode == KEY_ESCAPE:

				if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
					release_mouse()
				else:
					capture_mouse()

				return


	# =====================================================
	# E = INTERACT
	# =====================================================

	if event.is_action_pressed("interact"):

		try_interact()

		return


	# =====================================================
	# CLICK = CAPTURE MOUSE
	# =====================================================

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
	# Crouch - CTRL
	# -------------------------------------------------------
	# ห้ามใช้ CollisionShape3D.scale
	# เพราะ Jolt ไม่รองรับ non-uniform scaling
	# -------------------------------------------------------

	var shape := collision_shape.shape

	if shape is CapsuleShape3D:

		var capsule := shape as CapsuleShape3D

		if Input.is_action_pressed("crouch"):
			capsule.height = crouch_height
		else:
			capsule.height = normal_height

	elif shape is BoxShape3D:

		var box := shape as BoxShape3D

		if Input.is_action_pressed("crouch"):
			box.size.y = crouch_height
		else:
			box.size.y = normal_height


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
	# WASD
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


	var input_dir := Vector2(
		input_x,
		input_y
	)

	if input_dir.length() > 1.0:
		input_dir = input_dir.normalized()


	# -------------------------------------------------------
	# Direction
	# -------------------------------------------------------

	var forward := -global_transform.basis.z
	var right := global_transform.basis.x

	var dir := (
		right * input_dir.x
		+ forward * input_dir.y
	)

	dir.y = 0.0

	if dir.length() > 1.0:
		dir = dir.normalized()


	# -------------------------------------------------------
	# Speed
	# -------------------------------------------------------

	var speed := walk_speed

	if Input.is_action_pressed("sprint"):
		speed = sprint_speed


	# -------------------------------------------------------
	# Acceleration
	# -------------------------------------------------------

	var accel := ground_accel

	if not is_on_floor():
		accel = air_accel


	var target_velocity := dir * speed

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
	# Move
	# -------------------------------------------------------

	move_and_slide()


	# -------------------------------------------------------
	# Fall Reset
	# -------------------------------------------------------

	if global_position.y < FALL_LIMIT:

		global_position = _spawn_position
		velocity = Vector3.ZERO


# =========================================================
# Interaction / Pickup
# =========================================================

func try_interact() -> void:

	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return


	# -------------------------------------------------------
	# Ray เริ่มจาก "ตา"
	# -------------------------------------------------------

	var from := camera.global_position

	var to := (
		from
		- camera.global_transform.basis.z
		* interact_distance
	)


	# -------------------------------------------------------
	# Ray Query
	# -------------------------------------------------------

	var query := PhysicsRayQueryParameters3D.create(
		from,
		to
	)

	query.exclude = [self]
	query.collide_with_areas = true
	query.collide_with_bodies = true


	var result := (
		get_world_3d()
		.direct_space_state
		.intersect_ray(query)
	)


	if result.is_empty():
		return


	var hit: Object = result.get("collider")


	# -------------------------------------------------------
	# Egg โดยตรง
	# -------------------------------------------------------

	if hit is Egg:

		var egg := hit as Egg

		if egg.collected:
			return

		egg.try_collect(self)

		return


	# -------------------------------------------------------
	# CollisionShape3D ของ Egg
	# -------------------------------------------------------

	if hit is Node:

		var parent := (
			hit as Node
		).get_parent()

		if parent is Egg:

			var egg := parent as Egg

			if egg.collected:
				return

			egg.try_collect(self)


# =========================================================
# Mouse
# =========================================================

func capture_mouse() -> void:

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func release_mouse() -> void:

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


# =========================================================
# Exit
# =========================================================

func _exit_tree() -> void:

	release_mouse()
