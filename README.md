# Sistem Absensi SPG Berbasis Lokasi (Flutter + Node.js)

Repositori monorepo untuk sistem absensi SPG (Sales Promotion Girl/Boy) berbasis lokasi GPS dan validasi server-side.

## Struktur Direktori

```text
absensi_apk/
├── backend/            # Backend API (Node.js, Express, TypeScript, Prisma)
│   ├── prisma/         # Schema database Prisma
│   ├── src/            # Source code backend (routes, controllers, services, middlewares)
│   ├── .env.example    # Template environment variables
│   └── package.json    # Dependencies & scripts backend
├── mobile/             # Aplikasi Mobile (Flutter)
│   ├── lib/            # Source code Flutter
│   └── pubspec.yaml    # Dependencies Flutter
├── docs/               # Dokumentasi proyek & PRD
│   └── PRD.md          # Product Requirement Document
├── docker-compose.yml  # PostgreSQL database container setup
└── README.md
```

## Memulai Proyek

### 1. Database (PostgreSQL via Docker)
Pastikan Docker Desktop aktif, lalu jalankan:
```bash
docker compose up -d
```

### 2. Backend (Express + TypeScript + Prisma)
```bash
cd backend
npm install
npm run prisma:generate
npm run dev
```
Backend akan berjalan di `http://localhost:5000`. Health check dapat diakses di `http://localhost:5000/api/health`.

### 3. Mobile (Flutter)
```bash
cd mobile
flutter run
```
