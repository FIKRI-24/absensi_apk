import prisma from '../config/database';
import { AppError } from '../middlewares/error.middleware';
import { calculateHaversineDistance } from '../utils/haversine.util';
import { CheckinInput, CheckoutInput } from '../validators/attendance.validator';

/**
 * Mengembalikan range awal dan akhir hari ini dalam UTC, berdasarkan timezone WIB (UTC+7).
 */
function getTodayRangeWIB(): { startOfDayUTC: Date; endOfDayUTC: Date } {
  const now = new Date();
  const wibOffset = 7 * 60 * 60 * 1000; // 7 jam dalam ms
  const todayWIB = new Date(now.getTime() + wibOffset);
  const startOfDayUTC = new Date(
    Date.UTC(todayWIB.getUTCFullYear(), todayWIB.getUTCMonth(), todayWIB.getUTCDate()) - wibOffset
  );
  const endOfDayUTC = new Date(startOfDayUTC.getTime() + 24 * 60 * 60 * 1000 - 1);
  return { startOfDayUTC, endOfDayUTC };
}

export class AttendanceService {
  async checkin(userId: number, input: CheckinInput) {
    // 1. Ambil data user + outlet dari DB
    const user = await prisma.user.findUnique({
      where: { id: userId },
      include: { outlet: true },
    });

    if (!user || !user.outlet) {
      const error: AppError = new Error('SPG belum ditugaskan ke outlet');
      error.statusCode = 400;
      throw error;
    }

    // 2. Tolak jika mock location terdeteksi
    if (input.mock_location_detected === true) {
      const error: AppError = new Error(
        'Absen ditolak: terdeteksi lokasi palsu (mock/fake GPS)'
      );
      error.statusCode = 403;
      throw error;
    }

    // 3. Hitung jarak Haversine
    const jarak = calculateHaversineDistance(
      input.latitude,
      input.longitude,
      user.outlet.latitude,
      user.outlet.longitude
    );

    if (jarak > user.outlet.radius_meter) {
      const error: AppError = new Error(
        `Absen ditolak: Anda berada ${Math.round(jarak)} meter dari toko. Radius yang diizinkan: ${user.outlet.radius_meter} meter`
      );
      error.statusCode = 403;
      throw error;
    }

    // 4. Cek apakah sudah checkin hari ini
    const { startOfDayUTC, endOfDayUTC } = getTodayRangeWIB();
    const existingCheckin = await prisma.attendance.findFirst({
      where: {
        user_id: userId,
        jenis: 'masuk',
        waktu_server: {
          gte: startOfDayUTC,
          lte: endOfDayUTC,
        },
      },
    });

    if (existingCheckin) {
      const error: AppError = new Error('Anda sudah melakukan absen datang hari ini');
      error.statusCode = 409;
      throw error;
    }

    // 5. Buat record attendance
    const attendance = await prisma.attendance.create({
      data: {
        user_id: userId,
        outlet_id: user.outlet.id,
        jenis: 'masuk',
        waktu_server: new Date(),
        lat_device: input.latitude,
        long_device: input.longitude,
        jarak_meter: jarak,
        mock_location_detected: input.mock_location_detected,
        foto_url: input.foto_base64 ?? null,
        status: 'valid',
      },
    });

    return attendance;
  }

  async checkout(userId: number, input: CheckoutInput) {
    // 1. Ambil data user + outlet dari DB
    const user = await prisma.user.findUnique({
      where: { id: userId },
      include: { outlet: true },
    });

    if (!user || !user.outlet) {
      const error: AppError = new Error('SPG belum ditugaskan ke outlet');
      error.statusCode = 400;
      throw error;
    }

    // 2. Tolak jika mock location terdeteksi
    if (input.mock_location_detected === true) {
      const error: AppError = new Error(
        'Absen ditolak: terdeteksi lokasi palsu (mock/fake GPS)'
      );
      error.statusCode = 403;
      throw error;
    }

    // 3. Hitung jarak Haversine
    const jarak = calculateHaversineDistance(
      input.latitude,
      input.longitude,
      user.outlet.latitude,
      user.outlet.longitude
    );

    if (jarak > user.outlet.radius_meter) {
      const error: AppError = new Error(
        `Absen ditolak: Anda berada ${Math.round(jarak)} meter dari toko. Radius yang diizinkan: ${user.outlet.radius_meter} meter`
      );
      error.statusCode = 403;
      throw error;
    }

    const { startOfDayUTC, endOfDayUTC } = getTodayRangeWIB();

    // 4. Validasi: harus sudah checkin hari ini
    const existingCheckin = await prisma.attendance.findFirst({
      where: {
        user_id: userId,
        jenis: 'masuk',
        waktu_server: {
          gte: startOfDayUTC,
          lte: endOfDayUTC,
        },
      },
    });

    if (!existingCheckin) {
      const error: AppError = new Error('Anda belum melakukan absen datang hari ini');
      error.statusCode = 400;
      throw error;
    }

    // 5. Cek apakah sudah checkout hari ini
    const existingCheckout = await prisma.attendance.findFirst({
      where: {
        user_id: userId,
        jenis: 'pulang',
        waktu_server: {
          gte: startOfDayUTC,
          lte: endOfDayUTC,
        },
      },
    });

    if (existingCheckout) {
      const error: AppError = new Error('Anda sudah melakukan absen pulang hari ini');
      error.statusCode = 409;
      throw error;
    }

    // 6. Buat record attendance checkout
    const attendance = await prisma.attendance.create({
      data: {
        user_id: userId,
        outlet_id: user.outlet.id,
        jenis: 'pulang',
        waktu_server: new Date(),
        lat_device: input.latitude,
        long_device: input.longitude,
        jarak_meter: jarak,
        mock_location_detected: input.mock_location_detected,
        foto_url: input.foto_base64 ?? null,
        status: 'valid',
      },
    });

    return attendance;
  }

  async getHistory(userId: number, from?: string, to?: string) {
    const whereClause: {
      user_id: number;
      created_at?: { gte?: Date; lte?: Date };
    } = { user_id: userId };

    if (from || to) {
      whereClause.created_at = {};
      if (from) {
        whereClause.created_at.gte = new Date(from);
      }
      if (to) {
        whereClause.created_at.lte = new Date(to);
      }
    }

    const attendances = await prisma.attendance.findMany({
      where: whereClause,
      orderBy: { created_at: 'desc' },
    });

    return attendances;
  }
}

export const attendanceService = new AttendanceService();
