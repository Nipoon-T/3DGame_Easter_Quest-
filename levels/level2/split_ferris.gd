extends SceneTree
## Tool script: แยก mesh ของ assets_mint/ferris_wheel.glb ออกเป็นชิ้นส่วน (ไม่แก้ไฟล์ glb ต้นฉบับ)
## รันด้วย:
##   Godot --headless --path . --script res://levels/level2/split_ferris.gd
## ผลลัพธ์:
##   levels/level2/ferris_parts/legs.res, wheel.res, cabin_00..11.res
##   levels/level2/ferris_wheel_spin.tscn
##
## วิธีแยก: glb นี้แยกตามวัสดุ (surface) อยู่แล้ว
##   - legs_red   = ขา 4 แผ่น (อยู่นิ่ง)
##   - white/red/yellow/orange = ขอบล้อ ซี่ล้อ วงเหลือง แกนกลาง (หมุน)
##   - cabin_* (4 สี) แต่ละสีมี 3 กระเช้า (ตัว + หลังคา) และ blue = แกนห้อยกระเช้า 12 แท่ง
##     จับคู่ตัวกระเช้า/หลังคา/แกน ด้วย connected components (เชื่อมกันด้วยจุดยอดที่ตำแหน่งเดียวกัน)
##     แล้วจับคู่ตามระยะใกล้สุด

const SRC := "res://assets_mint/ferris_wheel.glb"
const OUT := "res://levels/level2/ferris_parts/"
const SCENE_OUT := "res://levels/level2/ferris_wheel_spin.tscn"
const SCALE := 7.0                      ## ขนาดเท่าตัวเดิม (ferris_ride.tscn)
const SURF_CABINS: Array[int] = [0, 7, 8, 9]
const SURF_WHEEL: Array[int] = [1, 2, 3, 6]
const SURF_LEGS := 4
const SURF_RODS := 5

