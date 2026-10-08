# ด่าน find_Easter_eggs_in_garden — สวนอีสเตอร์ในป่า (low-poly)

ด่านค้นหาไข่อีสเตอร์ในสวนกลางป่าขนาดประมาณ 36×36 ม. มีกำแพงหินล้อมทั้ง 4 ด้าน มีสระน้ำเล็ก ๆ ตรงกลาง
ไข่ทั้งหมด 10 ใบ (ง่าย 3 / กลาง 4 / ยาก 3) เวลา 240 วินาที

> ทุกไฟล์ของด่านนี้อยู่ในโฟลเดอร์ `res://find_Easter_eggs_in_garden/` เท่านั้น ไม่ได้แก้ไฟล์ของเพื่อนเลย
> (player, egg, systems, levels, asset_nhoon ใช้แบบ instance / อ้าง path ตรง ๆ)

## วิธีเปิด

1. เปิดโปรเจกต์ใน Godot 4.7
2. เปิดไฟล์ `res://find_Easter_eggs_in_garden/find_Easter_eggs_in_garden.tscn`
3. กด **F6** (Run Current Scene) แล้วเล่นได้ทันที

ไฟล์ `scripts/*.gd.uid` ใส่มาให้แล้ว (Godot 4.4+ ใช้อ้างสคริปต์) ให้ commit ไปพร้อมกัน

## วิธีเล่น

| ปุ่ม | ทำอะไร |
|---|---|
| W A S D | เดิน |
| Shift | วิ่ง |
| Space | กระโดด (ต้องใช้กับไข่ใบที่ 10) |
| Ctrl | ย่อตัว |
| E / คลิกซ้าย | เล็งแล้วเก็บไข่ (ระยะ 2.5 ม. จากกล้อง) |
| H | ใช้ Hint — ไข่ที่ใกล้ที่สุดจะเด้งและเรืองแสง |
| P | หยุดชั่วคราว |
| ESC | ปล่อยเมาส์ |

- เริ่มที่ประตูทางเข้าฝั่งใต้ ภูติอีสเตอร์จะอธิบายภารกิจเป็นภาษาไทย
- ดาวสีทอง (Hint +1) ซ่อนไว้ 2 จุด: ในป่าสน และมุมตะวันออกเฉียงใต้ข้างลำธารแห้ง
- เก็บไข่ครบ 10 ใบก่อนหมดเวลา = ผ่านด่าน

## โซนในสวน

1. **ทางเข้า (ใต้)** — ซุ้มประตู ลานโล่ง มีพุ่มดอกไม้สองข้าง
2. **สระน้ำ + แปลงดอกไม้กลางสวน** — สระกลม ล้อมด้วยแปลงดอกไม้และทางเดินวงรอบ
3. **มุมป่าสน (ตะวันตกเฉียงเหนือ)** — ต้นสน 10 ต้น (Pine Trees by Quaternius)
4. **กองหินกับลำธารแห้ง (ตะวันออก)** — หินก้อนใหญ่ หินสูง และหินขั้นบันไดสำหรับกระโดด
5. **ลาน Walk in the Woods (ตะวันออกเฉียงเหนือ มุมในสุด)** — จุดไฮไลต์ เดินเข้าไปในป่าจิ๋วได้ (collision ตามรูปทรงจริง)
6. **สวนป่า** — ต้นไม้ low-poly 50 ต้น 5 ชนิด (โอ๊ก, เบิร์ช, ป็อปลาร์, เฟอร์, ซากุระชมพู) กลางสวนโปร่ง ไล่หนาแน่นขึ้นเรื่อย ๆ ไปทางกำแพง บังสายตาทำให้หาไข่ยากขึ้น
7. (เสริม) ทุ่งดอกไม้ฝั่งตะวันตก มีตอไม้ และ "ป่าจิ๋ว" Walk in the Woods ขนาดเล็กมุมตะวันตกเฉียงใต้

## ผังสวน (มองจากด้านบน, 1 ตัวอักษร = 1 ม. แนวนอน / 2 ม. แนวตั้ง)

