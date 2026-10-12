extends RefCounted
## ตัวช่วยสร้างวัสดุของด่าน 2 (ใช้ผ่าน const U := preload("res://levels/level2/util.gd"))
## ไม่ใช้ไฟล์ภาพ: ลายทางสร้างจาก shader ในโค้ด

const STRIPE_CODE := """
shader_type spatial;
uniform vec4 color_a : source_color = vec4(0.95, 0.72, 0.86, 1.0);
uniform vec4 color_b : source_color = vec4(1.0, 0.96, 0.88, 1.0);
uniform float count = 8.0;
uniform bool radial = false;
varying vec3 local_pos;
void vertex() {
	local_pos = VERTEX;
}
void fragment() {
	float a = UV.x;
	if (radial) {
		a = atan(local_pos.x, local_pos.z) / 6.2831853 + 0.5;
	}
	float s = step(0.5, fract(a * count));
	ALBEDO = mix(color_a.rgb, color_b.rgb, s);
	ROUGHNESS = 0.85;
}
"""

static var _stripe_shader: Shader


static func flat(color: Color, emission_energy: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.85
	if emission_energy > 0.0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = emission_energy
	return m


static func stripes(color_a: Color, color_b: Color, count: float, radial: bool) -> ShaderMaterial:
	if _stripe_shader == null:
		_stripe_shader = Shader.new()
		_stripe_shader.code = STRIPE_CODE
	var m := ShaderMaterial.new()
	m.shader = _stripe_shader
	m.set_shader_parameter("color_a", color_a)
	m.set_shader_parameter("color_b", color_b)
	m.set_shader_parameter("count", count)
	m.set_shader_parameter("radial", radial)
	return m


## ปรับ font_size ของ Label3D ให้ข้อความอยู่ในกรอบ max_width x max_height (เมตร)
## ใช้ base_size เป็นขนาดสูงสุด ย่อลงเมื่อข้อความกว้าง/สูงเกินกรอบ
static func fit_label(label: Label3D, max_width: float, max_height: float, base_size: int) -> void:
	var font: Font = label.font if label.font != null else ThemeDB.fallback_font
	var ext: Vector2 = font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, base_size)
	var w: float = maxf(ext.x * label.pixel_size, 0.001)
	var h: float = maxf(ext.y * label.pixel_size, 0.001)
	var k: float = minf(1.0, minf(max_width / w, max_height / h))
	label.font_size = maxi(8, floori(base_size * k))
