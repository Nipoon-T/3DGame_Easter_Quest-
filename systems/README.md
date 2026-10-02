# systems/ — คู่มือใช้งานระบบเกม (เจ้าของ: ลภัสรดา คนที่ 2)

ทุกอย่างในโฟลเดอร์นี้ **ลากใส่ด่านแล้วใช้ได้เลย** ไม่ต้องแก้โค้ด
ถ้าอยากแก้ไฟล์ในโฟลเดอร์นี้ บอกลภัสรดาก่อนนะ

---

## 1. ตั้งค่าด่าน (เจ้าของด่านทุกคน)

1. node รากของด่านแปะ `res://levels/level.gd`
2. ตั้งใน Inspector:
   - `time_limit` = เวลาของด่าน (วินาที) — ใส่ `0` = ไม่จับเวลา (พื้นที่ลับ)
   - `eggs_required` = จำนวนไข่ที่ต้องเก็บ — ใส่ `0` = ต้องเก็บทุกใบในด่าน
3. instance `res://player/player.tscn` เข้าด่าน
4. ชื่อไฟล์ด่านต้องตรงกับ `LEVELS` ใน `game_manager.gd`
   (`level1_dark_room.tscn`, `level2_funfair.tscn`, `level3_secret_garden.tscn`)
5. ทดสอบ: เปิดไฟล์ด่านแล้วกด **F6** ได้เลย ไม่ต้องผ่านเมนู

## 2. ของที่ลากใส่ด่านได้

| ไฟล์ | ใช้ทำอะไร | ตั้งค่าใน Inspector |
|---|---|---|
| `egg.tscn` | ไข่ที่ต้องเก็บ (เล็งแล้วกด **E**) | `egg_color` สีไข่, `is_mystery` = ไข่ลับตอนจบ, `collect_sound` เสียงตอนเก็บ |
| `hint_spot.tscn` | ดาวสีทอง เดินชนแล้วได้ Hint +1 | `hint_amount` |
| `easter_spirit.tscn` | ภูติพูดอธิบายภารกิจตอนเริ่มด่าน | `intro_lines` บทพูดเอง (เว้นว่าง = ใช้บทตั้งต้นของด่านนั้น), ใช้ `{eggs}` `{time}` ในข้อความได้ |
| `dev_hud.tscn` | HUD ชั่วคราว: เวลา / ไข่ / Hint / Pause | — |

**ไข่:** ห้ามสร้างไข่เอง ให้ลาก `egg.tscn` เท่านั้น ย่อขยายได้ด้วย Scale (เช่น 0.5–0.6 สำหรับซ่อนบนชั้น)
**ไข่บนที่สูง:** ทดสอบว่ากระโดดถึง/เล็งถึงจริง (ระยะเก็บ 2.5 ม. วัดจากกล้อง)

## 3. ปุ่มที่ใช้ได้ตอนนี้

| ปุ่ม | ทำอะไร |
|---|---|
| E / คลิกซ้าย | เก็บไข่ |
| H | ใช้ Hint (ไข่ที่ใกล้ที่สุดจะเด้งและเรืองแสง) |
| P | หยุดชั่วคราว / เล่นต่อ |
| ESC | ปล่อยเมาส์ |

> H และ P เป็นปุ่มสำรอง — ถ้าคนที่ 1 เพิ่ม action `hint` / `pause` ใน Input Map แล้ว
> ระบบจะเปลี่ยนไปใช้ปุ่มที่ตั้งไว้ให้เอง

## 4. สำหรับ UI (คนที่ 3)

UI **ฟัง signal เท่านั้น** ไม่อ่านค่าจาก Player/ด่านโดยตรง

| Signal | ส่งค่า | ใช้ทำอะไร |
|---|---|---|
| `egg_collected` | `collected, required` | ตัวนับไข่ |
| `time_changed` | `seconds_left` | นาฬิกา |
| `hints_changed` | `hints_left` | จำนวน Hint |
| `level_started` | `level_index` | ชื่อด่าน |
| `level_completed` | `level_index` | "ผ่านด่าน!" |
| `game_won` / `game_lost` | – | เสียง/เอฟเฟกต์ก่อนเปลี่ยนหน้า |
| `paused_changed` | `is_paused` | โชว์/ซ่อนเมนู Pause |

ฟังก์ชันที่ปุ่มใน UI เรียกได้:

```gdscript
GameManager.start_new_game()   # ปุ่มเริ่มเกม
GameManager.use_hint()         # ปุ่ม Hint
GameManager.set_paused(false)  # ปุ่มเล่นต่อในเมนู Pause
GameManager.toggle_pause()     # สลับหยุด/เล่นต่อ
GameManager.retry_level()      # ปุ่มลองใหม่ (หน้าแพ้)
GameManager.selected_character = "leo"  # หน้าเลือกตัวละคร
```

- เมนู Pause ต้องตั้ง `process_mode = Always` ไม่งั้นกดปุ่มไม่ได้ตอนเกมหยุด
- HUD จริงให้ `add_to_group("hud")` แล้ว `dev_hud` จะซ่อนตัวเองอัตโนมัติ
- ฟอนต์ไทย: `systems/fonts/NotoSansThai.ttf` (ฟรี, OFL) ใช้กับ UI ทั้งเกมได้
- ยังขาด: `ui/win_screen.tscn`, `ui/lose_screen.tscn` (ระหว่างนี้แพ้แล้วระบบจะเริ่มด่านใหม่ให้เอง)

## 5. ค่าที่ปรับตอนบาลานซ์ (วันที่ 9) — ใน `game_manager.gd`

| ค่า | ตอนนี้ | ความหมาย |
|---|---|---|
| `START_HINTS` | 3 | Hint ตอนเริ่มเกม |
| `LEVEL_BONUS_HINTS` | `[0, 1, 2]` | Hint ที่ได้เพิ่มตอนเข้าแต่ละด่าน |
| `NEXT_LEVEL_DELAY` | 1.5 | วินาทีก่อนเปลี่ยนด่าน |

เวลาของแต่ละด่านปรับที่ `time_limit` ของด่านนั้น (Dark Room = 180 วินาที, ไข่ 8 ใบ)

## 6. ไฟล์อื่นในโฟลเดอร์นี้

- `game_manager.gd` — Autoload: นับไข่, Timer, Hint, Pause, ชนะ/แพ้, เปลี่ยนด่าน
- `flicker_light.gd` — แปะกับ Light3D ให้กะพริบแบบหลอดไฟเก่า
- `follow_player_light.gd` — แสงสลัวตามตัวผู้เล่น (ใช้ในห้องมืด)