```
            N (เหนือ, -Z)
   x=-18 ---------------------------- x=+18
   ######################################   z=-18
   ## Y   Y  T Y    Y  Y Y   Y 9       ##
   ##T YT     T  bY      Yb WWWWWWWWWY ##
   ##    Y T   Y Y         bWWWWWWWWW  ##   z=-12
   ##  T   h T  R  Y Y   Y  WWWWWWWWWY ##
   ##  Y  T ...T       Y    WWWWWWWWW  ##
   ##   T Y    .............3        Y ##   z=-6
   ##  Y     Y   ..**~~*6..    Y     ::##
   ##  R        2.*~~~~~~*..  Y  Y R:: ##
   ## Y    Y    ..*~~~~~~*..    R :::Y ##   z=+0
   ##    Y    .....**~~**.. ....  ::   ##
   ##   Y  ....   ........ Y   .. R 4  ##
   ## Y 5 ..   b     ..  Y       R: R  ##   z=+6
   ##   b  b Y       ..       Y   :: Y ##
   ##  b     7   Y  Y.. 1 Y   b   ::0  ##
   ##    www      b  ..@ b      Y  R:Y ##   z=+12
   ## Y  www     Y b S.  b R Y b  h :: ##
   ##8    Y   Y      ..   Y  b   Y   ::##
   ######################################   z=+18
            S (ใต้, +Z) — ทางเข้า
```

`#` กำแพง · `.` ทางเดิน · `~` สระน้ำ · `*` แปลงดอกไม้ · `:` ลำธารแห้ง · `T` ต้นสน · `Y` ต้นไม้ low-poly (สวนป่า) · `R` หิน · `b` พุ่มไม้ · `o` ตอไม้
`W` Walk in the Woods (ใหญ่) · `w` Walk in the Woods (จิ๋ว) · `S` จุดเกิด · `@` ภูติอีสเตอร์ · `h` ดาว Hint · `1`–`9`, `0` = ไข่ใบที่ 1–10

## จุดซ่อนไข่ทั้งหมด (10 ใบ)

พิกัดเป็นตำแหน่ง global ของ node ไข่ (x, y, z) หน่วยเมตร จุดเกิดผู้เล่นอยู่ที่ (0, 0, 15)

| # | node | ระดับ | พิกัด (x, y, z) | scale | สี | ซ่อนที่ไหน |
|---|---|---|---|---|---|---|
| 1 | Egg01_EntrancePath | ง่าย | (2.10, 0.00, 9.20) | 0.90 | `#FF8CBF` | ข้างทางเดินหลัก ถัดจากทางเข้า |
| 2 | Egg02_PondPath | ง่าย | (-5.25, 0.00, -1.00) | 0.90 | `#FFE04C` | บนทางเดินวงรอบสระน้ำ ฝั่งตะวันตก |
| 3 | Egg03_WoodsPath | ง่าย | (6.90, 0.00, -6.00) | 0.90 | `#73F2BF` | ปลายทางเดินก่อนถึงลาน Walk in the Woods |
| 4 | Egg04_BehindRock | กลาง | (14.75, 0.00, 3.95) | 0.80 | `#B280FF` | หลังหินก้อนใหญ่ ฝั่งลำธารแห้ง (ตะวันออก) |
| 5 | Egg05_UnderBush | กลาง | (-13.25, 0.00, 6.40) | 0.70 | `#80BFFF` | ใต้ชายพุ่มไม้ใหญ่ ทุ่งดอกไม้ฝั่งตะวันตก |
| 6 | Egg06_FlowerBed | กลาง | (2.38, 0.00, -3.83) | 0.70 | `#FF9940` | ในแปลงดอกไม้รอบสระน้ำ ฝั่งตะวันออกเฉียงเหนือ |
| 7 | Egg07_OnStump | กลาง | (-8.40, 0.82, 10.40) | 0.80 | `#FF6673` | บนตอไม้ ทุ่งดอกไม้ฝั่งตะวันตก |
| 8 | Egg08_WallNook | ยาก | (-16.15, 0.00, 16.15) | 0.65 | `#CCA6FF` | ซอกกำแพงหิน มุมตะวันตกเฉียงใต้ |
| 9 | Egg09_BehindWoods | ยาก | (10.00, 0.00, -16.05) | 0.70 | `#5999FF` | หลังลาน Walk in the Woods ชิดกำแพงเหนือ |
| 10 | Egg10_RockTop | ยาก | (14.36, 1.97, 10.25) | 0.80 | `#FFD133` | บนยอดหินสูงข้างลำธาร ต้องกระโดดขึ้นหินเตี้ยก่อน |

ทุกใบผ่านการทดสอบอัตโนมัติ: มีจุดยืนที่ capsule ของผู้เล่นวางได้จริง และ raycast จากกล้อง (สูง 1.03 ม.) ถึงไข่ในระยะ ≤ 2.5 ม. โดยไม่มีอะไรบัง
ไข่ใบที่ 10 เก็บจากพื้นไม่ได้ (ต้องกระโดดขึ้นหินเตี้ยสูง ~0.8 ม. ก่อน แล้วขึ้นหินสูง ~2 ม.)

