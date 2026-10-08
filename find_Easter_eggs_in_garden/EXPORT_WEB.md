# Export ด่าน find_Easter_eggs_in_garden เป็นเว็บ แล้วขึ้น GitHub Pages

> **ต้องทำเองใน Godot editor** — การเพิ่ม export preset จะสร้างไฟล์ `export_presets.cfg` ที่ root ของโปรเจกต์
> ซึ่งอยู่นอกโฟลเดอร์ `find_Easter_eggs_in_garden/` ที่ได้รับอนุญาตให้สร้างไฟล์ จึงไม่ได้สร้างไว้ให้

## 1. ติดตั้ง Web export template ของ Godot 4.7

1. เปิดโปรเจกต์ด้วย Godot **4.7** (เวอร์ชันเดียวกับ template)
2. เมนู **Editor > Manage Export Templates…**
3. กด **Download and Install** (ต้องต่อเน็ต) — หรือดาวน์โหลดไฟล์ `Godot_v4.7-stable_export_templates.tpz` จากหน้า Download ของ godotengine.org แล้วกด **Install from File**
4. รอจนขึ้นว่า installed สำหรับ 4.7.stable

## 2. เพิ่ม preset Web

1. เมนู **Project > Export…**
2. กด **Add…** แล้วเลือก **Web**
3. ตั้งชื่อ preset เช่น `Web (Garden)`

## 3. Resources — export เฉพาะฉากนี้

1. ในแท็บ **Resources** ตั้ง **Export Mode** = **Export selected scenes (and dependencies)**
2. ในรายการไฟล์ ติ๊กเฉพาะ `find_Easter_eggs_in_garden/find_Easter_eggs_in_garden.tscn`
   - Godot จะดึง dependency ให้เอง (player, egg, systems, asset_nhoon ที่ฉากใช้ และ autoload GameManager)
   - asset_gam และโมเดลใหญ่ที่ไม่ได้ใช้ใน asset_nhoon จะไม่ถูกรวม → ขนาด .pck ไม่บวม (asset ที่ฉากใช้รวม ≈ 17 MB)
3. แท็บ **Options**:
   - **Variant > Thread Support** = **ปิด (off)** ← สำคัญ GitHub Pages ส่ง header COOP/COEP ไม่ได้ ถ้าเปิดจะโหลดไม่ขึ้น
   - **VRAM Texture Compression > For Desktop** = เปิด (ค่าเริ่มต้น)
   - **HTML > Export Icon** เปิดได้ตามต้องการ
4. renderer: เว็บใช้ **Compatibility** อัตโนมัติ (`rendering_method.web = gl_compatibility`) ไม่ต้องตั้งเพิ่ม ฉากนี้ออกแบบให้ใช้ได้กับ Compatibility แล้ว

## 4. ตั้ง main scene ตอน export

ตอนนี้ main scene ของโปรเจกต์คือเมนูหลักของเกม ถ้าจะ export **เฉพาะด่านนี้** ให้หน้าเว็บเปิดมาที่ด่านสวนเลย เลือกวิธีใดวิธีหนึ่ง:

**วิธี A — ใช้ feature tag (ไม่กระทบตอนเล่นบนเครื่อง)**
1. ใน export preset แท็บ **Features** ช่อง **Custom** ใส่ `garden`
2. **Project > Project Settings > Application > Run > Main Scene** กดปุ่ม ⟳/➕ ข้างค่า (Add override) เลือก feature `garden`
3. ตั้งค่า override = `res://find_Easter_eggs_in_garden/find_Easter_eggs_in_garden.tscn`
   (จะได้บรรทัด `run/main_scene.garden=...` ใน project.godot — ให้ตกลงกับเพื่อนก่อน เพราะเป็นไฟล์ส่วนกลาง)

