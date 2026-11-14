"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const supertest_1 = __importDefault(require("supertest"));
const app_1 = __importDefault(require("../src/app"));
const database_1 = __importDefault(require("../src/config/database"));
describe('Server Time Endpoints (/api/server-time)', () => {
    let token;
    beforeAll(async () => {
        const res = await (0, supertest_1.default)(app_1.default).post('/api/auth/login').send({
            username: 'spg1',
            password: 'spg123',
        });
        token = res.body.data.token;
    });
    afterAll(async () => {
        await database_1.default.$disconnect();
    });
    describe('GET /api/server-time', () => {
        it('should reject request without token (401)', async () => {
            const response = await (0, supertest_1.default)(app_1.default).get('/api/server-time');
            expect(response.status).toBe(401);
            expect(response.body.success).toBe(false);
        });
        it('should return server time with WIB and UTC format for authenticated user', async () => {
            const response = await (0, supertest_1.default)(app_1.default)
                .get('/api/server-time')
                .set('Authorization', `Bearer ${token}`);
            expect(response.status).toBe(200);
            expect(response.body.success).toBe(true);
            expect(response.body.data).toHaveProperty('timestamp');
            expect(response.body.data).toHaveProperty('server_time_utc');
            expect(response.body.data).toHaveProperty('server_time_wib');
            expect(response.body.data).toHaveProperty('timezone', 'Asia/Jakarta');
            expect(response.body.data).toHaveProperty('offset_hours', 7);
            // Verify timestamp is reasonably close to now (within 5 seconds)
            const diff = Math.abs(Date.now() - response.body.data.timestamp);
            expect(diff).toBeLessThan(5000);
        });
    });
});
//# sourceMappingURL=serverTime.test.js.map