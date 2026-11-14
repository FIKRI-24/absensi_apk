import jwt, { SignOptions } from 'jsonwebtoken';
import { config } from '../config/env';
import { JWTPayload } from '../types/auth.types';

export const generateToken = (payload: JWTPayload): string => {
  const options: SignOptions = {
    expiresIn: config.jwt.expiresIn as SignOptions['expiresIn'],
  };

  return jwt.sign(payload, config.jwt.secret, options);
};

export const verifyToken = (token: string): JWTPayload => {
  return jwt.verify(token, config.jwt.secret) as JWTPayload;
};