**วิธี B — export แยกชั่วคราว**
1. เปลี่ยน **Main Scene** เป็นไฟล์ด่านสวนชั่วคราว
2. export (ข้อ 5)
3. เปลี่ยน Main Scene กลับเป็นค่าเดิม **ก่อน commit** (ห้าม commit project.godot ที่เปลี่ยน main scene)

> ถ้าเวอร์ชันที่ใช้อยู่มีช่องเลือก main scene แยกใน export preset ใช้ช่องนั้นได้เลย

**วิธี C — ใส่ในเกมจริง:** ให้เจ้าของ `systems/game_manager.gd` เพิ่มด่านนี้ใน `LEVELS` แล้ว export ทั้งเกมตามปกติ (ติ๊กฉากเมนูหลักด้วย)

## 5. Export

1. กด **Export Project…** (ไม่ใช่ Export PCK/ZIP)
2. สร้างโฟลเดอร์ปลายทาง **นอก** โฟลเดอร์ด่าน เช่น `build/web/` ที่ root ของ repo
3. ตั้งชื่อไฟล์เป็น **`index.html`** (GitHub Pages เปิดไฟล์ชื่อนี้อัตโนมัติ)
4. ปิด **Export With Debug** สำหรับเวอร์ชันจริง แล้วกด Save
5. จะได้ไฟล์ประมาณ: `index.html`, `index.js`, `index.wasm` (~35–40 MB), `index.pck`, `index.png`, `index.audio.worklet.js` … ทุกไฟล์ต่ำกว่า 50 MB

ทดสอบบนเครื่องก่อน: ใน editor กดปุ่ม **Remote Debug > Run in Browser** (ไอคอนเว็บมุมขวาบน) หรือ
`python -m http.server 8000` ในโฟลเดอร์ build/web แล้วเปิด http://localhost:8000
(เปิดไฟล์ index.html ด้วยดับเบิลคลิกตรง ๆ จะไม่ทำงาน)

## 6. ขึ้น GitHub Pages

**แบบง่าย (branch แยก `gh-pages`)**
```bash
# ที่ root ของ repo หลัง export เสร็จ
cd build/web
touch .nojekyll                 # กัน Jekyll ข้ามไฟล์บางชื่อ
git init -b gh-pages
git add .
git commit -m "Web build: find_Easter_eggs_in_garden"
git remote add origin https://github.com/<ชื่อผู้ใช้>/3DGame_Easter_Quest-.git
git push -f origin gh-pages
```
แล้วไปที่ GitHub repo > **Settings > Pages** > Source = **Deploy from a branch** > Branch = `gh-pages` / `(root)` > Save
รอ 1–2 นาที จะได้ลิงก์ `https://<ชื่อผู้ใช้>.github.io/3DGame_Easter_Quest-/`

**แบบโฟลเดอร์ docs/** (ถ้าไม่อยากมี branch แยก): export ลง `docs/` ที่ root แล้ว push ตามปกติ
จากนั้น Settings > Pages > Branch = `main` / `/docs` (ให้ทีมตกลงกันก่อน เพราะเป็นโฟลเดอร์ใหม่ที่ root)

## เช็กลิสต์ถ้าเปิดเว็บแล้วไม่ขึ้น

- จอดำ / error เรื่อง SharedArrayBuffer → ลืมปิด **Thread Support**
- 404 → ชื่อไฟล์ไม่ใช่ `index.html` หรือ Pages ชี้ผิดโฟลเดอร์
- ไฟล์หาย/โมเดลหาย → path ตัวพิมพ์เล็ก-ใหญ่ไม่ตรง (เซิร์ฟเวอร์ Linux แยกตัวพิมพ์) หรือไม่ได้ติ๊กฉากใน Resources
- เมาส์ไม่ล็อก → คลิกในหน้าเกมหนึ่งครั้งก่อน (เบราว์เซอร์บังคับ)
- ช้า → ปิดแท็บอื่น ฉากนี้ใช้ MeshInstance ≈ 100 ชิ้น, ไม่มี GI/SSAO, เงาแค่ DirectionalLight เดียว
