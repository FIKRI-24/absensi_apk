import { Router } from 'express';
import { serverTimeController } from '../controllers/serverTime.controller';
import { authenticateJWT } from '../middlewares/auth.middleware';

const router = Router();

// GET /api/server-time (Wajib header Authorization: Bearer <token>)
router.get('/server-time', authenticateJWT, (req, res) => {
  serverTimeController.getServerTime(req, res);
});

export default router;