var _mesh: ArrayMesh


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var inst := (load(SRC) as PackedScene).instantiate()
	for n in inst.find_children("*", "MeshInstance3D", true, false):
		_mesh = (n as MeshInstance3D).mesh as ArrayMesh
	var whole: AABB = _mesh.get_aabb()

	# ---- ขา ----
	var legs_mesh := ArrayMesh.new()
	_add_surface(legs_mesh, _mesh.surface_get_arrays(SURF_LEGS), _mesh.surface_get_material(SURF_LEGS))
	_save(legs_mesh, "legs")
	var leg_comps := _components(SURF_LEGS)

	# ---- วงล้อ ----
	# จุดหมุนของวงล้อ = ศูนย์กลางของขอบล้อสีขาว (อยู่ที่ y = +0.09 ไม่ใช่ origin ของโมเดล)
	var hub: Vector3 = _surface_aabb(1).get_center()
	var rim_r := _ring_radius(1, hub)
	var wheel_mesh := ArrayMesh.new()
	for s in SURF_WHEEL:
		var warr := _mesh.surface_get_arrays(s)
		var all_tris: Array = []
		for t in range(0, (warr[Mesh.ARRAY_INDEX] as PackedInt32Array).size(), 3):
			all_tris.append(t)
		_add_surface(wheel_mesh, _extract(warr, all_tris, hub), _mesh.surface_get_material(s))
	_save(wheel_mesh, "wheel")

	# ---- กระเช้า ----
	var rods := _components(SURF_RODS)
	var cabins: Array = []   # [{mesh, pivot}]
	for s in SURF_CABINS:
		var comps := _components(s)
		var bodies: Array = []
		var roofs: Array = []
		for c in comps:
			if (c["tris"] as Array).size() >= 80:
				bodies.append(c)
			else:
				roofs.append(c)
		for body in bodies:
			var roof := _nearest(roofs, body["bb"].get_center(), true)
			var rod := _nearest(rods, body["bb"].get_center(), false)
			roofs.erase(roof)
			rods.erase(rod)
			var rod_bb: AABB = rod["bb"]
			# จุดแขวน = จุดที่แกนห้อย (เส้นตั้ง) ตัดกับวงกลมขอบล้อ รัศมี rim_r กระเช้าห้อยลงมาจากจุดนี้
			var pivot := _rim_point(rod_bb, hub, rim_r)
			print("cabin ", cabins.size(), " rim radius ", snappedf(Vector2(pivot.x - hub.x, pivot.y - hub.y).length(), 0.001), " rod y ", snappedf(rod_bb.position.y, 0.01), "..", snappedf(rod_bb.end.y, 0.01), " pivot y ", snappedf(pivot.y, 0.01), " dx roof ", snappedf(roof["bb"].get_center().x - body["bb"].get_center().x, 0.001), " dx rod ", snappedf(rod_bb.get_center().x - body["bb"].get_center().x, 0.001))
			var m := ArrayMesh.new()
			var tris: Array = (body["tris"] as Array) + (roof["tris"] as Array)
			_add_surface(m, _extract(_mesh.surface_get_arrays(s), tris, pivot), _mesh.surface_get_material(s))
			_add_surface(m, _extract(_mesh.surface_get_arrays(SURF_RODS), rod["tris"], pivot), _mesh.surface_get_material(SURF_RODS))
			cabins.append({"mesh": m, "pivot": pivot, "low": rod_bb.position.y})
	for i in cabins.size():
		_save(cabins[i]["mesh"], "cabin_%02d" % i)
	var lowest := INF
	for cb in cabins:
		lowest = minf(lowest, hub.y - rim_r - ((cb["pivot"] as Vector3).y - (cb["low"] as float)))
	print("hub ", hub, " ระยะต่ำสุดของก้นกระเช้าเมื่อหมุน (หน่วยโมเดล) ", snappedf(lowest, 0.001), " ก้นขา ", snappedf(whole.position.y, 0.001), " => เหนือพื้น ", snappedf((lowest - whole.position.y) * SCALE, 0.01), " ม.")
	print("cabins: ", cabins.size(), " leg parts: ", leg_comps.size(), " (ควรได้ 12 และ 4)")

	# ---- scene ----
	var root := Node3D.new()
	root.name = "FerrisWheelSpin"
	root.set_script(load("res://levels/level2/ferris_wheel_spin.gd"))
	var model := Node3D.new()
	model.name = "Model"
	root.add_child(model)
	model.owner = root
	model.scale = Vector3.ONE * SCALE
	var c := whole.get_center()
	model.position = Vector3(-c.x * SCALE, -whole.position.y * SCALE, -c.z * SCALE)
	var legs_node := MeshInstance3D.new()
	legs_node.name = "Legs"
	legs_node.mesh = load(OUT + "legs.res")
	model.add_child(legs_node)
	legs_node.owner = root
	var wheel := Node3D.new()
	wheel.name = "Wheel"
	model.add_child(wheel)
	wheel.owner = root
	wheel.unique_name_in_owner = true
	wheel.position = hub
	var wheel_mesh_node := MeshInstance3D.new()
	wheel_mesh_node.name = "WheelMesh"
	wheel_mesh_node.mesh = load(OUT + "wheel.res")
	wheel.add_child(wheel_mesh_node)
	wheel_mesh_node.owner = root
	var cabins_node := Node3D.new()
	cabins_node.name = "Cabins"
	wheel.add_child(cabins_node)
	cabins_node.owner = root
	cabins_node.unique_name_in_owner = true
	for i in cabins.size():
		var piv := Node3D.new()
		piv.name = "Pivot%02d" % i
		piv.position = (cabins[i]["pivot"] as Vector3) - hub
		cabins_node.add_child(piv)
		piv.owner = root
		var mi := MeshInstance3D.new()
		mi.name = "Cabin"
		mi.mesh = load(OUT + "cabin_%02d.res" % i)
		piv.add_child(mi)
		mi.owner = root
	# collision: เฉพาะขา (กล่องเอียงตามแผ่นขา) ใต้ StaticBody3D ที่ไม่ถูก scale
	var body := StaticBody3D.new()
	body.name = "Body"
	root.add_child(body)
	body.owner = root
	for i in leg_comps.size():
		var bb: AABB = leg_comps[i]["bb"]
		var cx := bb.get_center().x
		var dx := bb.size.x
		var dy := bb.size.y
		var sgn := 1.0 if cx > 0.0 else -1.0
		var length := Vector2(dx, dy).length()
		var cs := CollisionShape3D.new()
		cs.name = "LegShape%d" % i
		var shape := BoxShape3D.new()
		shape.size = Vector3(0.7, length * SCALE, 0.8)
		cs.shape = shape
		body.add_child(cs)
		cs.owner = root
		cs.position = model.position + bb.get_center() * SCALE
		cs.rotation.z = sgn * asin(dx / length)
	var ps := PackedScene.new()
	print("pack: ", ps.pack(root))
	print("save scene: ", ResourceSaver.save(ps, SCENE_OUT))
	quit()


## ส่งคืน [{tris: Array[int] (index เริ่มของสามเหลี่ยม), bb: AABB}] ของแต่ละชิ้นที่ไม่ต่อกัน
func _components(surface: int) -> Array:
	var arr := _mesh.surface_get_arrays(surface)
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var key2id := {}
	var remap := PackedInt32Array()
	remap.resize(v.size())
	for i in v.size():
		var k := Vector3i((v[i] * 10000.0).round())
		if not key2id.has(k):
			key2id[k] = key2id.size()
		remap[i] = key2id[k]
	var parent := PackedInt32Array()
	parent.resize(key2id.size())
	for i in parent.size():
		parent[i] = i
	for t in range(0, idx.size(), 3):
		for o in [1, 2]:
			var a := _find(parent, remap[idx[t]])
			var b := _find(parent, remap[idx[t + o]])
			if a != b:
				parent[b] = a
	var groups := {}
	for t in range(0, idx.size(), 3):
		var r := _find(parent, remap[idx[t]])
		if not groups.has(r):
			groups[r] = []
		(groups[r] as Array).append(t)
	var out: Array = []
	for r in groups:
		var tris: Array = groups[r]
		var bb := AABB(v[idx[tris[0]]], Vector3.ZERO)
		for t in tris:
			for o in 3:
				bb = bb.expand(v[idx[t + o]])
		out.append({"tris": tris, "bb": bb})
	return out


