extends CanvasLayer
## =========================================================
## มินิเกมก่อนได้ Hint (เจ้าของไฟล์: คนที่ 2)
## GameManager เปิดหน้านี้เองเมื่อผู้เล่นกด Hint — ไม่ต้องลากใส่ด่าน
##
## ตอบถูก -> ได้ Hint (ไข่ที่ใกล้ที่สุดเด้ง + เรืองแสง)
## ตอบผิด / หมดเวลา -> ตั้งค่าใน GameManager (QUIZ_WRONG_COSTS_HINT)
##
## เพิ่ม/แก้คำถาม "เติมคำ" ได้ที่ WORD_QUESTIONS ด้านล่าง
##   word = คำที่มี _ แทนตัวที่หายไป, answer = ตัวที่ถูก, wrong = ตัวหลอก 3 ตัว
## =========================================================

signal finished(correct: bool)

@export var time_limit := 10.0   ## วินาทีที่ให้ตอบ

const WORD_QUESTIONS := [
	{"word": "กระ_่าย", "answer": "ต", "wrong": ["ด", "ถ", "ฎ"], "hint": "สัตว์หูยาว"},
	{"word": "ไข่อี_เตอร์", "answer": "ส", "wrong": ["ศ", "ษ", "ซ"], "hint": "สิ่งที่เรากำลังตามหา"},
	{"word": "ดอก_ม้", "answer": "ไ", "wrong": ["ใ", "เ", "แ"], "hint": "บานในสวน"},
	{"word": "ผี_สื้อ", "answer": "เ", "wrong": ["แ", "โ", "ไ"], "hint": "แมลงปีกสวย"},
	{"word": "แค_อท", "answer": "ร", "wrong": ["ล", "ว", "น"], "hint": "ผักสีส้มที่กระต่ายชอบ"},
	{"word": "ช็อก_กแลต", "answer": "โ", "wrong": ["เ", "แ", "ไ"], "hint": "ขนมหวานสีน้ำตาล"},
	{"word": "ส_นสนุก", "answer": "ว", "wrong": ["ร", "ล", "น"], "hint": "มีชิงช้าสวรรค์"},
	{"word": "ตะ_ร้า", "answer": "ก", "wrong": ["ข", "ค", "ง"], "hint": "ใช้ใส่ไข่"},
	{"word": "ลูก_วาด", "answer": "ก", "wrong": ["ข", "ด", "บ"], "hint": "ขนมหวานเม็ดเล็ก"},
	{"word": "ฤดูใบไม้_ลิ", "answer": "ผ", "wrong": ["พ", "ฝ", "ฟ"], "hint": "ฤดูของเทศกาลอีสเตอร์"},
	{"word": "พระอา_ิตย์", "answer": "ท", "wrong": ["ธ", "ต", "ด"], "hint": "ขึ้นตอนเช้า"},
	{"word": "สีชม_ู", "answer": "พ", "wrong": ["ภ", "ผ", "บ"], "hint": "สีของไข่บางใบ"},
	{"word": "_ันทร์", "answer": "จ", "wrong": ["ฉ", "ช", "ซ"], "hint": "ส่องแสงตอนกลางคืน"},
	{"word": "BUN_Y", "answer": "N", "wrong": ["M", "D", "R"], "hint": "กระต่ายภาษาอังกฤษ"},
	{"word": "E_G", "answer": "G", "wrong": ["C", "Q", "J"], "hint": "ไข่ภาษาอังกฤษ"},
	{"word": "BASK_T", "answer": "E", "wrong": ["A", "I", "O"], "hint": "ตะกร้าภาษาอังกฤษ"},
	{"word": "CARR_T", "answer": "O", "wrong": ["A", "U", "E"], "hint": "แครอทภาษาอังกฤษ"},
]

# static = จำค่าข้ามรอบ (หน้ามินิเกมถูกสร้างใหม่ทุกครั้งที่กด Hint)
static var _next_is_math := true          # สลับ บวกเลข -> เติมคำ -> บวกเลข ...
static var _word_deck: Array = []         # สำรับคำที่ยังไม่ได้ใช้ (ไม่ซ้ำจนกว่าจะครบทุกคำ)

