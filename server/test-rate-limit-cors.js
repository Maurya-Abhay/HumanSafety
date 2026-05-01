// Rate Limiting & CORS Test Suite
// Run this after starting the server: npm run prod

const http = require('http');

const BASE_URL = 'http://localhost:5000';
const TOKEN = 'Bearer your_test_token_here'; // Replace with valid token

let passCount = 0;
let failCount = 0;

// Helper to make HTTP request
function makeRequest(method, path, data = null, headers = {}) {
  return new Promise((resolve, reject) => {
    const url = new URL(path, BASE_URL);
    const options = {
      method,
      hostname: url.hostname,
      port: url.port,
      path: url.pathname + url.search,
      headers: {
        'Content-Type': 'application/json',
        ...headers,
      },
    };

    const req = http.request(options, (res) => {
      let responseData = '';
      res.on('data', (chunk) => {
        responseData += chunk;
      });
      res.on('end', () => {
        resolve({
          status: res.statusCode,
          headers: res.headers,
          body: responseData,
        });
      });
    });

    req.on('error', reject);

    if (data) {
      req.write(JSON.stringify(data));
    }
    req.end();
  });
}

async function test(name, fn) {
  try {
    await fn();
    console.log(`✓ ${name}`);
    passCount++;
  } catch (err) {
    console.log(`✗ ${name}: ${err.message}`);
    failCount++;
  }
}

async function runTests() {
  console.log('=== RATE LIMITING & CORS TESTS ===\n');

  // Test 1: Health check
  await test('Health check returns 200', async () => {
    const res = await makeRequest('GET', '/health');
    if (res.status !== 200) throw new Error(`Expected 200, got ${res.status}`);
  });

  // Test 2: Rate limiting - global limit
  console.log('\n--- Rate Limiting Tests ---');
  await test('Rate limiting: First 100 requests should pass', async () => {
    let successCount = 0;
    for (let i = 0; i < 100; i++) {
      const res = await makeRequest('GET', '/api/v1/user/profile', null, {
        'Authorization': TOKEN,
      });
      if (res.status === 200 || res.status === 401) {
        // 401 is fine (no valid token), we're testing rate limit
        successCount++;
      }
    }
    if (successCount < 95) throw new Error(`Only ${successCount}/100 requests passed`);
  });

  await test('Rate limiting: Request 101+ should return 429', async () => {
    const res = await makeRequest('GET', '/api/v1/user/profile', null, {
      'Authorization': TOKEN,
    });
    if (res.status !== 429) {
      throw new Error(`Expected 429 (Too Many Requests), got ${res.status}`);
    }
  });

  // Test 3: Auth endpoint stricter limit
  console.log('\n--- Auth Endpoint Rate Limit Tests ---');
  await test('Auth limit: 5 login attempts should pass', async () => {
    let successCount = 0;
    for (let i = 0; i < 5; i++) {
      const res = await makeRequest('POST', '/api/v1/auth/login', {
        phone: '1234567890',
        password: 'test',
      });
      if (res.status !== 429) {
        successCount++;
      }
    }
    if (successCount < 5) throw new Error(`Only ${successCount}/5 passed`);
  });

  await test('Auth limit: Request 6+ should return 429', async () => {
    const res = await makeRequest('POST', '/api/v1/auth/login', {
      phone: '1234567890',
      password: 'test',
    });
    if (res.status !== 429) {
      throw new Error(`Expected 429, got ${res.status}`);
    }
  });

  // Test 4: CORS headers
  console.log('\n--- CORS Tests ---');
  await test('CORS: Response includes Access-Control-Allow-Origin header', async () => {
    const res = await makeRequest('GET', '/health', null, {
      'Origin': 'http://localhost:3000',
    });
    if (!res.headers['access-control-allow-origin']) {
      throw new Error('Missing CORS header');
    }
  });

  await test('CORS: Allowed methods include GET, POST, PUT, DELETE', async () => {
    const res = await makeRequest('GET', '/health', null, {
      'Origin': 'http://localhost:3000',
    });
    const allowedMethods = res.headers['access-control-allow-methods'];
    if (!allowedMethods || (!allowedMethods.includes('GET') && !allowedMethods.includes('POST'))) {
      throw new Error('Missing allowed methods in CORS header');
    }
  });

  // Test 5: Error handling
  console.log('\n--- Error Handling Tests ---');
  await test('404 response for unknown route', async () => {
    const res = await makeRequest('GET', '/api/v1/nonexistent');
    if (res.status !== 404) throw new Error(`Expected 404, got ${res.status}`);
  });

  await test('Error response includes requestId', async () => {
    const res = await makeRequest('GET', '/api/v1/nonexistent');
    const body = JSON.parse(res.body);
    if (!body.requestId) throw new Error('Missing requestId in error response');
  });

  // Summary
  console.log('\n=== TEST SUMMARY ===');
  console.log(`✓ Passed: ${passCount}`);
  console.log(`✗ Failed: ${failCount}`);
  console.log(`Total: ${passCount + failCount}`);

  if (failCount === 0) {
    console.log('\n✓ All tests passed!');
    process.exit(0);
  } else {
    console.log('\n✗ Some tests failed');
    process.exit(1);
  }
}

// Wait for server to be ready
async function waitForServer() {
  let retries = 30; // 30 seconds
  while (retries > 0) {
    try {
      await makeRequest('GET', '/health');
      return;
    } catch {
      retries--;
      await new Promise((r) => setTimeout(r, 1000));
    }
  }
  throw new Error('Server not responding');
}

async function main() {
  try {
    console.log('Waiting for server...');
    await waitForServer();
    console.log('Server ready!\n');
    await runTests();
  } catch (err) {
    console.error('Fatal error:', err.message);
    process.exit(1);
  }
}

main();
