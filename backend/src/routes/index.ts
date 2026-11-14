import { Router } from 'express';
import healthRoutes from './health.routes';

const router = Router();

// Health check endpoint
router.use('/', healthRoutes);

// More routes (auth, outlet, attendance, admin) will be added in subsequent phases

export default router;
