# PRD: Sistem Absensi SPG Berbasis Lokasi (Flutter + Node.js)

**Versi:** 1.0  
**Status:** Draft untuk eksekusi AI Agent (Claude Code / Antigravity)  
**Menggantikan:** Aplikasi App Inventor "ABSENSI SPG" (legacy)

---

## 1. Latar Belakang
Aplikasi absensi SPG saat ini dibuat dengan MIT App Inventor dan memiliki kelemahan serius: password dikirim polos di URL, validasi jarak hanya di sisi klien (rentan fake GPS), jam device dipakai sebagai acuan waktu, dan tidak ada kontrol source code yang jelas (sertifikat generik App Inventor). Proyek ini membangun ulang sistem dengan arsitektur client-server yang proper: **Flutter** untuk aplikasi mobile dan **Node.js (Express)** untuk backend API.

---

## 2. Tujuan Produk
1. SPG dapat login, melihat data toko tempat bertugas, dan melakukan absen datang/pulang berbasis lokasi GPS.
2. Validasi radius lokasi dan waktu absen dilakukan **di server**, bukan di device, untuk mencegah manipulasi.
3. Password dan data sensitif dikirim terenkripsi (HTTPS) dan disimpan ter-hash.
4. Admin/HRD dapat melihat laporan absensi semua SPG dari dashboard.
5. Sistem mudah dipelihara, source code sepenuhnya dimiliki perusahaan.

---

## 3. Target Pengguna
- **SPG (Sales Promotion Girl/Boy):** pengguna utama aplikasi mobile, absen datang/pulang di toko tempat bertugas.
- **Admin/HRD:** memantau laporan absensi, mengelola data SPG dan outlet.

---

## 4. Lingkup (Scope)

### Termasuk (In Scope)
- Autentikasi (login) SPG dengan JWT.
- Ambil data outlet/toko milik SPG yang login (termasuk koordinat & radius).
- Ambil waktu server (agar tidak bergantung jam device).
- Hitung jarak device ke toko dengan formula **Haversine** (bukan Euclidean seperti versi lama).
- Absen datang & pulang dengan dialog konfirmasi (Ya/Tidak), ditolak server jika di luar radius.
- Deteksi indikasi mock/fake GPS location di device, ditolak di server jika terdeteksi.
- Riwayat absensi per SPG (lihat di app).
- Dashboard web sederhana untuk admin (lihat laporan, kelola outlet & user) — opsional, fase akhir.

### Tidak Termasuk (Out of Scope, untuk versi awal)
- Verifikasi wajah/selfie (ditandai sebagai *future enhancement*, lihat §8).
- Integrasi payroll otomatis.
- Multi-tenant / multi-perusahaan.

---

## 5. Spesifikasi Fungsional

### 5.1 Autentikasi
- `POST /api/auth/login` — body `{ username, password }` → validasi bcrypt hash → balas JWT (access token, masa berlaku pendek, misal 8 jam) + data profil SPG.
- Semua endpoint selain login & health-check wajib header `Authorization: Bearer <token>`.

### 5.2 Data Outlet/Toko
- `GET /api/outlet/me` — ambil outlet yang ditugaskan ke SPG yang login: `nama toko`, `kode outlet`, `latitude`, `longitude`, `radius_meter`.
- `GET /api/server-time` — balas waktu server (UTC + offset WIB) sebagai acuan waktu absen, bukan waktu device.

### 5.3 Absensi
- `POST /api/attendance/checkin`
  - Body: `{ latitude, longitude, accuracy, mock_location_detected, foto_base64? }`
  - Server: hitung jarak Haversine ke outlet SPG; jika `> radius_meter` → tolak (`403`, pesan jarak aktual); jika `mock_location_detected=true` → tolak; jika user sudah absen datang hari ini → tolak (cegah duplikat); jika valid → simpan record dengan `waktu_server` (bukan dari body), status `hadir`.
- `POST /api/attendance/checkout` — pola sama, jenis `pulang`, syarat sudah checkin hari itu.
- `GET /api/attendance/history?from=&to=` — riwayat absensi SPG yang login.

