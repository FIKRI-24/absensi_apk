import { z } from 'zod';

export const checkinSchema = z.object({
  latitude: z
    .number({ required_error: 'Latitude wajib diisi', invalid_type_error: 'Latitude harus berupa angka' })
    .min(-90, 'Latitude tidak valid (min -90)')
    .max(90, 'Latitude tidak valid (max 90)'),
  longitude: z
    .number({ required_error: 'Longitude wajib diisi', invalid_type_error: 'Longitude harus berupa angka' })
    .min(-180, 'Longitude tidak valid (min -180)')
    .max(180, 'Longitude tidak valid (max 180)'),
  accuracy: z
    .number({ required_error: 'Akurasi GPS wajib diisi', invalid_type_error: 'Akurasi harus berupa angka' })
    .min(0, 'Akurasi tidak valid (min 0)'),
  mock_location_detected: z.boolean({
    required_error: 'Status mock location wajib diisi',
    invalid_type_error: 'mock_location_detected harus berupa boolean',
  }),
  foto_base64: z.string().optional(),
});

export const checkoutSchema = z.object({
  latitude: z
    .number({ required_error: 'Latitude wajib diisi', invalid_type_error: 'Latitude harus berupa angka' })
    .min(-90, 'Latitude tidak valid (min -90)')
    .max(90, 'Latitude tidak valid (max 90)'),
  longitude: z
    .number({ required_error: 'Longitude wajib diisi', invalid_type_error: 'Longitude harus berupa angka' })
    .min(-180, 'Longitude tidak valid (min -180)')
    .max(180, 'Longitude tidak valid (max 180)'),
  accuracy: z
    .number({ required_error: 'Akurasi GPS wajib diisi', invalid_type_error: 'Akurasi harus berupa angka' })
    .min(0, 'Akurasi tidak valid (min 0)'),
  mock_location_detected: z.boolean({
    required_error: 'Status mock location wajib diisi',
    invalid_type_error: 'mock_location_detected harus berupa boolean',
  }),
  foto_base64: z.string().optional(),
});

export const historyQuerySchema = z.object({
  from: z.string().optional(),
  to: z.string().optional(),
});

export type CheckinInput = z.infer<typeof checkinSchema>;
export type CheckoutInput = z.infer<typeof checkoutSchema>;
export type HistoryQueryInput = z.infer<typeof historyQuerySchema>;