## โครงสร้างไฟล์

```
find_Easter_eggs_in_garden/
├─ find_Easter_eggs_in_garden.tscn   ฉากหลัก (กด F6)
├─ README.md / EXPORT_WEB.md
├─ scripts/
│  ├─ glb_part.gd        ดึงโมเดล "ชิ้นเดียว" ออกจาก .glb ที่มีหลายโมเดล / รวม mesh ทั้งไฟล์ ("*") / สร้าง trimesh collision
│  ├─ part_multimesh.gd  วางโมเดลซ้ำด้วย MultiMesh (ดอกไม้ หญ้า หินแนวกำแพง หินขอบสระ)
│  └─ lowpoly_trees.gd   สร้างต้นไม้ low-poly 5 ชนิดจากรูปทรงพื้นฐาน (flat shading + vertex color, ไม่ใช้ไฟล์ asset)
└─ garden_props/         prop ที่ใส่ collision แล้ว ลากไปใช้ในด่านอื่นได้
   ├─ pine_grove.tscn    ต้นสน 10 ต้น + CylinderShape3D ทีละต้น
   ├─ rock_big / rock_tall / rock_mid / rock_round / rock_low.tscn  (Rocks by Quaternius + BoxShape3D)
   ├─ rock_small.tscn    (Rock by Quaternius)
   ├─ bush.tscn / bush_flowers.tscn / flower_bush.tscn  (Cylinder เล็ก ให้ไข่ซ่อนใต้ชายพุ่มได้)
   ├─ stump.tscn         ตอไม้สีล้วน
   └─ walk_in_the_woods.tscn  ไฮไลต์ รวม 119 mesh เป็น 1 + collision ตามรูปทรง
```

โครงสร้าง node ของฉากหลัก: `Garden` (level.gd, time_limit 240, eggs_required 0) → WorldEnvironment, Sun, Ground, Paths, DryCreek,
Walls (+ ซุ้มประตู), WallRocks, BackdropForest (ต้นสนนอกกำแพง ไม่มี collision), Landmarks, Pond, PondRim, Trees, Rocks,
Bushes (+ Stump), ForestTrees (ต้นไม้ 5 ชนิด + Collision ลำต้น 50 อัน), Flowers, Grass, Eggs, HintSpots, EasterSpirit, DevHUD, Player

**ทำไมต้องมี glb_part.gd:** ไฟล์ใน asset_nhoon หลายไฟล์มีหลายโมเดลวางเรียงห่างกันในไฟล์เดียว (เช่น Bushes.glb มี Plant_1 / Bush / Bush_Flowers อยู่ที่ x≈127–133)
และ Walk in the Woods มี 119 ชิ้นย่อย สคริปต์นี้ดึงเฉพาะชิ้นที่ต้องการมาไว้ที่จุดกำเนิด โดยไม่ต้องแก้ไฟล์ .glb และไม่ต้องเปิด editable children
mesh ที่สร้างไม่มี owner จึงไม่ถูกบันทึกลง .tscn (ไฟล์ไม่บวม) และเป็น `@tool` จึงเห็นใน editor ด้วย

## สวนป่า (ต้นไม้ 50 ต้น)

| ชนิด | จำนวน | สูงประมาณ | collision |
|---|---|---|---|
| oak (โอ๊ก ทรงพุ่มกลม) | 12 | 4.4 ม. | ลำต้น Cylinder r 0.3 |
| birch (เบิร์ช ลำต้นขาว) | 10 | 5.2 ม. | ลำต้น Cylinder r 0.2 |
| poplar (ป็อปลาร์ ทรงสูงเพรียว) | 8 | 5.3 ม. | Cylinder r 0.75 (พุ่มต่ำ) |
| fir (เฟอร์ ทรงกรวย 3 ชั้น) | 10 | 5.2 ม. | Cylinder r 0.95 (กิ่งถึงพื้น) |
| blossom (ซากุระชมพู ธีมอีสเตอร์) | 10 | 4.2 ม. | ลำต้น Cylinder r 0.3 |

