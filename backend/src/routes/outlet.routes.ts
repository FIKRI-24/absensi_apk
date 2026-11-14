import { Router } from 'express';
import { outletController } from '../controllers/outlet.controller';
import { authenticateJWT } from '../middlewares/auth.middleware';

const router = Router();

// GET /api/outlet/me (Wajib header Authorization: Bearer <token>)
router.get('/me', authenticateJWT, (req, res, next) => {
  outletController.getMyOutlet(req, res, next);
});

export default router;
