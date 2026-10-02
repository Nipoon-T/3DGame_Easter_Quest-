extends CanvasLayer
## HUD ระหว่างเล่น: ตัวนับไข่, นาฬิกา, ปุ่ม Hint, ชื่อด่าน, ป๊อปอัปผ่านด่าน
## ใช้งาน: ลาก ui/hud.tscn ไปวางเป็นลูกของ node รากของด่าน
## อ่านข้อมูลผ่าน signal ของ GameManager เท่านั้น (ไม่แตะ Player/ด่าน)
## ปุ่มคีย์บอร์ด "hint" GameManager รับอยู่แล้ว HUD จึงไม่รับปุ่มซ้ำ (กดคีย์ = ใช้ 1 ครั้ง)

# ---------- ขนาด (ปรับใน Inspector ถ้าเปลี่ยนขนาดจอ) ----------
@export_group("Size")
@export var font: Font
@export var screen_margin: int = 28
@export var counter_font_size: int = 36
@export var clock_font_size: int = 36
@export var icon_size: int = 44
@export var hint_button_size: int = 120
@export var hint_font_size: int = 28
@export var badge_font_size: int = 24
@export var key_font_size: int = 22
@export var title_font_size: int = 96
@export var complete_font_size: int = 72

# ---------- สี ----------
@export_group("Colors")
@export var cream := Color("fff6e0")
@export var panel_alpha: float = 0.92
@export var border_color := Color("7a4a22")
@export var text_color := Color("7a4a22")
@export var mint := Color("a8e6cf")
@export var pink := Color("f2b8dc")
@export var gold := Color("f5b800")
@export var hint_color := Color("fff2a8")      # เหลืองอ่อน
@export var hint_disabled_color := Color("b9b4a8")
@export var danger_color := Color("e03b3b")

# ---------- พฤติกรรม ----------
@export_group("Behavior")
@export var level_names: Array[String] = ["Dark Room", "Funfair", "Secret Garden", "Secret Area"]
@export var title_duration: float = 2.0
@export var low_time_threshold: float = 30.0

@onready var margin: MarginContainer = %Margin
@onready var egg_panel: PanelContainer = %EggPanel
@onready var egg_icon: Control = %EggIcon
@onready var egg_label: Label = %EggLabel
@onready var clock_panel: PanelContainer = %ClockPanel
@onready var sun_icon: Control = %SunIcon
@onready var time_label: Label = %TimeLabel
@onready var hint_holder: Control = %HintHolder
@onready var hint_button: Button = %HintButton
@onready var hint_badge: PanelContainer = %HintBadge
@onready var hint_count_label: Label = %HintCountLabel
@onready var hint_key_label: Label = %HintKeyLabel
@onready var level_title: Label = %LevelTitle
@onready var complete_panel: PanelContainer = %CompletePanel
@onready var complete_label: Label = %CompleteLabel

var _egg_style_normal: StyleBoxFlat
var _egg_style_done: StyleBoxFlat
var _last_collected: int = 0
var _last_seconds: int = -1
var _low_time: bool = false
var _low_tween: Tween
var _bounce_tween: Tween
var _title_tween: Tween
var _complete_tween: Tween


func _ready() -> void:
	layer = 10
	margin.add_theme_constant_override("margin_left", screen_margin)
	margin.add_theme_constant_override("margin_right", screen_margin)
	margin.add_theme_constant_override("margin_top", screen_margin)
	margin.add_theme_constant_override("margin_bottom", screen_margin)

	_style_all()

	# pivot ตรงกลาง ให้ scale แล้วเด้งจากกลาง
	for c: Control in [egg_label, time_label, level_title, complete_panel, hint_button]:
		_center_pivot(c)
		c.resized.connect(_center_pivot.bind(c))

	hint_button.pressed.connect(_on_hint_pressed)
	hint_key_label.text = _hint_key_text()

	GameManager.egg_collected.connect(_on_egg_collected)
	GameManager.time_changed.connect(_on_time_changed)
	GameManager.hints_changed.connect(_on_hints_changed)
	GameManager.level_started.connect(_on_level_started)
	GameManager.level_completed.connect(_on_level_completed)

	# ---- ค่าเริ่มต้น: GameManager อาจส่ง signal ไปแล้วก่อน HUD โหลด ----
	_last_collected = GameManager.eggs_collected
	_on_egg_collected(GameManager.eggs_collected, GameManager.eggs_required)
	_on_hints_changed(GameManager.hints_left)
	clock_panel.visible = GameManager.has_timer
	if GameManager.has_timer:
		_on_time_changed(GameManager.time_left)
	level_title.modulate.a = 0.0
	complete_panel.hide()
	if GameManager.is_running:
		_show_level_title(GameManager.current_level)


# ============ สไตล์ ============