### 5.4 Admin (fase akhir)
- `GET /api/admin/attendance?outlet_id=&date=` — laporan absensi lintas SPG (role admin saja, middleware RBAC).
- `POST /api/admin/outlet`, `PUT /api/admin/outlet/:id` — kelola data toko.
- `POST /api/admin/user` — kelola akun SPG.

---

## 6. Skema Database (PostgreSQL)

```sql
users (
  id SERIAL PRIMARY KEY,
  nama VARCHAR(100) NOT NULL,
  kode_spg VARCHAR(20) UNIQUE NOT NULL,
  username VARCHAR(50) UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  outlet_id INT REFERENCES outlets(id),
  role VARCHAR(20) DEFAULT 'spg', -- 'spg' | 'admin'
  created_at TIMESTAMP DEFAULT now()
)

outlets (
  id SERIAL PRIMARY KEY,
  nama_toko VARCHAR(100) NOT NULL,
  kode_outlet VARCHAR(20) UNIQUE NOT NULL,
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  radius_meter INT DEFAULT 100
)

attendances (
  id SERIAL PRIMARY KEY,
  user_id INT REFERENCES users(id),
  outlet_id INT REFERENCES outlets(id),
  jenis VARCHAR(10) NOT NULL, -- 'masuk' | 'pulang'
  waktu_server TIMESTAMP NOT NULL,
  lat_device DOUBLE PRECISION,
  long_device DOUBLE PRECISION,
  jarak_meter DOUBLE PRECISION,
  mock_location_detected BOOLEAN DEFAULT false,
  foto_url TEXT,
  status VARCHAR(20) DEFAULT 'valid',
  created_at TIMESTAMP DEFAULT now()
)
```

---

## 7. Arsitektur Teknis
- **Backend:** Node.js + Express, struktur layer (routes → controller → service → model), ORM: Prisma atau Sequelize.
- **Database:** PostgreSQL, dipakai sama persis di local (via Docker) dan production.
- **Auth:** JWT (`jsonwebtoken`) + `bcrypt` untuk hash password.
- **Validasi input:** `zod` atau `joi`.
- **Mobile:** Flutter, state management Provider/Riverpod, package `geolocator` (GPS + deteksi mock location), `dio` (HTTP client), `flutter_secure_storage` (simpan token).
- **Komunikasi:** REST API via HTTPS (wajib, bukan HTTP polos seperti versi lama).
- **Hosting (saran):** VPS/Railway/Render untuk backend; Flutter build APK untuk distribusi internal.

---

## 8. Future Enhancements (tidak di fase awal)
- Verifikasi foto selfie saat absen (face match).
- Notifikasi push (absen lupa, reminder).
- Dashboard analitik kehadiran per periode.
- Geofencing otomatis (reminder saat SPG masuk radius toko).

---

## 9. Kriteria Sukses
- Password tidak pernah terlihat dalam bentuk plain text di request/log.
- Absen di luar radius toko **selalu ditolak oleh server**, walau device dimodifikasi.
- Waktu absen tercatat memakai jam server, terbukti tidak berubah meski jam HP diubah manual.
- Source code backend & mobile sepenuhnya ada di repository milik perusahaan (Git).

---

## Fase Eksekusi untuk AI Agent (Claude Code / Antigravity)

### Fase 0 — Setup Proyek
- Inisialisasi repo Git dengan struktur monorepo: `/backend` dan `/mobile`.
- `/backend`: inisialisasi Node.js + Express + TypeScript (opsional tapi disarankan), ESLint/Prettier, `.env.example`.
- `/mobile`: inisialisasi project Flutter baru (`flutter create mobile`).
- Setup PostgreSQL lokal (`docker-compose`) + Prisma schema awal sesuai §6.
- **Output fase ini:** project berjalan (`npm run dev` backend hidup, `flutter run` menampilkan halaman default), database terkoneksi.

