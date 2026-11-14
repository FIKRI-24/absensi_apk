import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function main() {
  console.log('[Seed] Seeding database...');

  // Clean up existing data (in reverse order of foreign keys)
  await prisma.attendance.deleteMany();
  await prisma.user.deleteMany();
  await prisma.outlet.deleteMany();

  // 1. Create Outlets (real coordinates in Jakarta)
  const outletGI = await prisma.outlet.create({
    data: {
      nama_toko: 'Grand Indonesia Mall',
      kode_outlet: 'OUT-GI-001',
      latitude: -6.19515,
      longitude: 106.82088,
      radius_meter: 100,
    },
  });

  const outletCP = await prisma.outlet.create({
    data: {
      nama_toko: 'Central Park Mall',
      kode_outlet: 'OUT-CP-002',
      latitude: -6.17743,
      longitude: 106.79075,
      radius_meter: 100,
    },
  });

  console.log(`[Seed] Created outlets: ${outletGI.nama_toko}, ${outletCP.nama_toko}`);

  // 2. Hash passwords
  const saltRounds = 10;
  const adminPasswordHash = await bcrypt.hash('admin123', saltRounds);
  const spgPasswordHash = await bcrypt.hash('spg123', saltRounds);

  // 3. Create Users (1 Admin, 2 SPG)
  const admin = await prisma.user.create({
    data: {
      nama: 'Admin HRD',
      kode_spg: 'ADM-001',
      username: 'admin',
      password_hash: adminPasswordHash,
      role: 'admin',
      outlet_id: null,
    },
  });

  const spg1 = await prisma.user.create({
    data: {
      nama: 'Siti Rahma',
      kode_spg: 'SPG-001',
      username: 'spg1',
      password_hash: spgPasswordHash,
      role: 'spg',
      outlet_id: outletGI.id,
    },
  });

  const spg2 = await prisma.user.create({
    data: {
      nama: 'Budi Santoso',
      kode_spg: 'SPG-002',
      username: 'spg2',
      password_hash: spgPasswordHash,
      role: 'spg',
      outlet_id: outletCP.id,
    },
  });

  console.log(
    `[Seed] Created users: ${admin.username} (admin), ${spg1.username} (spg), ${spg2.username} (spg)`
  );
  console.log('[Seed] Database seeding completed successfully.');
}

main()
  .catch((e) => {
    console.error('[Seed] Error during seeding:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
