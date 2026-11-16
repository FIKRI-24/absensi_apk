import { calculateHaversineDistance } from '../src/utils/haversine.util';

describe('calculateHaversineDistance', () => {
  it('harus mengembalikan 0 (atau sangat kecil) untuk titik yang sama', () => {
    // Grand Indonesia ke Grand Indonesia
    const distance = calculateHaversineDistance(-6.19515, 106.82088, -6.19515, 106.82088);
    expect(distance).toBeLessThan(1);
  });

  it('harus menghitung jarak Grand Indonesia ke Central Park sekitar 3800-4000 meter', () => {
    // Grand Indonesia: -6.19515, 106.82088
    // Central Park: -6.17743, 106.79075
    // Jarak Haversine aktual: ~3870 meter
    const distance = calculateHaversineDistance(-6.19515, 106.82088, -6.17743, 106.79075);
    expect(distance).toBeGreaterThan(3800);
    expect(distance).toBeLessThan(4000);
  });

  it('harus mengembalikan jarak > 100 meter untuk titik yang jelas berbeda', () => {
    // Jakarta ke Surabaya (sangat jauh)
    const distance = calculateHaversineDistance(-6.2, 106.8, -7.25, 112.75);
    expect(distance).toBeGreaterThan(100);
  });

  it('harus mengembalikan nilai positif untuk titik manapun', () => {
    const distance = calculateHaversineDistance(0, 0, 1, 1);
    expect(distance).toBeGreaterThan(0);
  });
});
