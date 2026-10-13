# สื่อการเรียนรู้บทเรียนคอมพิวเตอร์ช่วยสอน (CAI)
## รายวิชาวิทยาการคำนวณ (ว 42202) เรื่อง เทคโนโลยีความจริงเสริม (Augmented Reality)

ระบบสื่อการเรียนรู้แบบตอบโต้ผ่านเว็บ (Interactive Web-based CAI) ที่รวมเอาเทคโนโลยี **WebAR (Augmented Reality on Web)** เข้ากับระบบจัดการการเรียนรู้ (LMS) สมบูรณ์แบบ รองรับการยืนยันตัวตนนักเรียน การทำแบบทดสอบก่อน-หลังเรียน การคำนวณพัฒนาการเรียนรู้ ตลอดจนระบบตรวจงานและสรุปผลสำหรับผู้สอน

---

## 📌 คุณสมบัติสำคัญของระบบ (Key Features)

### 1. ระบบผู้เรียน (Student Portal)
* **การยืนยันตัวตนที่รัดกุม:** เข้าสู่ระบบด้วยรหัสนักศึกษา 11 หลัก โดยระบบจะตรวจสอบความถูกต้องกับรายชื่อนักเรียนในฐานข้อมูลก่อนอนุญาตให้สร้างบัญชี
* **เนื้อหาบทเรียน 5 หน่วยการเรียนรู้:**
  * **หน่วยที่ 1:** พื้นฐานความจริงเสริม (Azuma, 1997 / Milgram & Kishino, 1994)
  * **หน่วยที่ 2:** ชนิดและเทคโนโลยี AR (Marker vs Markerless, WebAR vs Native App)
  * **หน่วยที่ 3:** การออกแบบสื่อ AR เพื่อการเรียนรู้ (Mayer's Principles & Cognitive Load)
  * **หน่วยที่ 4:** ปฏิบัติการสร้าง WebAR ด้วย `<model-viewer>` v3.5.0 พร้อมเครื่องมือส่งงาน
  * **หน่วยที่ 5:** การทดสอบและประเมินสื่อ AR (IOC, $E_1/E_2$, Normalized Gain)
* **แบบทดสอบคู่ขนาน (Parallel Test Sets A/B):** ระบบสลับชุดข้อสอบ Pre-test และ Post-test ตามรหัสนักศึกษาเพื่อป้องกันการจำข้อสอบ
* **การวัดพัฒนาการด้วย Normalized Gain ($g$):** คำนวณค่าประสิทธิผลการเรียนรู้รายบุคคลตามแนวคิดของ Hake (1998)
* **ระบบจัดการโปรไฟล์:** อัปโหลดและย่อขนาดรูปภาพโปรไฟล์อัตโนมัติบนฝั่งผู้ใช้ (Client-side Canvas Resizing) ก่อนบันทึกลง Cloud Storage

### 2. ระบบผู้สอน (Teacher Management Dashboard)
* **ตารางสรุปผลการเรียนรายบุคคล:** แสดงสถานะการเข้าเรียน คะแนน Pre-test/Post-test และค่า Normalized Gain ($g$) แบบเรียลไทม์
* **ระบบตรวจงานปฏิบัติ AR:** ผู้สอนสามารถเปิดดูผลงาน (URL หรือ ไฟล์แนบ) ให้คะแนน และพิมพ์คำแนะนำตอบกลับนักเรียนได้
* **การจัดการสื่อการสอน:** เพิ่ม/ลบ สไลด์บรรยาย เอกสารประกอบ หรือวิดีโอ (รองรับไฟล์ PPTX, DOCX, PDF สูงสุด 50MB และลิงก์ภายนอก)
* **ส่งออกรายงาน CSV:** รองรับการ Export ข้อมูลคะแนนพร้อมรหัส UTF-8 BOM สำหรับเปิดใน Microsoft Excel ได้ภาษาไทยถูกต้อง ไม่แสดงฟอนต์ต่างดาว

---

## 📁 โครงสร้างไฟล์ในโครงการ (Project Structure)

```text
cai-ar-courseware/
├── courseware.html      # แพลตฟอร์มเว็บแอปพลิเคชันหลัก (Single-File SPA)
├── setup.sql            # สคริปต์สร้างฐานข้อมูล RLS, Trigger, View และ Storage บักเก็ต
└── README.md            # เอกสารอธิบายระบบและคู่มือการติดตั้ง
```

---

## 🛠️ ขั้นตอนการติดตั้งและตั้งค่าใช้งาน (Setup & Deployment)

### ขั้นตอนที่ 1: การตั้งค่า Supabase Backend
1. สมัครใช้งานและสร้าง Project ใหม่ที่ [Supabase.com](https://supabase.com)
2. ไปที่เมนู **SQL Editor** ใน Supabase Dashboard
3. คัดลอกเนื้อหาทั้งหมดในไฟล์ `setup.sql` วางลงใน SQL Editor แล้วกด **Run**
4. คำสั่ง SQL จะทำการสร้าง:
   * ตารางข้อมูล: `students`, `teachers`, `attempts`, `progress`, `submissions`, `materials`
   * ระบบรักษาความปลอดภัย: Row Level Security (RLS) และ Trigger สำหรับตรวจสอบรหัสนักศึกษา
   * มุมมองสรุปผล: `results` view
   * พื้นที่เก็บไฟล์ (Storage Buckets): `photos`, `submissions`, `materials`

### ขั้นตอนที่ 2: การแต่งตั้งบัญชีผู้สอน (Teacher Account)
1. เปิดไฟล์ `courseware.html` บนเบราว์เซอร์ และทำการสมัครสมาชิก/ลงทะเบียนผู้สอนด้วย **อีเมลอาจารย์** (เช่น `teacher@school.ac.th`)
2. เข้าไปที่ Supabase Dashboard -> **Authentication** -> **Users** แล้วคัดลอกค่า `User UID` (ค่า UUID) ของบัญชีผู้สอน
3. กลับไปที่ **SQL Editor** แล้วรันคำสั่งแต่งตั้งสิทธิ์ผู้สอน:
   ```sql
   insert into public.teachers (user_id) values ('ใส่-UUID-ของผู้สอนที่นี่');
   ```

### ขั้นตอนที่ 3: การเชื่อมต่อเว็บแอปพลิเคชันกับ Supabase
1. ไปที่ Supabase Dashboard -> **Project Settings** -> **API**
2. คัดลอกค่า **Project URL** และ **anon public key**
3. เปิดไฟล์ `courseware.html` ด้วย Code Editor แล้วแก้ไขส่วนต้นไฟล์:
   ```javascript
   const SUPABASE_URL = "https://your-project-id.supabase.co";
   const SUPABASE_ANON_KEY = "your-anon-public-key";
   ```

### ขั้นตอนที่ 4: การนำเข้ารายชื่อนักเรียน (Student Roster)
* ไฟล์ `setup.sql` มีข้อมูลตัวอย่างนักเรียน 6 คน (รหัส `66010000001` - `66010000006`)
* หากต้องการเพิ่มรายชื่อนักเรียนจริง สามารถนำเข้าไฟล์ CSV ได้ทาง Supabase Dashboard -> **Table Editor** -> เลือกตาราง `students` -> **Insert** -> **Import data from CSV** โดยต้องมีคอลัมน์:
  * `id` (รหัสนักศึกษา 11 หลัก)
  * `title` (คำนำหน้า)
  * `first_name` (ชื่อ)
  * `last_name` (นามสกุล)
  * `section` (กลุ่มเรียน)

---

## 📐 กรอบแนวคิดเชิงทฤษฎีและวิชาการที่ใช้ในบทเรียน

บทเรียน CAI ชุดนี้ได้รับการออกแบบโดยอ้างอิงหลักการและทฤษฎีทางเทคโนโลยีและนวัตกรรมการศึกษา ดังนี้:

1. **การกำหนดองค์ประกอบ AR (Azuma, 1997):**
   ผสานสิ่งจริงและสิ่งเสมือน (Combine real & virtual), ปฏิสัมพันธ์เรียลไทม์ (Interactive in real-time) และวางตำแหน่งในพิกัดสามมิติ (Registered in 3D)

2. **Reality-Virtuality Continuum (Milgram & Kishino, 1994):**
   การจัดวางตำแหน่งของ AR ให้อยู่ในกลุ่ม Mixed Reality (MR) ที่เน้นฐานข้อมูลสภาพแวดล้อมจริงเป็นหลัก

3. **หลักการออกแบบมัลติมีเดียทางการเรียนรู้ (Mayer's Multimedia Principles):**
   * **Spatial Contiguity Principle:** วางข้อความอธิบายประชิดกับวัตถุ 3D ที่เกี่ยวข้อง
   * **Coherence Principle:** ตัดส่วนประกอบที่ไม่จำเป็นออกเพื่อลดภาระทางปัญญา (Cognitive Load)
   * **Signaling Principle:** ใช้จุดเน้นหรือสีเพื่อดึงดูดสายตาผู้เรียนไปยังจุดสำคัญบนโมเดล 3D

4. **การตรวจสอบความเที่ยงตรงของสื่อและข้อสอบ (Rovinelli & Hambleton, 1977):**
   ใช้ดรรชนีความสอดคล้อง IOC (Index of Item-Objective Congruence) เกณฑ์ผ่าน $\text{IOC} \ge 0.50$

5. **การวัดพัฒนาการสัมบูรณ์ (Hake, 1998):**
   ใช้สูตร Normalized Gain ($g$) เพื่อวิเคราะห์อัตราความก้าวหน้าทางการเรียนรู้โดยขจัดอิทธิพลของความรู้เดิม:
   $$g = \frac{\%Post - \%Pre}{100\% - \%Pre} = \frac{Score_{post} - Score_{pre}}{FullScore - Score_{pre}}$$

   * **เกณฑ์การแปลผลระดับกลุ่ม (Hake, 1998):**
     * สูง (High gain): $g \ge 0.70$
     * ปานกลาง (Medium gain): $0.30 \le g < 0.70$
     * ต่ำ (Low gain): $g < 0.30$

---

## 💻 เทคโนโลยีที่ใช้ (Tech Stack)

* **Frontend:** HTML5, Tailwind CSS (CDN), Vanilla JavaScript (ES6+)
* **3D & WebAR Rendering:** Google `<model-viewer>` CDN v3.5.0
* **Backend & Database:** Supabase (PostgreSQL, Row Level Security, Storage, Auth, Edge Triggers)
* **Fonts:** Google Fonts (Sarabun)

---

## 📄 ใบอนุญาตและการนำไปใช้ (License)

สื่อการเรียนรู้ชุดนี้จัดทำขึ้นเพื่อประโยชน์ทางการศึกษาและการเรียนการสอน สามารถนำไปประยุกต์ ดัดแปลง หรือพัฒนาต่อยอดเพื่อการเรียนรู้ได้โดยไม่มีค่าใช้จ่าย