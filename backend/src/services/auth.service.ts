import prisma from '../config/database';
import { comparePassword } from '../utils/password.util';
import { generateToken } from '../utils/jwt.util';
import { LoginInput } from '../validators/auth.validator';
import { AppError } from '../middlewares/error.middleware';

export class AuthService {
  async login(input: LoginInput) {
    const { username, password } = input;

    // 1. Find user by username
    const user = await prisma.user.findUnique({
      where: { username },
      include: {
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
      const error: AppError = new Error('Username atau password salah');
      error.statusCode = 401;
      throw error;
    }

    // 2. Validate password with bcrypt
    const isPasswordValid = await comparePassword(password, user.password_hash);
    if (!isPasswordValid) {
      const error: AppError = new Error('Username atau password salah');
      error.statusCode = 401;
      throw error;
    }

    // 3. Generate JWT Token
    const token = generateToken({
      userId: user.id,
      username: user.username,
      role: user.role,
      kodeSpg: user.kode_spg,
      outletId: user.outlet_id,
    });

    // 4. Return token & user profile (exclude password_hash)
    return {
      token,
      user: {
        id: user.id,
        nama: user.nama,
        kode_spg: user.kode_spg,
        username: user.username,
        role: user.role,
        outlet_id: user.outlet_id,
        outlet: user.outlet,
      },
    };
  }
}

export const authService = new AuthService();
