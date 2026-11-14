import prisma from '../config/database';
import { AppError } from '../middlewares/error.middleware';

export class OutletService {
  async getMyOutlet(userId: number) {
    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        nama: true,
        kode_spg: true,
        outlet_id: true,
        outlet: {
          select: {
            id: true,
            nama_toko: true,
            kode_outlet: true,
            latitude: true,
            longitude: true,
            radius_meter: true,
          },
        },
      },
    });

    if (!user) {
      const error: AppError = new Error('Pengguna tidak ditemukan');
      error.statusCode = 404;
      throw error;
    }

    if (!user.outlet) {
      const error: AppError = new Error('SPG belum ditugaskan ke toko/outlet manapun');
      error.statusCode = 404;
      throw error;
    }

    return user.outlet;
  }
}

export const outletService = new OutletService();
