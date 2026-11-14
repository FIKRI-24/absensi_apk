-- CreateTable
CREATE TABLE "users" (
    "id" SERIAL NOT NULL,
    "nama" VARCHAR(100) NOT NULL,
    "kode_spg" VARCHAR(20) NOT NULL,
    "username" VARCHAR(50) NOT NULL,
    "password_hash" TEXT NOT NULL,
    "outlet_id" INTEGER,
    "role" VARCHAR(20) NOT NULL DEFAULT 'spg',
    "created_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "outlets" (
    "id" SERIAL NOT NULL,
    "nama_toko" VARCHAR(100) NOT NULL,
    "kode_outlet" VARCHAR(20) NOT NULL,
    "latitude" DOUBLE PRECISION NOT NULL,
    "longitude" DOUBLE PRECISION NOT NULL,
    "radius_meter" INTEGER NOT NULL DEFAULT 100,

    CONSTRAINT "outlets_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "attendances" (
    "id" SERIAL NOT NULL,
    "user_id" INTEGER NOT NULL,
    "outlet_id" INTEGER NOT NULL,
    "jenis" VARCHAR(10) NOT NULL,
    "waktu_server" TIMESTAMP(6) NOT NULL,
    "lat_device" DOUBLE PRECISION,
    "long_device" DOUBLE PRECISION,
    "jarak_meter" DOUBLE PRECISION,
    "mock_location_detected" BOOLEAN NOT NULL DEFAULT false,
    "foto_url" TEXT,
    "status" VARCHAR(20) NOT NULL DEFAULT 'valid',
    "created_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "attendances_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "users_kode_spg_key" ON "users"("kode_spg");

-- CreateIndex
CREATE UNIQUE INDEX "users_username_key" ON "users"("username");

-- CreateIndex
CREATE UNIQUE INDEX "outlets_kode_outlet_key" ON "outlets"("kode_outlet");

-- AddForeignKey
ALTER TABLE "users" ADD CONSTRAINT "users_outlet_id_fkey" FOREIGN KEY ("outlet_id") REFERENCES "outlets"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "attendances" ADD CONSTRAINT "attendances_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "attendances" ADD CONSTRAINT "attendances_outlet_id_fkey" FOREIGN KEY ("outlet_id") REFERENCES "outlets"("id") ON DELETE CASCADE ON UPDATE CASCADE;
