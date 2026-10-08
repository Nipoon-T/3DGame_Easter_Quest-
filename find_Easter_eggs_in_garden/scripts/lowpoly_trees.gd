@tool
extends Node3D
## LowPolyTrees — ต้นไม้ low-poly หลายชนิด สร้างจากรูปทรงพื้นฐาน + flat shading + สีจาก vertex color
## ไม่ใช้ไฟล์โมเดล/texture เลย จึงไม่เพิ่มขนาดเกม (0 MB)
## ตำแหน่งทั้งหมดเก็บใน `positions` (MultiMesh ที่มีแต่ transform) วาดทั้งชนิดใน 1 draw call
## collision ของลำต้นอยู่ในฉากหลัก (ForestTrees/Collision) ไม่ได้สร้างในสคริปต์นี้

@export_enum("oak", "birch", "poplar", "fir", "blossom") var species := "oak"
@export var positions: MultiMesh

static var _meshes := {}
var _mmi: MultiMeshInstance3D

const BARK := Color(0.45, 0.31, 0.2)
const BIRCH_BARK := Color(0.93, 0.91, 0.86)


func _ready() -> void:
	if positions == null:
		return
	var mm := positions.duplicate() as MultiMesh
	mm.mesh = get_species_mesh(species)
	_mmi = MultiMeshInstance3D.new()
	_mmi.multimesh = mm
	add_child(_mmi)


static func get_species_mesh(sp: String) -> Mesh:
	if _meshes.has(sp):
		return _meshes[sp]
	var b := Builder.new()
	match sp:
		"oak":
			b.cyl(Vector3.ZERO, 0.24, 0.15, 2.3, 6, BARK)
			b.blob(Vector3(0, 3.0, 0), Vector3(1.35, 1.05, 1.35), Color(0.33, 0.58, 0.22))
			b.blob(Vector3(0.8, 2.6, 0.35), Vector3(0.85, 0.7, 0.85), Color(0.4, 0.66, 0.26))
			b.blob(Vector3(-0.7, 2.7, -0.45), Vector3(0.9, 0.75, 0.9), Color(0.36, 0.62, 0.24))
			b.blob(Vector3(0.1, 3.75, -0.1), Vector3(0.85, 0.65, 0.85), Color(0.42, 0.7, 0.28))
		"birch":
			b.cyl(Vector3.ZERO, 0.14, 0.1, 3.4, 5, BIRCH_BARK)
			b.cyl(Vector3(0, 1.1, 0), 0.142, 0.14, 0.12, 5, Color(0.2, 0.2, 0.2))
			b.cyl(Vector3(0, 2.2, 0), 0.125, 0.122, 0.1, 5, Color(0.2, 0.2, 0.2))
			b.blob(Vector3(0, 3.6, 0), Vector3(0.95, 1.3, 0.95), Color(0.62, 0.8, 0.32))
			b.blob(Vector3(0.35, 4.4, 0.1), Vector3(0.6, 0.8, 0.6), Color(0.7, 0.85, 0.38))
		"poplar":
			b.cyl(Vector3.ZERO, 0.17, 0.12, 0.9, 5, BARK)
			b.blob(Vector3(0, 2.75, 0), Vector3(0.8, 2.1, 0.8), Color(0.2, 0.46, 0.24))
		"fir":
			b.cyl(Vector3.ZERO, 0.18, 0.12, 0.7, 5, BARK)
			b.cone(Vector3(0, 0.5, 0), 1.35, 1.9, 7, Color(0.18, 0.45, 0.38))
			b.cone(Vector3(0, 1.55, 0), 1.05, 1.7, 7, Color(0.2, 0.5, 0.42))
			b.cone(Vector3(0, 2.55, 0), 0.72, 1.6, 7, Color(0.23, 0.55, 0.45))
		"blossom":
			b.cyl(Vector3.ZERO, 0.2, 0.13, 2.3, 6, Color(0.42, 0.28, 0.22))
			b.blob(Vector3(0, 3.0, 0), Vector3(1.25, 0.9, 1.25), Color(0.98, 0.7, 0.8))
			b.blob(Vector3(0.8, 2.75, -0.3), Vector3(0.75, 0.6, 0.75), Color(1.0, 0.8, 0.88))
			b.blob(Vector3(-0.65, 2.8, 0.45), Vector3(0.8, 0.65, 0.8), Color(0.96, 0.64, 0.76))
			b.blob(Vector3(0.05, 3.65, 0.1), Vector3(0.7, 0.55, 0.7), Color(1.0, 0.86, 0.92))
	var m := b.commit()
	_meshes[sp] = m
	return m


class Builder:
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()

	## ทรงรีโลว์โพลี (size = รัศมีแต่ละแกน)
	func blob(center: Vector3, size: Vector3, col: Color) -> void:
		var s := SphereMesh.new()
		s.radial_segments = 7
		s.rings = 4
		_add(s.get_mesh_arrays(), Transform3D(Basis.from_scale(size * 2.0), center), center, col)

	## ทรงกระบอก ฐานอยู่ที่ base
	func cyl(base: Vector3, r_bottom: float, r_top: float, h: float, seg: int, col: Color) -> void:
		var c := CylinderMesh.new()
		c.bottom_radius = r_bottom
		c.top_radius = r_top
		c.height = h
		c.radial_segments = seg
		c.rings = 1
		var center := base + Vector3(0, h / 2.0, 0)
		_add(c.get_mesh_arrays(), Transform3D(Basis(), center), center, col)

	## กรวย ฐานอยู่ที่ base
	func cone(base: Vector3, r: float, h: float, seg: int, col: Color) -> void:
		cyl(base, r, 0.0, h, seg, col)

	func _add(arrays: Array, xf: Transform3D, center: Vector3, col: Color) -> void:
		var v: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		for t in range(0, idx.size(), 3):
			var a := xf * v[idx[t]]
			var b := xf * v[idx[t + 1]]
			var c := xf * v[idx[t + 2]]
			var n := (b - a).cross(c - a)
			if n.length_squared() < 1e-10:
				continue
			n = n.normalized()
			if n.dot((a + b + c) / 3.0 - center) < 0.0:
				n = -n
			# สีต่างกันเล็กน้อยทีละหน้า ให้ดู low-poly
			var shade := 0.9 + 0.12 * float((t / 3 * 7) % 5) / 4.0
			var fc := Color(col.r * shade, col.g * shade, col.b * shade)
			for p in [a, b, c]:
				verts.append(p)
				normals.append(n)
				colors.append(fc)

	func commit() -> ArrayMesh:
		var arr := []
		arr.resize(Mesh.ARRAY_MAX)
		arr[Mesh.ARRAY_VERTEX] = verts
		arr[Mesh.ARRAY_NORMAL] = normals
		arr[Mesh.ARRAY_COLOR] = colors
		var m := ArrayMesh.new()
		m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		var mat := StandardMaterial3D.new()
		mat.vertex_color_use_as_albedo = true
		mat.vertex_color_is_srgb = true
		mat.roughness = 0.9
		m.surface_set_material(0, mat)
		return m
