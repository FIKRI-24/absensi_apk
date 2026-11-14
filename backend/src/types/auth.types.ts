export interface JWTPayload {
  userId: number;
  username: string;
  role: string;
  kodeSpg: string;
  outletId: number | null;
}

declare global {
  // eslint-disable-next-line @typescript-eslint/no-namespace
  namespace Express {
    interface Request {
      user?: JWTPayload;
    }
  }
}
