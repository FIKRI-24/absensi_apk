import request from 'supertest';
import app from '../src/app';
import prisma from '../src/config/database';

// Koordinat di dalam radius Grand Indonesia (outlet spg1)
const VALID_COORDS = {
  latitude: -6.19515,
  longitude: 106.82088,
  accuracy: 10,
  mock_location_detected: false,
};

// Koordinat sangat jauh (Surabaya)
const FAR_COORDS = {
  latitude: -7.25,
  longitude: 112.75,
  accuracy: 10,
  mock_location_detected: false,
};

describe('Attendance Endpoints (/api/attendance)', () => {
  let spg1Token: string;
  let spg2Token: string;
  let spg1Id: number;

  beforeAll(async () => {
    // Login sebagai spg1 (outlet Grand Indonesia)
    const loginSpg1 = await request(app).post('/api/auth/login').send({
      username: 'spg1',
      password: 'spg123',
    });
    spg1Token = loginSpg1.body.data.token;
    spg1Id = loginSpg1.body.data.user.id;

    // Login sebagai spg2 (outlet Central Park) - untuk test "belum checkin"
    const loginSpg2 = await request(app).post('/api/auth/login').send({
      username: 'spg2',
      password: 'spg123',
    });
    spg2Token = loginSpg2.body.data.token;
  });

  afterAll(async () => {
    // Cleanup: hapus semua record attendance SPG 1 yang dibuat saat test
    await prisma.attendance.deleteMany({ where: { user_id: spg1Id } });
    await prisma.$disconnect();
  });

  // ─────────────────────────────────────────────────────────────
  // POST /api/attendance/checkin
  // ─────────────────────────────────────────────────────────────
  describe('POST /api/attendance/checkin', () => {
    it('harus menolak request tanpa token (401)', async () => {
      const res = await request(app).post('/api/attendance/checkin').send(VALID_COORDS);
      expect(res.status).toBe(401);
      expect(res.body.success).toBe(false);
    });

    it('harus menolak koordinat di luar radius dengan pesan jarak (403)', async () => {
      const res = await request(app)
        .post('/api/attendance/checkin')
        .set('Authorization', `Bearer ${spg1Token}`)
        .send(FAR_COORDS);

      expect(res.status).toBe(403);
      expect(res.body.success).toBe(false);
      expect(res.body.message).toContain('meter dari toko');
    });

    it('harus menolak jika mock_location_detected = true (403)', async () => {
      const res = await request(app)
        .post('/api/attendance/checkin')
        .set('Authorization', `Bearer ${spg1Token}`)
        .send({
          ...VALID_COORDS,
          mock_location_detected: true,
        });

      expect(res.status).toBe(403);
      expect(res.body.success).toBe(false);
      expect(res.body.message).toContain('lokasi palsu');
    });

    it('harus berhasil checkin dengan koordinat valid (201)', async () => {
      const res = await request(app)
        .post('/api/attendance/checkin')
        .set('Authorization', `Bearer ${spg1Token}`)
        .send(VALID_COORDS);

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.message).toContain('Absen datang berhasil dicatat');
      expect(res.body.data).toBeDefined();
      expect(res.body.data.jenis).toBe('masuk');
    });

    it('harus menolak checkin kedua kali di hari yang sama (409)', async () => {
      const res = await request(app)
        .post('/api/attendance/checkin')
        .set('Authorization', `Bearer ${spg1Token}`)
        .send(VALID_COORDS);

      expect(res.status).toBe(409);
      expect(res.body.success).toBe(false);
      expect(res.body.message).toContain('sudah melakukan absen datang');
    });
  });

  // ─────────────────────────────────────────────────────────────
  // POST /api/attendance/checkout
  // ─────────────────────────────────────────────────────────────
  describe('POST /api/attendance/checkout', () => {
    it('harus menolak checkout jika belum checkin (400) - menggunakan spg2', async () => {
      // Koordinat di dalam radius Central Park (outlet spg2)
      const centralParkCoords = {
        latitude: -6.17743,
        longitude: 106.79075,
        accuracy: 10,
        mock_location_detected: false,
      };

      const res = await request(app)
        .post('/api/attendance/checkout')
        .set('Authorization', `Bearer ${spg2Token}`)
        .send(centralParkCoords);

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
      expect(res.body.message).toContain('belum melakukan absen datang');
    });

    it('harus berhasil checkout setelah checkin (201) - menggunakan spg1', async () => {
      const res = await request(app)
        .post('/api/attendance/checkout')
        .set('Authorization', `Bearer ${spg1Token}`)
        .send(VALID_COORDS);

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.message).toContain('Absen pulang berhasil dicatat');
      expect(res.body.data).toBeDefined();
      expect(res.body.data.jenis).toBe('pulang');
    });

    it('harus menolak checkout kedua kali di hari yang sama (409)', async () => {
      const res = await request(app)
        .post('/api/attendance/checkout')
        .set('Authorization', `Bearer ${spg1Token}`)
        .send(VALID_COORDS);

      expect(res.status).toBe(409);
      expect(res.body.success).toBe(false);
      expect(res.body.message).toContain('sudah melakukan absen pulang');
    });
  });

  // ─────────────────────────────────────────────────────────────
  // GET /api/attendance/history
  // ─────────────────────────────────────────────────────────────
  describe('GET /api/attendance/history', () => {
    it('harus menolak request tanpa token (401)', async () => {
      const res = await request(app).get('/api/attendance/history');
      expect(res.status).toBe(401);
      expect(res.body.success).toBe(false);
    });

    it('harus mengembalikan array riwayat absensi (200)', async () => {
      const res = await request(app)
        .get('/api/attendance/history')
        .set('Authorization', `Bearer ${spg1Token}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(Array.isArray(res.body.data)).toBe(true);
    });

    it('harus mendukung filter from dan to (200)', async () => {
      const today = new Date().toISOString().split('T')[0];
      const res = await request(app)
        .get(`/api/attendance/history?from=${today}&to=${today}`)
        .set('Authorization', `Bearer ${spg1Token}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(Array.isArray(res.body.data)).toBe(true);
    });
  });
});
