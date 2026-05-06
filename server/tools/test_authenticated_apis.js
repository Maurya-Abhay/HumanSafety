const fs = require('fs');
const path = require('path');
const fetch = global.fetch || require('node-fetch');

const SERVER_ROOT = path.resolve(__dirname, '..');
const OUTPUT = [];

const host = process.env.SERVER_URL || 'http://localhost:5000';

async function testEndpoint(method, url, body = null, token = null, description = '') {
  try {
    const opts = {
      method,
      headers: { 'Content-Type': 'application/json' },
      timeout: 10000,
    };
    if (token) opts.headers.Authorization = `Bearer ${token}`;
    if (body) opts.body = JSON.stringify(body);

    const res = await fetch(url, opts);
    const text = await res.text();
    let json = null;
    try { json = JSON.parse(text); } catch (e) { json = { text }; }
    
    const result = { ok: res.ok, status: res.status, body: json };
    const icon = res.ok ? '✓' : '✗';
    console.log(`${icon} [${res.status}] ${description || method} ${url.replace(host, '')}`);
    
    return result;
  } catch (error) {
    const result = { ok: false, error: error.message };
    console.log(`✗ [ERR] ${description || method} ${url.replace(host, '')} - ${error.message}`);
    return result;
  }
}

(async function main() {
  console.log('🔐 === STARTING AUTHENTICATED API TEST ===\n');

  // Step 1: Create test user via signup
  console.log('📝 Step 1: Creating test user...');
  const phoneNum = `999${Date.now().toString().slice(-7)}`;
  const signupResult = await testEndpoint(
    'POST',
    `${host}/api/v1/auth/signup`,
    {
      fullName: 'Test User',
      phone: phoneNum,
      email: `test${Date.now()}@example.com`,
      password: 'Test@1234',
    },
    null,
    'POST /api/v1/auth/signup (create user)'
  );

  if (!signupResult.ok || !signupResult.body?.data?.token) {
    console.log('❌ Signup failed:', signupResult.body?.error?.message || signupResult.error);
    process.exit(1);
  }

  const token = signupResult.body.data.token;
  const userId = signupResult.body.data.user.id;
  console.log(`✓ Token obtained: ${token.slice(0, 20)}...`);
  console.log(`✓ User ID: ${userId}\n`);

  // Step 2: Test Auth endpoints
  console.log('🔑 === AUTH ENDPOINTS ===');
  await testEndpoint('POST', `${host}/api/v1/auth/login`, { phone: phoneNum, password: 'Test@1234' }, null, 'POST /api/v1/auth/login');
  await testEndpoint('POST', `${host}/api/v1/auth/refresh-token`, { token }, null, 'POST /api/v1/auth/refresh-token');
  await testEndpoint('POST', `${host}/api/v1/auth/logout`, {}, token, 'POST /api/v1/auth/logout');
  console.log('');

  // Step 3: Test User endpoints
  console.log('👤 === USER ENDPOINTS ===');
  await testEndpoint('GET', `${host}/api/v1/user/profile`, null, token, 'GET /api/v1/user/profile');
  await testEndpoint('PUT', `${host}/api/v1/user/profile`, { name: 'Updated Name' }, token, 'PUT /api/v1/user/profile');
  await testEndpoint('POST', `${host}/api/v1/user/location`, { latitude: 28.7041, longitude: 77.1025 }, token, 'POST /api/v1/user/location');
  await testEndpoint('GET', `${host}/api/v1/user/location`, null, token, 'GET /api/v1/user/location');
  await testEndpoint('POST', `${host}/api/v1/user/role-application`, { role: 'police', documents: {} }, token, 'POST /api/v1/user/role-application');
  console.log('');

  // Step 4: Test Contact endpoints
  console.log('📞 === CONTACT ENDPOINTS ===');
  await testEndpoint('POST', `${host}/api/v1/contact/add`, { name: 'Contact', phone: '9999000001' }, token, 'POST /api/v1/contact/add');
  await testEndpoint('GET', `${host}/api/v1/contact/list`, null, token, 'GET /api/v1/contact/list');
  console.log('');

  // Step 5: Test Emergency endpoints
  console.log('🚨 === EMERGENCY ENDPOINTS ===');
  await testEndpoint('POST', `${host}/api/v1/emergency/panic`, { type: 'accident', location: { latitude: 28.7041, longitude: 77.1025 } }, token, 'POST /api/v1/emergency/panic');
  await testEndpoint('GET', `${host}/api/v1/emergency/alerts`, null, token, 'GET /api/v1/emergency/alerts');
  console.log('');

  // Step 6: Test Help endpoints
  console.log('🆘 === HELP ENDPOINTS ===');
  await testEndpoint('POST', `${host}/api/v1/help/request`, { type: 'assistance', description: 'Need help' }, token, 'POST /api/v1/help/request');
  await testEndpoint('GET', `${host}/api/v1/help/requests`, null, token, 'GET /api/v1/help/requests');
  console.log('');

  // Step 7: Test Hospital endpoints
  console.log('🏥 === HOSPITAL ENDPOINTS ===');
  await testEndpoint('GET', `${host}/api/v1/hospital/nearby`, null, token, 'GET /api/v1/hospital/nearby');
  await testEndpoint('GET', `${host}/api/v1/hospital/alerts`, null, token, 'GET /api/v1/hospital/alerts');
  console.log('');

  // Step 8: Test Accident Analysis endpoints
  console.log('🚗 === ACCIDENT ENDPOINTS ===');
  await testEndpoint('POST', `${host}/api/v1/accident/analyze`, { 
    audioFile: 'base64-encoded-audio',
    videoFile: 'base64-encoded-video'
  }, token, 'POST /api/v1/accident/analyze');
  console.log('');

  // Step 9: Test Settings endpoints
  console.log('⚙️ === SETTINGS ENDPOINTS ===');
  await testEndpoint('GET', `${host}/api/v1/settings/`, null, token, 'GET /api/v1/settings/');
  await testEndpoint('PUT', `${host}/api/v1/settings/update`, { theme: 'dark' }, token, 'PUT /api/v1/settings/update');
  console.log('');

  // Step 10: Test AI endpoints
  console.log('🤖 === AI ENDPOINTS ===');
  await testEndpoint('GET', `${host}/api/v1/ai/profile/${userId}`, null, token, 'GET /api/v1/ai/profile/:userId');
  await testEndpoint('POST', `${host}/api/v1/ai/behavior-history`, { userId, behavior: 'panic_detected' }, token, 'POST /api/v1/ai/behavior-history');
  await testEndpoint('GET', `${host}/api/v1/ai/prediction-history/${userId}`, null, token, 'GET /api/v1/ai/prediction-history/:userId');
  console.log('');

  // Step 11: Test Health endpoints
  console.log('💓 === HEALTH ENDPOINTS ===');
  await testEndpoint('GET', `${host}/health/`, null, null, 'GET /health/');
  await testEndpoint('GET', `${host}/health/db`, null, null, 'GET /health/db');
  await testEndpoint('GET', `${host}/health/ready`, null, null, 'GET /health/ready');
  console.log('');

  // Step 12: Admin endpoints (for reference)
  console.log('👨‍💼 === ADMIN ENDPOINTS (require admin token) ===');
  await testEndpoint('GET', `${host}/api/v1/admin/dashboard`, null, token, 'GET /api/v1/admin/dashboard');
  await testEndpoint('GET', `${host}/api/v1/admin/users`, null, token, 'GET /api/v1/admin/users');
  console.log('');

  // Write summary
  const outPath = path.join(SERVER_ROOT, 'tools', 'authenticated_test_results.json');
  fs.writeFileSync(outPath, JSON.stringify(OUTPUT, null, 2));
  console.log(`\n✅ Test complete. Results written to: ${outPath}`);
})();
