"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const supertest_1 = __importDefault(require("supertest"));
const app_1 = __importDefault(require("../src/app"));
const database_1 = __importDefault(require("../src/config/database"));
describe('Auth Endpoints (/api/auth)', () => {
    afterAll(async () => {
        await database_1.default.$disconnect();
    });
    describe('POST /api/auth/login', () => {
        it('should login successfully with valid SPG credentials', async () => {
            const response = await (0, supertest_1.default)(app_1.default)
                .post('/api/auth/login')
                .send({
                username: 'spg1',
                password: 'spg123',
            });
            expect(response.status).toBe(200);
            expect(response.body.success).toBe(true);
            expect(response.body.data).toHaveProperty('token');
            expect(response.body.data.user).toBeDefined();
            expect(response.body.data.user.username).toBe('spg1');
            expect(response.body.data.user.role).toBe('spg');
            expect(response.body.data.user.outlet).toBeDefined();
            expect(response.body.data.user.outlet.kode_outlet).toBe('OUT-GI-001');
            expect(response.body.data.user).not.toHaveProperty('password_hash');
        });
        it('should login successfully with valid Admin credentials', async () => {
            const response = await (0, supertest_1.default)(app_1.default)
                .post('/api/auth/login')
                .send({
                username: 'admin',
                password: 'admin123',
            });
            expect(response.status).toBe(200);
            expect(response.body.success).toBe(true);
            expect(response.body.data).toHaveProperty('token');
            expect(response.body.data.user.role).toBe('admin');
        });
        it('should reject login with incorrect password', async () => {
            const response = await (0, supertest_1.default)(app_1.default)
                .post('/api/auth/login')
                .send({
                username: 'spg1',
                password: 'wrongpassword',
            });
            expect(response.status).toBe(401);
            expect(response.body.success).toBe(false);
            expect(response.body.message).toContain('Username atau password salah');
        });
        it('should reject login with non-existent username', async () => {
            const response = await (0, supertest_1.default)(app_1.default)
                .post('/api/auth/login')
                .send({
                username: 'unknown_user_999',
                password: 'somepassword',
            });
            expect(response.status).toBe(401);
            expect(response.body.success).toBe(false);
            expect(response.body.message).toContain('Username atau password salah');
        });
        it('should reject request when required fields are missing', async () => {
            const response = await (0, supertest_1.default)(app_1.default)
                .post('/api/auth/login')
                .send({
                username: 'spg1',
            });
            expect(response.status).toBe(400);
            expect(response.body.success).toBe(false);
            expect(response.body.message).toContain('Validasi input gagal');
        });
    });
});
//# sourceMappingURL=auth.test.js.map