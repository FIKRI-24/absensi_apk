import { Router } from 'express';
import healthRoutes from './health.routes';
import authRoutes from './auth.routes';
import outletRoutes from './outlet.routes';
import serverTimeRoutes from './serverTime.routes';
import attendanceRoutes from './attendance.routes';

const router = Router();

// Health check
router.use('/', healthRoutes);

// Auth endpoints (/api/auth/login)
router.use('/auth', authRoutes);

// Outlet endpoints (/api/outlet/me)
router.use('/outlet', outletRoutes);

// Server time endpoints (/api/server-time)
router.use('/', serverTimeRoutes);

// Attendance endpoints (/api/attendance/...)
router.use('/attendance', attendanceRoutes);

export default router;