### Fase 1 — Backend: Auth & Model Dasar
- Implementasi model `users`, `outlets`, `attendances` via Prisma migration.
- Endpoint `POST /api/auth/login` (bcrypt compare + JWT sign).
- Middleware `authenticateJWT` dan `requireRole(role)`.
- Seed data dummy: 1 admin, 2 SPG, 2 outlet dengan koordinat nyata.
- **Output:** bisa login via Postman/curl dan dapat token valid; endpoint terproteksi menolak request tanpa token.

### Fase 2 — Backend: Outlet & Server Time
- Endpoint `GET /api/outlet/me`.
- Endpoint `GET /api/server-time`.
- Unit test dasar (Jest) untuk kedua endpoint.
- **Output:** SPG yang login bisa ambil data outlet-nya sendiri saja (tidak bisa lihat outlet SPG lain).

### Fase 3 — Backend: Logika Absensi (Inti)
- Implementasi fungsi `calculateHaversineDistance(lat1, lon1, lat2, lon2)` sebagai util terpisah + unit test dengan beberapa kasus koordinat nyata.
- Endpoint `POST /api/attendance/checkin` dengan semua validasi (radius, mock location, duplikat harian), memakai `waktu_server` dari `Date.now()` server, bukan input client.
- Endpoint `POST /api/attendance/checkout` dengan pola sama.
- Endpoint `GET /api/attendance/history`.
- **Output:** test memastikan absen di luar radius ditolak, absen di dalam radius tercatat benar, jam yang tersimpan adalah jam server.

### Fase 4 — Mobile: Autentikasi & Struktur Dasar
- Setup `dio` client dengan interceptor (attach JWT otomatis), `flutter_secure_storage` untuk simpan token.
- Halaman Login (form username/password) → panggil `/api/auth/login` → simpan token → navigasi ke Home.
- State management dasar (Riverpod/Provider) untuk auth state.
- **Output:** login berhasil dari app, token tersimpan, logout berfungsi.

### Fase 5 — Mobile: Lokasi & Tampilan Toko
- Request permission lokasi (`geolocator`), tampilkan koordinat device & nama toko dari `/api/outlet/me`.
- Hitung & tampilkan estimasi jarak di UI (opsional, hanya informatif — validasi final tetap di server).
- Deteksi mock location (`geolocator` `Position.isMocked` atau setara) dan kirim flag ini ke server saat absen.
- **Output:** halaman utama menampilkan jarak user ke toko secara real-time.

### Fase 6 — Mobile: Alur Absen Datang/Pulang
- Tombol "Absen Datang" & "Absen Pulang" dengan dialog konfirmasi Ya/Tidak (mempertahankan UX lama yang sudah baik).
- Kirim request ke `/api/attendance/checkin` atau `/checkout` dengan lokasi + flag mock location.
- Tampilkan pesan sukses/gagal sesuai respons server (termasuk pesan jarak jika ditolak).
- Tampilkan riwayat absensi (list dari `/api/attendance/history`).
- **Output:** alur end-to-end absen datang/pulang berfungsi penuh dari app ke database.

### Fase 7 — Hardening & Keamanan
- Pastikan semua komunikasi lewat HTTPS (dokumentasikan setup SSL di deployment).
- Rate limiting pada endpoint login (`express-rate-limit`).
- Validasi input ketat di semua endpoint (`zod`/`joi`).
- Audit log sederhana untuk percobaan absen yang ditolak (untuk investigasi kecurangan).
- **Output:** checklist keamanan terpenuhi, tidak ada data sensitif di log.

### Fase 8 — Dashboard Admin (Opsional, Fase Akhir)
- Endpoint admin sesuai §5.4.
- Web sederhana (React atau server-rendered) untuk HRD melihat laporan kehadiran per outlet/tanggal.
- **Output:** HRD bisa melihat rekap kehadiran tanpa akses langsung ke database.

### Fase 9 — Deployment
- Dockerize backend, setup CI sederhana (GitHub Actions: lint + test on push).
- Deploy backend ke VPS/Railway/Render dengan environment variable aman (`.env` tidak di-commit).
- Build APK Flutter release (`flutter build apk --release`) dengan keystore milik perusahaan sendiri (bukan sertifikat generik seperti App Inventor).
- **Output:** sistem dapat diakses end-to-end di lingkungan produksi/staging.
