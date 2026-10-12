extends Node
## =========================================================
## SoundManager — เพลงพื้นหลัง + เสียงเอฟเฟกต์ของเกม (เจ้าของ: คนที่ 2)
## GameManager สร้าง node นี้เองตอนเริ่มเกม ไม่ต้องตั้ง Autoload เพิ่ม
##
## - เปลี่ยนเพลงอัตโนมัติตามฉากที่เปิดอยู่ (เมนู / ด่าน 1-3 / ชนะ / แพ้)
## - เล่นเสียงตาม signal ของ GameManager (เก็บไข่, ผ่านด่าน, เวลาใกล้หมด)
## - ระดับเสียงรวมปรับได้จากหน้า Settings ของคนที่ 3 (bus Master)
##
## เปลี่ยนไฟล์เสียง: แก้ path ด้านล่าง (วางไฟล์ไว้ในโฟลเดอร์ sound/)
## =========================================================

const MUSIC_MENU := "res://sound/menu.mp3"
const MUSIC_LEVELS := [
	"res://sound/level1.mp3",   # ด่าน 1 Dark Room
	"res://sound/level2.mp3",   # ด่าน 2 Funfair
	"res://sound/level3.mp3",   # ด่าน 3 Garden
]
const MUSIC_FINAL := "res://sound/level3.mp3"   # พื้นที่ลับตอนจบ
const MUSIC_WIN := "res://sound/win.mp3"
const MUSIC_LOSE := "res://sound/gameover.mp3"
const SFX_EGG := "res://sound/egg_collect.mp3"
const SFX_LEVEL_COMPLETE := "res://sound/level_complete.mp3"

const MENU_SCENES := ["res://ui/title_screen.tscn", "res://ui/main_menu.tscn"]

@export var music_volume_db := -6.0
@export var sfx_volume_db := 0.0
@export var low_time_pitch := 1.12   ## เวลาใกล้หมด -> เพลงเร็วขึ้น

var _music: AudioStreamPlayer
var _sfx: Array[AudioStreamPlayer] = []
var _music_path := ""
var _scene_path := ""
var _last_eggs := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS   # เพลงเล่นต่อตอน Pause / มินิเกม
	# แก้โดยคนที่ 3 (UI): ส่งเสียงเข้า bus Music/SFX
	GameSettings.ensure_setup()
	_music = AudioStreamPlayer.new()
	_music.bus = &"Music"
	_music.volume_db = music_volume_db
	add_child(_music)
	for i in 4:
		var p := AudioStreamPlayer.new()
		p.volume_db = sfx_volume_db
		# แก้โดยคนที่ 3 (UI): ส่งเสียงเข้า bus Music/SFX
		p.bus = &"SFX"
		add_child(p)
		_sfx.append(p)

	var gm := get_parent()
	gm.egg_collected.connect(_on_egg_collected)
	gm.level_completed.connect(_on_level_completed)
	gm.level_started.connect(_on_level_started)
	gm.time_low.connect(_on_time_low)
	gm.game_won.connect(func(): play_music(MUSIC_WIN, false))
	gm.game_lost.connect(func(): play_music(MUSIC_LOSE, false))


func _process(_delta: float) -> void:
	# เปลี่ยนเพลงเมื่อฉากเปลี่ยน
	var cs := get_tree().current_scene
	var path := cs.scene_file_path if cs else ""
	if path == _scene_path:
		return
	_scene_path = path
	if path in MENU_SCENES:
		play_music(MUSIC_MENU)
	elif path == get_parent().FINAL_AREA:
		play_music(MUSIC_FINAL)
	else:
		var idx: int = get_parent().LEVELS.find(path)
		if idx >= 0 and idx < MUSIC_LEVELS.size():
			play_music(MUSIC_LEVELS[idx])
	# หน้าชนะ/แพ้: เพลงถูกสั่งจาก signal game_won / game_lost แล้ว ไม่ต้องเปลี่ยน


## เล่นเพลงพื้นหลัง (ถ้าเป็นเพลงเดิมที่เล่นอยู่แล้ว จะไม่เริ่มใหม่)
func play_music(path: String, loop := true) -> void:
	if path == _music_path and _music.playing:
		return
	var stream := _load(path)
	if stream == null:
		return
	if "loop" in stream:
		stream.loop = loop
	_music_path = path
	_music.stream = stream
	_music.pitch_scale = 1.0
	_music.volume_db = music_volume_db
	_music.play()


## เล่นเสียงเอฟเฟกต์สั้นๆ (เล่นซ้อนกันได้ 4 เสียง)
func play_sfx(path: String) -> void:
	var stream := _load(path)
	if stream == null:
		return
	if "loop" in stream:
		stream.loop = false
	for p in _sfx:
		if not p.playing:
			p.stream = stream
			p.play()
			return
	_sfx[0].stream = stream
	_sfx[0].play()


func _load(path: String) -> AudioStream:
	if not ResourceLoader.exists(path):
		push_warning("SoundManager: ไม่พบไฟล์เสียง %s" % path)
		return null
	return load(path) as AudioStream


# ---------------- GameManager signals ----------------

func _on_level_started(_i: int) -> void:
	_last_eggs = 0
	_music.pitch_scale = 1.0


func _on_egg_collected(collected: int, _required: int) -> void:
	if collected > _last_eggs:
		play_sfx(SFX_EGG)
	_last_eggs = collected


func _on_level_completed(_i: int) -> void:
	play_sfx(SFX_LEVEL_COMPLETE)
	# เบาเพลงลงระหว่างรอเปลี่ยนด่าน
	create_tween().tween_property(_music, "volume_db", music_volume_db - 14.0, 0.6)


func _on_time_low() -> void:
	create_tween().tween_property(_music, "pitch_scale", low_time_pitch, 1.0)
