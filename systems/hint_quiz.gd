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

# ---- ธีมเดียวกับ UI ของคนที่ 3 (ครีม + ขอบน้ำตาลไม้ + ฟอนต์ Fredoka) ----
const UI_FONT := preload("res://ui/fonts/Fredoka-SemiBold.ttf")
const CREAM := Color("fff6e0")
const BROWN := Color("7a4a22")
const MINT := Color("a8e6cf")
const PINK := Color("f2b8dc")
const BLUE := Color("a8d8f0")
const YELLOW := Color("f7e08a")
const GOLD := Color("f5b800")


static func _panel_box(radius: int, pad: int, alpha := 0.95) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(CREAM, alpha)
	box.set_corner_radius_all(radius)
	box.set_border_width_all(6)
	box.border_color = BROWN
	box.shadow_color = Color(0, 0, 0, 0.3)
	box.shadow_size = 9
	box.shadow_offset = Vector2(0, 6)
	box.content_margin_left = pad + 6
	box.content_margin_right = pad + 6
	box.content_margin_top = pad - 4
	box.content_margin_bottom = pad - 4
	return box


static func _style_label(label: Label, size: int, color := BROWN, outline := 0, outline_color := BROWN) -> void:
	label.add_theme_font_override("font", UI_FONT)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_constant_override("outline_size", outline)
	label.add_theme_color_override("font_outline_color", outline_color)
const UIStyle := preload("res://ui/ui_style.gd")
const BUTTON_COLORS := [MINT, PINK, BLUE, YELLOW]


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
	_apply_theme()
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


func _apply_theme() -> void:
	var vbox := $Center/Panel/Margin/VBox as VBoxContainer
	var panel := $Center/Panel as PanelContainer
	panel.custom_minimum_size = Vector2(980, 0)
	panel.add_theme_stylebox_override("panel", _panel_box(54, 40))
	var margin := $Center/Panel/Margin as MarginContainer
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 6)
	vbox.add_theme_constant_override("separation", 14)
	_style_label($Center/Panel/Margin/VBox/Title, 34, GOLD, 10, BROWN)
	_style_label(kind_label, 48, BROWN)
	_style_label(question_label, 104, CREAM, 18, BROWN)
	_style_label(sub_label, 34, Color(BROWN, 0.8))
	_style_label(result_label, 40, BROWN)
	_style_label($Center/Panel/Margin/VBox/Keys, 26, Color(BROWN, 0.7))
	var grid := $Center/Panel/Margin/VBox/Grid as GridContainer
	grid.add_theme_constant_override("h_separation", 22)
	grid.add_theme_constant_override("v_separation", 22)
	for i in buttons.size():
		var b: Button = buttons[i]
		b.custom_minimum_size = Vector2(0, 104)
		UIStyle.style_button(b, BUTTON_COLORS[i], CREAM, BROWN, UI_FONT, 52)
		b.add_theme_stylebox_override("disabled", UIStyle.make_box(BUTTON_COLORS[i], BROWN, false))
		b.add_theme_color_override("font_disabled_color", CREAM)
		UIStyle.setup_hover(b, func(btn: Button, hovered: bool) -> void:
			if not btn.disabled: UIStyle.hover_tween(btn, hovered))
	# แถบเวลา
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color("ead9b8")
	bg.set_corner_radius_all(12)
	bg.set_border_width_all(4)
	bg.border_color = BROWN
	var fill := StyleBoxFlat.new()
	fill.bg_color = GOLD
	fill.set_corner_radius_all(12)
	bar.custom_minimum_size = Vector2(0, 26)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)


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
			buttons[j].add_theme_stylebox_override("disabled", UIStyle.make_box(Color("6fcf8f"), BROWN, false))
		elif j != i:
			buttons[j].modulate = Color(1, 1, 1, 0.55)
	if not ok:
		buttons[i].add_theme_stylebox_override("disabled", UIStyle.make_box(Color("ee6b6b"), BROWN, true))
	_finish(ok, "Correct! The nearest egg will glow." if ok else "Wrong! The answer is " + _answer)


func _finish(ok: bool, msg: String) -> void:
	_done = true
	result_label.text = msg
	result_label.add_theme_color_override("font_color", Color("3f9e5a") if ok else Color("e03b3b"))
	await get_tree().create_timer(1.2, true).timeout
	finished.emit(ok)
	queue_free()