- สร้างด้วย `scripts/lowpoly_trees.gd` จากรูปทรงพื้นฐาน (ทรงรี กระบอก กรวย) แบบ flat shading → **ไม่เพิ่มขนาดไฟล์ asset เลย** (สคริปต์ ~6 KB)
- วาดชนิดละ 1 MultiMesh (5 draw call สำหรับ 50 ต้น) ลำต้นอยู่ใน StaticBody3D เดียว
- จุดวาง: สุ่มแบบ seed คงที่ น้ำหนักความหนาแน่น ∝ ระยะจากกลางสวน (กลางสวน ~5%, ริมกำแพง ~100%) ไม่วางบนทางเดิน สระ ลำธาร ลาน Walk in the Woods
  ห่างไข่ทุกใบ ≥ 1.9 ม. ห่างกันเอง ≥ 2.3 ม. ห่างดาว Hint / จุดเกิด / หินกระโดด
- ทดสอบซ้ำหลังใส่ต้นไม้: flood-fill จากจุดเกิดยืนยันว่าเดินไปถึงจุดเก็บไข่ทุกใบได้ ไม่มีต้นไม้ปิดทาง
- ต้นสนนอกกำแพง **ไม่ต้องลด** เพราะขนาดรวมยังไม่เกิน 22 MB (และกลุ่มต้นสนทั้งหมดใช้ไฟล์ 0.1 MB ไฟล์เดียวกัน ลดจำนวนก็ไม่ลดขนาดไฟล์)

## การปรับแต่งที่ทำ (ตัดสินใจเอง)

- กำแพง: มองเห็นสูง 2.6 ม. แต่ collision สูง 8 ม. + เพดานใสที่ 8.25 ม. → กระโดดจากหินที่สูงที่สุด (~2 ม.) ยังข้ามไม่ได้
- สระน้ำมี collision ทรงกระบอกสูง 8 ม. (ผู้เล่นเดินลงน้ำ/ยืนบนน้ำไม่ได้)
- หินแนวกำแพง หินขอบสระ ดอกไม้ หญ้า ไม่มี collision (ใช้ MultiMesh) — กำแพง collision อยู่หน้าหินแนวกำแพงแล้ว
- สุ่มตำแหน่ง/หมุน/scale (0.85–1.2) ด้วย seed คงที่ 2026 ตอนสร้างฉาก ค่าจึงถูกบันทึกตายตัวใน .tscn ได้ผลเหมือนเดิมทุกครั้ง
- ไม่มี OmniLight เพิ่ม (มีแค่ไฟใน hint_spot ×2 และภูติ ×1 ของระบบเดิม)
- ไม่ใช้ SDFGI / SSAO / SSIL / VoxelGI / Volumetric Fog ใช้แค่ depth fog บาง ๆ ที่ Compatibility รองรับ

## Asset ที่ใช้ และขนาดไฟล์ (นับรวม dependency ทั้งหมดของฉาก)

ต้นไม้ 50 ต้นไม่ใช้ asset เพิ่ม ขนาดรวมจึงเพิ่มแค่สคริปต์ + ข้อมูลตำแหน่งในฉาก รายการนี้ได้จาก `ResourceLoader.get_dependencies()` แบบไล่ทุกชั้น + autoload GameManager

**ไฟล์ใหม่ (find_Easter_eggs_in_garden/)**

| ไฟล์ | ขนาด |
|---|---|
| EXPORT_WEB.md | 7.7 KB |
| README.md | 20.0 KB |
| find_Easter_eggs_in_garden.tscn | 78.9 KB |
| scripts/glb_part.gd | 3.6 KB |
| scripts/glb_part.gd.uid | 0.0 KB |
| scripts/lowpoly_trees.gd | 5.0 KB |
| scripts/lowpoly_trees.gd.uid | 0.0 KB |
| scripts/part_multimesh.gd | 1.3 KB |
| scripts/part_multimesh.gd.uid | 0.0 KB |
| garden_props/bush.tscn | 0.7 KB |
| garden_props/bush_flowers.tscn | 0.7 KB |
| garden_props/flower_bush.tscn | 0.7 KB |
| garden_props/pine_grove.tscn | 2.1 KB |
| garden_props/rock_big.tscn | 0.7 KB |
| garden_props/rock_low.tscn | 0.7 KB |
| garden_props/rock_mid.tscn | 0.7 KB |
| garden_props/rock_round.tscn | 0.7 KB |
| garden_props/rock_small.tscn | 0.7 KB |
| garden_props/rock_tall.tscn | 0.7 KB |
| garden_props/stump.tscn | 1.1 KB |
| garden_props/walk_in_the_woods.tscn | 0.5 KB |
| **รวม** | **126.7 KB** |

**asset_nhoon ที่ฉากอ้างถึง**