func _style_all() -> void:
	_egg_style_normal = _make_panel(cream, 24)
	_egg_style_done = _make_panel(mint, 24)
	egg_panel.add_theme_stylebox_override("panel", _egg_style_normal)
	clock_panel.add_theme_stylebox_override("panel", _make_panel(cream, 40))
	complete_panel.add_theme_stylebox_override("panel", _make_panel(cream, 36, 32))
	hint_badge.add_theme_stylebox_override("panel", _make_circle(pink, 4))

	_style_label(egg_label, counter_font_size)
	_style_label(time_label, clock_font_size)
	_style_label(hint_count_label, badge_font_size)
	_style_label(hint_key_label, key_font_size)
	hint_key_label.add_theme_color_override("font_color", Color.WHITE)
	hint_key_label.add_theme_color_override("font_outline_color", border_color)
	hint_key_label.add_theme_constant_override("outline_size", 8)
	_style_label(level_title, title_font_size)
	level_title.add_theme_color_override("font_color", cream)
	level_title.add_theme_color_override("font_outline_color", border_color)
	level_title.add_theme_constant_override("outline_size", 24)
	level_title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.4))
	level_title.add_theme_constant_override("shadow_offset_y", 6)
	_style_label(complete_label, complete_font_size)

	egg_icon.custom_minimum_size = Vector2.ONE * icon_size
	sun_icon.custom_minimum_size = Vector2.ONE * icon_size
	egg_icon.set("fill_color", pink)
	sun_icon.set("fill_color", Color("ffd54a"))

	hint_holder.custom_minimum_size = Vector2.ONE * hint_button_size
	_style_hint_button()


func _style_label(label: Label, font_size: int) -> void:
	if font:
		label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", text_color)


func _make_panel(color: Color, radius: int, pad: int = 14) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(color, panel_alpha)
	box.set_corner_radius_all(radius)
	box.set_border_width_all(4)
	box.border_color = border_color
	box.shadow_color = Color(0, 0, 0, 0.3)
	box.shadow_size = 6
	box.shadow_offset = Vector2(0, 4)
	box.content_margin_left = pad + 6
	box.content_margin_right = pad + 6
	box.content_margin_top = pad - 4
	box.content_margin_bottom = pad - 4
	return box


