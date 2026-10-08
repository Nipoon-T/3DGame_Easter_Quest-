@tool
extends Node3D
## PartMultiMesh — วางโมเดลชิ้นเดียวจาก .glb ซ้ำหลายจุดด้วย MultiMesh (1 draw call)
## ใช้กับดอกไม้ หญ้า และหินแนวกำแพง (ไม่มี collision)
## ตำแหน่งทั้งหมดเก็บใน `positions` = MultiMesh ที่มีแต่ transform (ไม่มี mesh)
## สคริปต์จะสร้าง MultiMeshInstance3D ลูก (ไม่ถูกบันทึกลงฉาก) แล้วใส่ mesh จาก glb ให้

const GlbPart := preload("res://find_Easter_eggs_in_garden/scripts/glb_part.gd")

@export var source: PackedScene
@export var part_name := ""
@export var positions: MultiMesh
@export var cast_shadow := false

var _mmi: MultiMeshInstance3D


func _ready() -> void:
	if source == null or positions == null or part_name == "":
		return
	var mesh := GlbPart.get_part_mesh(source, part_name)
	if mesh == null:
		push_warning("PartMultiMesh: ไม่พบ '%s'" % part_name)
		return
	var mm := positions.duplicate() as MultiMesh
	mm.mesh = mesh
	_mmi = MultiMeshInstance3D.new()
	_mmi.multimesh = mm
	if not cast_shadow:
		_mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_mmi)
