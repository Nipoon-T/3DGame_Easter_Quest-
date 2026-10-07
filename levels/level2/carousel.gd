extends Node3D
## ม้าหมุน — Rotor (AnimatableBody3D) หมุนช้า ๆ พา Player ที่ยืนอยู่บนพื้นหมุนตามไปด้วย
## ม้าขึ้นลงช้า ๆ ลูกของ Rotor ทั้งหมดหมุนไปด้วย (วางไข่เป็นลูกของ Rotor ได้)

@export var spin_speed: float = 0.35     ## rad/s
@export var bob_height: float = 0.12
@export var bob_speed: float = 1.6

var _t: float = 0.0
var _horses: Array[Node3D] = []
var _horse_base_y: Array[float] = []

@onready var _rotor: AnimatableBody3D = %Rotor


func _ready() -> void:
	for h in %Horses.get_children():
		var horse := h as Node3D
		_horses.append(horse)
		_horse_base_y.append(horse.position.y)


func _physics_process(delta: float) -> void:
	_t += delta
	_rotor.rotation.y = fmod(_rotor.rotation.y + spin_speed * delta, TAU)
	for i in _horses.size():
		_horses[i].position.y = _horse_base_y[i] + sin(_t * bob_speed + i * PI) * bob_height
