import { Request, Response, NextFunction } from 'express';
import { attendanceService } from '../services/attendance.service';
import { CheckinInput, CheckoutInput } from '../validators/attendance.validator';

export class AttendanceController {
  async checkin(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = req.user!.userId;
      const input = req.body as CheckinInput;

      const attendance = await attendanceService.checkin(userId, input);

      res.status(201).json({
        success: true,
        message: 'Absen datang berhasil dicatat',
        data: attendance,
      });
    } catch (error) {
      next(error);
    }
  }

  async checkout(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = req.user!.userId;
      const input = req.body as CheckoutInput;

      const attendance = await attendanceService.checkout(userId, input);

      res.status(201).json({
        success: true,
        message: 'Absen pulang berhasil dicatat',
        data: attendance,
      });
    } catch (error) {
      next(error);
    }
  }

  async getHistory(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = req.user!.userId;
      const { from, to } = req.query as { from?: string; to?: string };

      const attendances = await attendanceService.getHistory(userId, from, to);

      res.status(200).json({
        success: true,
        data: attendances,
      });
    } catch (error) {
      next(error);
    }
  }
}

export const attendanceController = new AttendanceController();
