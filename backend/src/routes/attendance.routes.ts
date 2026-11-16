import { Router } from 'express';
import { attendanceController } from '../controllers/attendance.controller';
import { authenticateJWT } from '../middlewares/auth.middleware';
import { validate } from '../middlewares/validate.middleware';
import { checkinSchema, checkoutSchema } from '../validators/attendance.validator';

const router = Router();

// POST /api/attendance/checkin
router.post('/checkin', authenticateJWT, validate(checkinSchema), (req, res, next) => {
  attendanceController.checkin(req, res, next);
});

// POST /api/attendance/checkout
router.post('/checkout', authenticateJWT, validate(checkoutSchema), (req, res, next) => {
  attendanceController.checkout(req, res, next);
});

// GET /api/attendance/history
router.get('/history', authenticateJWT, (req, res, next) => {
  attendanceController.getHistory(req, res, next);
});

export default router;