func _find(parent: PackedInt32Array, x: int) -> int:
	while parent[x] != x:
		parent[x] = parent[parent[x]]
		x = parent[x]
	return x


func _nearest(list: Array, center: Vector3, roof_above: bool) -> Dictionary:
	var best: Dictionary = {}
	var best_d := INF
	for c in list:
		var cc: Vector3 = (c["bb"] as AABB).get_center()
		var d := Vector2(cc.x - center.x, cc.y - center.y).length()
		if roof_above and cc.y < center.y:
			d += 10.0
		if d < best_d:
			best_d = d
			best = c
	return best


## สร้าง arrays ใหม่จากสามเหลี่ยมที่เลือก (ตัด vertex ที่ไม่ใช้ และย้ายตำแหน่งด้วย -shift)
func _extract(arr: Array, tris: Array, shift: Vector3) -> Array:
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var n: PackedVector3Array = arr[Mesh.ARRAY_NORMAL] if arr[Mesh.ARRAY_NORMAL] != null else PackedVector3Array()
	var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV] if arr[Mesh.ARRAY_TEX_UV] != null else PackedVector2Array()
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var map := {}
	var nv := PackedVector3Array()
	var nn := PackedVector3Array()
	var nuv := PackedVector2Array()
	var ni := PackedInt32Array()
	for t in tris:
		for o in 3:
			var old := idx[t + o]
			if not map.has(old):
				map[old] = nv.size()
				nv.append(v[old] - shift)
				if n.size() > 0:
					nn.append(n[old])
				if uv.size() > 0:
					nuv.append(uv[old])
			ni.append(map[old])
	var out := []
	out.resize(Mesh.ARRAY_MAX)
	out[Mesh.ARRAY_VERTEX] = nv
	if nn.size() > 0:
		out[Mesh.ARRAY_NORMAL] = nn
	if nuv.size() > 0:
		out[Mesh.ARRAY_TEX_UV] = nuv
	out[Mesh.ARRAY_INDEX] = ni
	return out


func _add_surface(m: ArrayMesh, arrays: Array, mat: Material) -> void:
	# ใช้เฉพาะ vertex/normal/uv/index ที่จำเป็น (เมชนี้ไม่มี tangent/color)
	var clean := []
	clean.resize(Mesh.ARRAY_MAX)
	for k in [Mesh.ARRAY_VERTEX, Mesh.ARRAY_NORMAL, Mesh.ARRAY_TEX_UV, Mesh.ARRAY_INDEX]:
		clean[k] = arrays[k]
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, clean)
	m.surface_set_material(m.get_surface_count() - 1, mat.duplicate())


func _save(m: Mesh, nm: String) -> void:
	print("save ", nm, ": ", ResourceSaver.save(m, OUT + nm + ".res"))


func _surface_aabb(surface: int) -> AABB:
	var v: PackedVector3Array = _mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]
	var bb := AABB(v[0], Vector3.ZERO)
	for p in v:
		bb = bb.expand(p)
	return bb


func _ring_radius(surface: int, hub: Vector3) -> float:
	var v: PackedVector3Array = _mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]
	var rmin := INF
	var rmax := 0.0
	for p in v:
		var r := Vector2(p.x - hub.x, p.y - hub.y).length()
		rmin = minf(rmin, r)
		rmax = maxf(rmax, r)
	return (rmin + rmax) * 0.5


## จุดบนแกนห้อย (เส้นตั้งผ่านกลางแท่ง) ที่อยู่บนวงกลมรัศมี rim_r รอบ hub
func _rim_point(rod_bb: AABB, hub: Vector3, rim_r: float) -> Vector3:
	var x := rod_bb.get_center().x
	var dx := x - hub.x
	var dy := sqrt(maxf(rim_r * rim_r - dx * dx, 0.0))
	var best_y := hub.y + dy
	var lo := rod_bb.position.y
	var hi := rod_bb.end.y
	var d_up := maxf(lo - (hub.y + dy), (hub.y + dy) - hi)
	var d_dn := maxf(lo - (hub.y - dy), (hub.y - dy) - hi)
	if d_dn < d_up:
		best_y = hub.y - dy
	return Vector3(x, best_y, rod_bb.get_center().z)