| ไฟล์ | ใช้ทำอะไร | ขนาด |
|---|---|---|
| Walk in the Woods by Don Carson - 38m6Q1H12DU.glb | ไฮไลต์ ×2 (รวม 119 mesh → 1) | 2.90 MB |
| Rocks by Quaternius - gYhoEOKItJ (1).glb | หินใหญ่ 5 แบบ + หินแนวกำแพง (ไฟล์ใหญ่ที่เลือกใช้ 1 ไฟล์) | 3.01 MB |
| Rocks by Quaternius - gYhoEOKItJ (1)_Rocks.png | texture ของ glb ด้านบน | 2.90 MB |
| Grass.glb | หญ้า MultiMesh | 0.73 MB |
| Grass_Grass.png | texture ของ glb ด้านบน | 0.70 MB |
| Bushes.glb | พุ่มไม้ | 0.45 MB |
| Bushes_Bush_Leaves.png | texture ของ glb ด้านบน | 0.07 MB |
| Bushes_Flowers.png | texture ของ glb ด้านบน | 0.30 MB |
| Flowers.glb | ดอกไม้ MultiMesh | 0.36 MB |
| Flowers_Flowers.png | texture ของ glb ด้านบน | 0.30 MB |
| Flower Bushes.glb | พุ่มดอกไม้ | 0.33 MB |
| Flower Bushes_Flowers.png | texture ของ glb ด้านบน | 0.30 MB |
| Pine Trees by Quaternius - oYtDty0fR6.glb | ต้นสน (ในสวน + นอกกำแพง) | 0.09 MB |
| Rock by Quaternius - RtLRqYjfMs.glb | หินเล็ก / ขอบสระ | 0.03 MB |
| **รวม** | | **12.48 MB** |

**ไฟล์ของเพื่อนที่ฉากใช้ (player / egg / systems / levels)**

| ไฟล์ | ขนาด |
|---|---|
| player/player.tscn | 4.9 KB |
| player/player.gd | 11.7 KB |
| player/Character_Animated.fbx | 4.06 MB |
| egg.tscn | 1.2 KB |
| systems/egg.gd | 7.3 KB |
| levels/level.gd | 0.8 KB |
| systems/game_manager.gd | 9.4 KB |
| systems/dev_hud.tscn | 3.0 KB |
| systems/dev_hud.gd | 3.2 KB |
| systems/hint_spot.tscn | 1.1 KB |
| systems/hint_spot.gd | 0.8 KB |
| systems/easter_spirit.tscn | 3.3 KB |
| systems/easter_spirit.gd | 6.7 KB |
| systems/fonts/NotoSansThai.ttf | 0.21 MB |
| **รวม** | **4.32 MB** |

**รวมทั้งหมด: 16.92 MB (17743024 bytes) — งบ 22 MB → เหลือ 5.08 MB** ✅

> หมายเหตุ: ขนาดนี้คือไฟล์ต้นฉบับ ตอน export Godot จะแปลง .glb/.png เป็นไฟล์ import ซึ่งอาจเล็กหรือใหญ่ขึ้นเล็กน้อย
> ไม่ได้ใช้ Birch / Maple / Trees / Dead Trees / Palm / Pine Trees.glb (ตัวใหญ่) และไม่ได้ใช้ asset_gam

## สถิติฉาก (นับตอนรันจริง)

- MeshInstance3D 96 ชิ้น + MultiMeshInstance3D 20 ชุด (รวมทั้งหมด ≈ 116 draw node, เป้าหมาย ≤ 150)
- Light: DirectionalLight3D 1 ดวง (shadow, max distance 40) + OmniLight ของระบบเดิม 3 ดวง

## Export Web

ดูขั้นตอนละเอียดใน [EXPORT_WEB.md](EXPORT_WEB.md) — สรุปสั้น ๆ:
Editor > Manage Export Templates (4.7) → Project > Export > Add **Web** → Resources: *Export selected scenes (and dependencies)* ติ๊กเฉพาะ
`find_Easter_eggs_in_garden.tscn` → ปิด Thread Support → export เป็น `index.html` → push ขึ้น GitHub Pages

## ฝากเพื่อน (เจ้าของ systems/)

ถ้าจะให้ด่านนี้อยู่ในลำดับเกม ต้องเพิ่ม path `res://find_Easter_eggs_in_garden/find_Easter_eggs_in_garden.tscn` ใน `LEVELS` ของ
`systems/game_manager.gd` (ไฟล์นี้ไม่ได้แก้ให้ ตามกติกาห้ามแตะ systems/) ระหว่างนี้กด F6 เล่นแยกได้ตามปกติ