var _answer := ""
var _choices: Array[String] = []
var _time_left := 0.0
var _done := false

@onready var kind_label: Label = $Center/Panel/Margin/VBox/Kind
@onready var question_label: Label = $Center/Panel/Margin/VBox/Question
@onready var sub_label: Label = $Center/Panel/Margin/VBox/Sub
@onready var buttons: Array[Button] = [
	$Center/Panel/Margin/VBox/Grid/B1, $Center/Panel/Margin/VBox/Grid/B2,
	$Center/Panel/Margin/VBox/Grid/B3, $Center/Panel/Margin/VBox/Grid/B4,
]
@onready var bar: ProgressBar = $Center/Panel/Margin/VBox/TimeBar
@onready var result_label: Label = $Center/Panel/Margin/VBox/Result


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# สลับประเภทโจทย์ทุกครั้ง ไม่ให้เจอแบบเดียวกันติดกัน
	if _next_is_math:
		_make_math()
	else:
		_make_word()
	_next_is_math = not _next_is_math
	_choices.shuffle()
	for i in buttons.size():
		buttons[i].text = "%d)  %s" % [i + 1, _choices[i]]
		buttons[i].pressed.connect(_choose.bind(i))
	_time_left = time_limit
	bar.max_value = time_limit
	bar.value = time_limit
	result_label.text = ""


func _make_math() -> void:
	kind_label.text = "บวกเลขเร็ว!"
	var a := randi_range(3, 25)
	var b := randi_range(2, 15)
	var ans := a + b
	question_label.text = "%d + %d = ?" % [a, b]
	sub_label.text = ""
	_answer = str(ans)
	var opts := {ans: true}
	for d in [1, -1, 2, -2, 10, -10, 3]:
		if opts.size() >= 4:
			break
		var v: int = ans + int(d)
		if v > 0 and not opts.has(v) and randf() < 0.8:
			opts[v] = true
	var extra := 4
	while opts.size() < 4:
		opts[ans + extra] = true
		extra += 1
	_choices.clear()
	for k in opts.keys():
		_choices.append(str(k))


func _make_word() -> void:
	if _word_deck.is_empty():
		_word_deck = WORD_QUESTIONS.duplicate()
		_word_deck.shuffle()
	var q: Dictionary = _word_deck.pop_back()
	kind_label.text = "เติมคำให้ถูก!"
	question_label.text = q["word"].replace("_", "□")
	sub_label.text = "คำใบ้: " + q["hint"]
	_answer = q["answer"]
	_choices.clear()
	_choices.append(q["answer"])
	for w in q["wrong"]:
		_choices.append(w)


func _process(delta: float) -> void:
	if _done:
		return
	_time_left -= delta
	bar.value = max(_time_left, 0.0)
	if _time_left <= 0.0:
		_finish(false, "หมดเวลา! คำตอบคือ " + _answer)


func _input(event: InputEvent) -> void:
	if _done or not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var k: int = event.physical_keycode
	var idx := -1
	if k >= KEY_1 and k <= KEY_4:
		idx = k - KEY_1
	elif k >= KEY_KP_1 and k <= KEY_KP_4:
		idx = k - KEY_KP_1
	if idx >= 0:
		get_viewport().set_input_as_handled()
		_choose(idx)


func _choose(i: int) -> void:
	if _done:
		return
	var ok := _choices[i] == _answer
	for j in buttons.size():
		buttons[j].disabled = true
		if _choices[j] == _answer:
			buttons[j].modulate = Color(0.6, 1, 0.6)
	if not ok:
		buttons[i].modulate = Color(1, 0.5, 0.5)
	_finish(ok, "ถูกต้อง! ไข่ที่ใกล้ที่สุดจะเรืองแสง" if ok else "ผิด! คำตอบคือ " + _answer)


func _finish(ok: bool, msg: String) -> void:
	_done = true
	result_label.text = msg
	result_label.add_theme_color_override("font_color", Color(0.6, 1, 0.6) if ok else Color(1, 0.55, 0.55))
	await get_tree().create_timer(1.2, true).timeout
	finished.emit(ok)
	queue_free()
