@tool
extends Node3D
## GlbPart — แสดงโมเดล "ชิ้นเดียว" จากไฟล์ .glb ที่มีหลายโมเดลรวมกัน
## (เช่น Bushes.glb มี Plant_1 / Bush / Bush_Flowers วางเรียงกันห่าง ๆ)
##
## - ไม่แก้ไฟล์ .glb และไม่ต้องเปิด editable children
## - part_name = ชื่อ node ในไฟล์ glb
## - part_name = "*" รวมทุก mesh ในไฟล์เป็น mesh เดียว (ลด draw call เช่น Walk in the Woods ที่มี 119 ชิ้น)
## - MeshInstance3D ที่สร้างไม่มี owner จึงไม่ถูกบันทึกลงไฟล์ฉาก

@export var source: PackedScene:
	set(v):
		source = v
		_rebuild()
@export var part_name := "":
	set(v):
		part_name = v
		_rebuild()
@export var cast_shadow := true
## สร้าง collision แบบ trimesh ตามรูปทรงจริง (ใช้กับ prop ที่เดินเข้าไปได้ เช่น Walk in the Woods)
@export var trimesh_collision := false

static var _cache := {}
static var _shape_cache := {}
var _mi: MeshInstance3D
var _body: StaticBody3D


func _ready() -> void:
	_rebuild()


func _rebuild() -> void:
	if not is_inside_tree():
		return
	if _mi:
		_mi.queue_free()
		_mi = null
	if _body:
		_body.queue_free()
		_body = null
	if source == null or part_name == "":
		return
	var mesh := get_part_mesh(source, part_name)
	if mesh == null:
		push_warning("GlbPart: ไม่พบ '%s' ใน %s" % [part_name, source.resource_path])
		return
	_mi = MeshInstance3D.new()
	_mi.mesh = mesh
	if not cast_shadow:
		_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_mi)
	if trimesh_collision and not Engine.is_editor_hint():
		var key := source.resource_path + "::" + part_name
		if not _shape_cache.has(key):
			_shape_cache[key] = mesh.create_trimesh_shape()
		_body = StaticBody3D.new()
		var cs := CollisionShape3D.new()
		cs.shape = _shape_cache[key]
		_body.add_child(cs)
		add_child(_body)


static func get_part_mesh(src: PackedScene, part: String) -> Mesh:
	var key := src.resource_path + "::" + part
	if _cache.has(key):
		return _cache[key]
	var root := src.instantiate()
	var result: Mesh = null
	if part == "*":
		result = _merge(root, root.find_children("*", "MeshInstance3D", true, false), false)
	else:
		var n := root.find_child(part, true, false)
		if n is MeshInstance3D:
			result = _merge(root, [n], true)
	root.free()
	_cache[key] = result
	return result


## รวม mesh หลายชิ้นเป็นชิ้นเดียว (แยก surface ตาม material)
## recenter = ตัดตำแหน่ง (translation) ทิ้ง เหลือแค่การหมุน/ย่อขยายของ node ใน glb
static func _merge(root: Node, nodes: Array, recenter: bool) -> Mesh:
	var tools := {}
	for n in nodes:
		var mi := n as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		var xf := mi.transform
		var p := mi.get_parent()
		while p != null and p != root:
			if p is Node3D:
				xf = (p as Node3D).transform * xf
			p = p.get_parent()
		if recenter:
			xf.origin = Vector3.ZERO
		for s in mi.mesh.get_surface_count():
			var mat := mi.get_active_material(s)
			if not tools.has(mat):
				var st := SurfaceTool.new()
				st.begin(Mesh.PRIMITIVE_TRIANGLES)
				tools[mat] = st
			(tools[mat] as SurfaceTool).append_from(mi.mesh, s, xf)
	var out := ArrayMesh.new()
	for mat in tools:
		var st := tools[mat] as SurfaceTool
		st.set_material(mat)
		st.commit(out)
	return out
