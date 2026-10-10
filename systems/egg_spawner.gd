extends Node3D
class_name EggSpawner
## =========================================================
## สุ่มวางไข่จากจุดเกิดหลายจุด (เจ้าของไฟล์: คนที่ 2)
##
## วิธีใช้:
##   1. ลาก systems/egg_spawner.tscn เข้าด่าน
##   2. เพิ่ม EggSpawnPoint เป็นลูกของมันหลายๆ จุด (เช่น 20 จุด)
##      (คลิกขวา EggSpawner > Add Child Node > EggSpawnPoint หรือ Ctrl+D ทำซ้ำจุดเดิม)
##   3. ตั้ง spawn_count = จำนวนไข่ที่จะสุ่มขึ้นมา (เช่น 8)
##   4. ที่ root ของด่าน (level.gd) ตั้ง eggs_required = 0 -> ต้องเก็บทุกใบที่สุ่มได้
##
## ไข่ถูกสร้างใน _ready() ของ node นี้ ซึ่งทำงานก่อน level.gd (node พ่อ) เสมอ
## GameManager จึงนับไข่ได้ครบตอนเริ่มด่าน
## =========================================================

@export var egg_scene: PackedScene = preload("res://systems/egg.tscn")
@export var spawn_count := 8          ## จำนวนไข่ที่สุ่มขึ้นมา (ถ้าจุดไม่พอจะใช้ทุกจุด)
@export var fixed_seed := 0           ## 0 = สุ่มใหม่ทุกครั้ง, ใส่เลขอื่น = ได้ชุดเดิมทุกครั้ง (ไว้ทดสอบ)
@export var spawn_all_for_testing := false  ## ติ๊กเพื่อวางไข่ครบทุกจุด (ไว้เช็คว่าทุกจุดเก็บได้)

@export_group("ความยาก: ไข่กลืนกับฉาก")
## สีที่จะสุ่มให้ไข่ (เว้นว่าง = สีพาสเทลสดใส หาง่าย) — ใส่สีโทนเดียวกับฉากเพื่อให้ไข่กลืน
@export var palette: PackedColorArray = []
## สุ่มเฉดสีเพิ่มเล็กน้อย (0 = ตรงตาม palette)
@export_range(0.0, 0.3, 0.01) var color_jitter := 0.06
## ความเรืองแสงของไข่ (0 = ไม่เรืองแสง กลืนกับฉาก, 0.25 = แบบเดิม)
@export_range(0.0, 2.0, 0.05) var glow := 0.25
## ไข่หมุนไหม (หมุน = สะดุดตา หาง่าย)
@export var spin := true

const PASTEL := [
	Color(1, 0.6, 0.75), Color(0.6, 0.85, 1), Color(1, 0.9, 0.4), Color(0.7, 1, 0.6),
	Color(0.85, 0.7, 1), Color(1, 0.7, 0.5), Color(0.6, 1, 0.9), Color(1, 0.6, 0.6),
]

var spawned_points: Array[EggSpawnPoint] = []


func _ready() -> void:
	var points: Array[EggSpawnPoint] = []
	for c in get_children():
		if c is EggSpawnPoint:
			points.append(c)

	var rng := RandomNumberGenerator.new()
	if fixed_seed != 0:
		rng.seed = fixed_seed
	else:
		rng.randomize()

	var chosen := points.duplicate() if spawn_all_for_testing else _pick_weighted(points, spawn_count, rng)
	if not spawn_all_for_testing and chosen.size() < spawn_count:
		push_warning("EggSpawner: มีจุดเกิดแค่ %d จุด แต่ต้องการ %d ใบ" % [chosen.size(), spawn_count])

	for i in chosen.size():
		var p: EggSpawnPoint = chosen[i]
		var egg := egg_scene.instantiate()
		egg.name = "Egg_" + p.name
		# มี palette = ใช้สีจาก palette เสมอ (ให้กลืนกับฉาก) / ไม่มี = ใช้สีที่ตั้งไว้ในจุดหรือพาสเทล
		egg.egg_color = p.egg_color if (p.use_custom_color and palette.is_empty()) else _pick_color(i, rng)
		egg.glow = glow
		if not spin:
			egg.spin_speed = 0.0
		add_child(egg)
		egg.global_transform = Transform3D(p.global_basis.orthonormalized().scaled(Vector3.ONE * p.egg_scale), p.global_position)
		spawned_points.append(p)
	print("EggSpawner: สุ่มไข่ %d ใบ จาก %d จุด -> %s" % [chosen.size(), points.size(), ", ".join(chosen.map(func(x): return x.name))])


func _pick_color(i: int, rng: RandomNumberGenerator) -> Color:
	if palette.is_empty():
		return PASTEL[i % PASTEL.size()]
	var c: Color = palette[rng.randi() % palette.size()]
	if color_jitter > 0.0:
		c = Color.from_hsv(
			fposmod(c.h + rng.randf_range(-color_jitter, color_jitter) * 0.5, 1.0),
			clampf(c.s + rng.randf_range(-color_jitter, color_jitter), 0.0, 1.0),
			clampf(c.v + rng.randf_range(-color_jitter, color_jitter), 0.0, 1.0))
	return c


## สุ่มแบบไม่ซ้ำ โดยคิดน้ำหนัก (weight) ของแต่ละจุด
func _pick_weighted(points: Array[EggSpawnPoint], n: int, rng: RandomNumberGenerator) -> Array:
	var pool := points.filter(func(p): return p.weight > 0.0)
	var result := []
	while result.size() < n and not pool.is_empty():
		var total := 0.0
		for p in pool:
			total += p.weight
		var r := rng.randf() * total
		for i in pool.size():
			r -= pool[i].weight
			if r <= 0.0 or i == pool.size() - 1:
				result.append(pool[i])
				pool.remove_at(i)
				break
	return result
