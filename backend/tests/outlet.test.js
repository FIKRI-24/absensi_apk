"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const supertest_1 = __importDefault(require("supertest"));
const app_1 = __importDefault(require("../src/app"));
const database_1 = __importDefault(require("../src/config/database"));
describe('Outlet Endpoints (/api/outlet)', () => {
    let spg1Token;
    let spg2Token;
    let adminToken;
    beforeAll(async () => {
        // Login as SPG 1
        const res1 = await (0, supertest_1.default)(app_1.default).post('/api/auth/login').send({
            username: 'spg1',
            password: 'spg123',
        });
        spg1Token = res1.body.data.token;
        // Login as SPG 2
        const res2 = await (0, supertest_1.default)(app_1.default).post('/api/auth/login').send({
            username: 'spg2',
            password: 'spg123',
        });
        spg2Token = res2.body.data.token;
        // Login as Admin
        const resAdmin = await (0, supertest_1.default)(app_1.default).post('/api/auth/login').send({
            username: 'admin',
            password: 'admin123',
        });
        adminToken = resAdmin.body.data.token;
    });
    afterAll(async () => {
        await database_1.default.$disconnect();
    });
    describe('GET /api/outlet/me', () => {
        it('should reject request without token (401)', async () => {
            const response = await (0, supertest_1.default)(app_1.default).get('/api/outlet/me');
            expect(response.status).toBe(401);
            expect(response.body.success).toBe(false);
        });
        it('should reject request with invalid token (401)', async () => {
            const response = await (0, supertest_1.default)(app_1.default)
                .get('/api/outlet/me')
                .set('Authorization', 'Bearer invalid_dummy_token_12345');
            expect(response.status).toBe(401);
            expect(response.body.success).toBe(false);
        });
        it('should return SPG 1 outlet (Grand Indonesia Mall)', async () => {
            const response = await (0, supertest_1.default)(app_1.default)
                .get('/api/outlet/me')
                .set('Authorization', `Bearer ${spg1Token}`);
            expect(response.status).toBe(200);
            expect(response.body.success).toBe(true);
            expect(response.body.data).toHaveProperty('nama_toko', 'Grand Indonesia Mall');
            expect(response.body.data).toHaveProperty('kode_outlet', 'OUT-GI-001');
            expect(response.body.data).toHaveProperty('latitude');
            expect(response.body.data).toHaveProperty('longitude');
            expect(response.body.data).toHaveProperty('radius_meter', 100);
        });
        it('should return SPG 2 outlet (Central Park Mall)', async () => {
            const response = await (0, supertest_1.default)(app_1.default)
                .get('/api/outlet/me')
                .set('Authorization', `Bearer ${spg2Token}`);
            expect(response.status).toBe(200);
            expect(response.body.success).toBe(true);
            expect(response.body.data).toHaveProperty('nama_toko', 'Central Park Mall');
            expect(response.body.data).toHaveProperty('kode_outlet', 'OUT-CP-002');
        });
        it('should confirm SPG 1 only receives their assigned outlet and not SPG 2 outlet', async () => {
            const response = await (0, supertest_1.default)(app_1.default)
                .get('/api/outlet/me')
                .set('Authorization', `Bearer ${spg1Token}`);
            expect(response.status).toBe(200);
            expect(response.body.data.kode_outlet).not.toBe('OUT-CP-002');
            expect(response.body.data.kode_outlet).toBe('OUT-GI-001');
        });
        it('should return 404 for admin user who has no outlet assigned', async () => {
            const response = await (0, supertest_1.default)(app_1.default)
                .get('/api/outlet/me')
                .set('Authorization', `Bearer ${adminToken}`);
            expect(response.status).toBe(404);
            expect(response.body.success).toBe(false);
            expect(response.body.message).toContain('belum ditugaskan');
        });
    });
});
//# sourceMappingURL=outlet.test.js.map