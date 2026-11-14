import app from './app';
import { config } from './config/env';

const server = app.listen(config.port, () => {
  console.log(`[Server] Running on http://localhost:${config.port} in ${config.nodeEnv} mode`);
});

// Graceful shutdown
const signals = ['SIGTERM', 'SIGINT'];
signals.forEach((signal) => {
  process.on(signal, () => {
    console.log(`[Server] ${signal} received. Closing HTTP server...`);
    server.close(() => {
      console.log('[Server] HTTP server closed.');
      process.exit(0);
    });
  });
});