func _make_circle(color: Color, border: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(999)
	box.set_border_width_all(border)
	box.border_color = border_color
	box.shadow_color = Color(0, 0, 0, 0.3)
	box.shadow_size = 3
	box.shadow_offset = Vector2(0, 2)
	box.content_margin_left = 10
	box.content_margin_right = 10
	box.content_margin_top = 2
	box.content_margin_bottom = 2
	return box


func _style_hint_button() -> void:
	var normal := _make_circle(hint_color, 5)
	var hover := _make_circle(hint_color.lightened(0.25), 5)
	var pressed := _make_circle(hint_color.darkened(0.12), 5)
	var disabled := _make_circle(hint_disabled_color, 5)
	for box: StyleBoxFlat in [normal, hover, pressed, disabled]:
		box.shadow_size = 8
		box.shadow_offset = Vector2(0, 5)
		box.set_content_margin_all(0)
	pressed.shadow_size = 3
	pressed.shadow_offset = Vector2(0, 2)
	hint_button.add_theme_stylebox_override("normal", normal)
	hint_button.add_theme_stylebox_override("hover", hover)
	hint_button.add_theme_stylebox_override("pressed", pressed)
	hint_button.add_theme_stylebox_override("disabled", disabled)
	hint_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		hint_button.add_theme_color_override(state, text_color)
	hint_button.add_theme_color_override("font_disabled_color", Color("fff6e0"))
	if font:
		hint_button.add_theme_font_override("font", font)
	hint_button.add_theme_font_size_override("font_size", hint_font_size)
	hint_button.text = "HINT"
	# ไม่รับโฟกัส: กด Space/Enter ตอนเล่นจะได้ไม่ไปกดปุ่มนี้
	hint_button.focus_mode = Control.FOCUS_NONE

	hint_button.mouse_entered.connect(_on_hint_hover.bind(true))
	hint_button.mouse_exited.connect(_on_hint_hover.bind(false))


func _center_pivot(c: Control) -> void:
	c.pivot_offset = c.size / 2.0


func _on_hint_hover(hovered: bool) -> void:
	if hint_button.disabled and hovered:
		return
	var target := Vector2.ONE * (1.06 if hovered else 1.0)
	create_tween().tween_property(hint_button, "scale", target, 0.12) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# ============ ไข่ ============

func _on_egg_collected(collected: int, required: int) -> void:
	egg_label.text = "%d / %d" % [collected, required]
	var done := required > 0 and collected >= required
	egg_panel.add_theme_stylebox_override("panel", _egg_style_done if done else _egg_style_normal)
	if collected > _last_collected:
		_bounce_egg_label()
	_last_collected = collected


func _bounce_egg_label() -> void:
	if _bounce_tween:
		_bounce_tween.kill()
	egg_label.add_theme_color_override("font_color", gold)
	egg_label.scale = Vector2.ONE
	_bounce_tween = create_tween()
	_bounce_tween.tween_property(egg_label, "scale", Vector2.ONE * 1.4, 0.12) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_bounce_tween.tween_property(egg_label, "scale", Vector2.ONE, 0.2) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_bounce_tween.tween_interval(0.25)
	_bounce_tween.tween_callback(func() -> void: egg_label.add_theme_color_override("font_color", text_color))


# ============ นาฬิกา ============

func _on_time_changed(seconds_left: float) -> void:
	var secs := int(ceil(seconds_left))
	if secs != _last_seconds:
		_last_seconds = secs
		time_label.text = "%02d:%02d" % [secs / 60, secs % 60]
	_set_low_time(seconds_left < low_time_threshold)


func _set_low_time(low: bool) -> void:
	if low == _low_time:
		return
	_low_time = low
	if _low_tween:
		_low_tween.kill()
		_low_tween = null
	time_label.scale = Vector2.ONE
	time_label.modulate.a = 1.0
	if low:
		time_label.add_theme_color_override("font_color", danger_color)
		_low_tween = create_tween().set_loops()
		_low_tween.tween_property(time_label, "scale", Vector2.ONE * 1.15, 0.5) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_low_tween.parallel().tween_property(time_label, "modulate:a", 0.65, 0.5)
		_low_tween.tween_property(time_label, "scale", Vector2.ONE, 0.5) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_low_tween.parallel().tween_property(time_label, "modulate:a", 1.0, 0.5)
	else:
		time_label.add_theme_color_override("font_color", text_color)


# ============ Hint ============

func _on_hints_changed(hints_left: int) -> void:
	hint_count_label.text = str(hints_left)
	hint_button.disabled = hints_left <= 0
	hint_badge.modulate = Color(0.75, 0.75, 0.75) if hints_left <= 0 else Color.WHITE
	if hint_button.disabled:
		hint_button.scale = Vector2.ONE


func _on_hint_pressed() -> void:
	GameManager.use_hint()


## อ่านชื่อปุ่มของ action "hint" จาก InputMap จริง
## ถ้ายังไม่มี action นี้ GameManager ใช้ปุ่ม H สำรองอยู่ จึงแสดง [H] ให้ตรงกัน
func _hint_key_text() -> String:
	if InputMap.has_action("hint"):
		for event in InputMap.action_get_events("hint"):
			if event is InputEventKey:
				var key := event as InputEventKey
				var name_text := key.as_text_physical_keycode() if key.physical_keycode != KEY_NONE \
					else key.as_text_keycode()
				return "[%s]" % name_text.replace(" (Physical)", "")
		for event in InputMap.action_get_events("hint"):
			return "[%s]" % event.as_text()
	return "[H]"


# ============ ชื่อด่าน ============

func _on_level_started(level_index: int) -> void:
	# ด่านใหม่: รีเซ็ตสถานะ แล้วโชว์ชื่อ
	_last_collected = 0
	_last_seconds = -1
	complete_panel.hide()
	clock_panel.visible = GameManager.has_timer
	_set_low_time(false)
	_show_level_title(level_index)


func _show_level_title(level_index: int) -> void:
	if level_index < 0 or level_index >= level_names.size():
		return
	level_title.text = level_names[level_index]
	if _title_tween:
		_title_tween.kill()
	level_title.modulate.a = 0.0
	level_title.scale = Vector2.ONE * 0.8
	var fade_in := 0.3
	var fade_out := 0.5
	var hold := maxf(title_duration - fade_in - fade_out, 0.0)
	_title_tween = create_tween()
	_title_tween.tween_property(level_title, "modulate:a", 1.0, fade_in)
	_title_tween.parallel().tween_property(level_title, "scale", Vector2.ONE, fade_in) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_title_tween.tween_interval(hold)
	_title_tween.tween_property(level_title, "modulate:a", 0.0, fade_out)


# ============ ผ่านด่าน ============

func _on_level_completed(_level_index: int) -> void:
	if _title_tween:
		_title_tween.kill()
	level_title.modulate.a = 0.0
	# อนิเมชันต้องจบก่อน GameManager เปลี่ยนด่าน (NEXT_LEVEL_DELAY) ค้างไว้จนด่านเปลี่ยน
	var pop_time := minf(0.45, GameManager.NEXT_LEVEL_DELAY * 0.6)
	complete_panel.show()
	complete_panel.scale = Vector2.ZERO
	complete_panel.modulate.a = 0.0
	if _complete_tween:
		_complete_tween.kill()
	_complete_tween = create_tween().set_parallel()
	_complete_tween.tween_property(complete_panel, "scale", Vector2.ONE, pop_time) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_complete_tween.tween_property(complete_panel, "modulate:a", 1.0, pop_time * 0.5)
