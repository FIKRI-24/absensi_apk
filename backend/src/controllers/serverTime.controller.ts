import { Request, Response } from 'express';

export class ServerTimeController {
  getServerTime(_req: Request, res: Response): void {
    const now = new Date();

    // WIB is UTC+7 (420 minutes)
    const wibOffsetMinutes = 7 * 60;
    const wibDate = new Date(now.getTime() + wibOffsetMinutes * 60 * 1000);

    // Format WIB string: YYYY-MM-DD HH:mm:ss
    const pad = (n: number) => n.toString().padStart(2, '0');
    const wibFormatted = `${wibDate.getUTCFullYear()}-${pad(wibDate.getUTCMonth() + 1)}-${pad(
      wibDate.getUTCDate()
    )} ${pad(wibDate.getUTCHours())}:${pad(wibDate.getUTCMinutes())}:${pad(wibDate.getUTCSeconds())}`;

    res.status(200).json({
      success: true,
      data: {
        timestamp: now.getTime(),
        server_time_utc: now.toISOString(),
        server_time_wib: wibFormatted,
        timezone: 'Asia/Jakarta',
        offset_hours: 7,
      },
    });
  }
}

export const serverTimeController = new ServerTimeController();
