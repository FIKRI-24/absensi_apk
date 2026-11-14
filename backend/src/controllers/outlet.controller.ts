import { Request, Response, NextFunction } from 'express';
import { outletService } from '../services/outlet.service';

export class OutletController {
  async getMyOutlet(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) {
        res.status(401).json({
          success: false,
          message: 'Pengguna belum terautentikasi',
        });
        return;
      }

      const outlet = await outletService.getMyOutlet(req.user.userId);

      res.status(200).json({
        success: true,
        data: outlet,
      });
    } catch (error) {
      next(error);
    }
  }
}

export const outletController = new OutletController();
