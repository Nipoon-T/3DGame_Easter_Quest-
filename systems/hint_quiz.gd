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
	{"word": "BUN_Y", "answer": "N", "wrong": ["M", "D", "R"], "hint": "A cute animal with long ears"},
	{"word": "E_G", "answer": "G", "wrong": ["C", "Q", "J"], "hint": "What you are looking for"},
	{"word": "BASK_T", "answer": "E", "wrong": ["A", "I", "O"], "hint": "You carry eggs in it"},
	{"word": "CARR_T", "answer": "O", "wrong": ["A", "U", "E"], "hint": "Orange vegetable bunnies love"},
	{"word": "FLOW_R", "answer": "E", "wrong": ["A", "O", "I"], "hint": "It blooms in the garden"},
	{"word": "SPR_NG", "answer": "I", "wrong": ["A", "E", "O"], "hint": "The season of Easter"},
	{"word": "CHOCO_ATE", "answer": "L", "wrong": ["R", "N", "T"], "hint": "Sweet and brown"},
	{"word": "CHI_K", "answer": "C", "wrong": ["K", "S", "T"], "hint": "A baby chicken"},
	{"word": "CAN_Y", "answer": "D", "wrong": ["T", "B", "N"], "hint": "A small sweet treat"},
	{"word": "BUTT_RFLY", "answer": "E", "wrong": ["A", "O", "U"], "hint": "Insect with pretty wings"},
	{"word": "RAIN_OW", "answer": "B", "wrong": ["D", "P", "V"], "hint": "Seven colors in the sky"},
	{"word": "S_N", "answer": "U", "wrong": ["A", "O", "I"], "hint": "It shines in the morning"},
	{"word": "M_ON", "answer": "O", "wrong": ["A", "E", "U"], "hint": "It shines at night"},
	{"word": "GARD_N", "answer": "E", "wrong": ["A", "I", "O"], "hint": "Where flowers grow"},
	{"word": "PIN_", "answer": "K", "wrong": ["G", "T", "C"], "hint": "A soft egg color"},
	{"word": "HUN_", "answer": "T", "wrong": ["D", "G", "K"], "hint": "Egg ___ = searching for eggs"},
	{"word": "LAM_", "answer": "B", "wrong": ["P", "D", "M"], "hint": "A baby sheep"},
]

# static = จำค่าข้ามรอบ (หน้ามินิเกมถูกสร้างใหม่ทุกครั้งที่กด Hint)
static var _last_was_math := false        # ประเภทโจทย์ครั้งก่อน
static var _streak := 0                   # ได้ประเภทเดิมติดกันกี่ครั้งแล้ว
const MAX_SAME_IN_ROW := 2                ## สุ่มประเภทโจทย์ แต่ห้ามซ้ำเกินกี่ครั้งติด
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
	# สุ่มประเภทโจทย์ 50:50 แต่ถ้าได้แบบเดิมครบ MAX_SAME_IN_ROW ครั้งแล้ว บังคับเป็นอีกแบบ
	var is_math := randf() < 0.5
	if _streak >= MAX_SAME_IN_ROW and is_math == _last_was_math:
		is_math = not is_math
	_streak = _streak + 1 if (is_math == _last_was_math and _streak > 0) else 1
	_last_was_math = is_math
	if is_math:
		_make_math()
	else:
		_make_word()
	_choices.shuffle()
	for i in buttons.size():
		buttons[i].text = "%d)  %s" % [i + 1, _choices[i]]
		buttons[i].pressed.connect(_choose.bind(i))
	_time_left = time_limit
	bar.max_value = time_limit
	bar.value = time_limit
	result_label.text = ""


func _make_math() -> void:
	kind_label.text = "Quick Math!"
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
	kind_label.text = "Fill in the Missing Letter!"
	question_label.text = q["word"].replace("_", " _ ").strip_edges()
	sub_label.text = "Clue: " + q["hint"]
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
		_finish(false, "Time's up! The answer is " + _answer)


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
	_finish(ok, "Correct! The nearest egg will glow." if ok else "Wrong! The answer is " + _answer)


func _finish(ok: bool, msg: String) -> void:
	_done = true
	result_label.text = msg
	result_label.add_theme_color_override("font_color", Color(0.6, 1, 0.6) if ok else Color(1, 0.55, 0.55))
	await get_tree().create_timer(1.2, true).timeout
	finished.emit(ok)
	queue_free()
