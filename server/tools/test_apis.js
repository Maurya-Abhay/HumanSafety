const fs = require('fs');
const path = require('path');
const fetch = global.fetch || require('node-fetch');

const SERVER_ROOT = path.resolve(__dirname, '..');
const APP_JS = path.join(SERVER_ROOT, 'app.js');
const ROUTES_DIR = path.join(SERVER_ROOT, 'routes');
const OUTPUT = [];

function parseAppJs() {
  const src = fs.readFileSync(APP_JS, 'utf8');
  const requires = {};
  // Find require lines: const authRoutes = require('./routes/auth.routes');
  const requireRe = /const\s+(\w+)\s*=\s*require\((['\"])(\.\/routes\/[\w_\-\.]+)\2\)/g;
  let m;
  while ((m = requireRe.exec(src))) {
    requires[m[1]] = m[3];
  }

  const mounts = {};
  // Find app.use('/api/v1/auth', authLimiter, authRoutes); or app.use('/path', routes);
  const mountRe = /app\.use\((['\"])([^'\"]+)\1\s*,\s*(?:[\w$]+\s*,\s*)*(\w+)\)/g;
  while ((m = mountRe.exec(src))) {
    const base = m[2];
    const varName = m[3];
    if (requires[varName]) mounts[requires[varName]] = base;
  }

  return { requires, mounts };
}

function parseRouteFile(routePath) {
  const baseName = path.basename(routePath);
  let full = path.join(ROUTES_DIR, baseName);
  if (!fs.existsSync(full)) {
    // try with .js
    full = full + '.js';
  }
  if (!fs.existsSync(full)) return [];
  const src = fs.readFileSync(full, 'utf8');
  const re = /router\.(get|post|put|delete|patch)\((['\"])([^'\"]+)\2/g;
  const routes = [];
  let m;
  while ((m = re.exec(src))) {
    routes.push({ method: m[1].toUpperCase(), path: m[3] });
  }
  return routes;
}

async function testEndpoint(method, url) {
  try {
    const opts = { method, headers: { 'Content-Type': 'application/json' }, timeout: 10000 };
    if (method !== 'GET' && method !== 'DELETE') opts.body = JSON.stringify({});
    const res = await fetch(url, opts);
    const text = await res.text();
    let json = null;
    try { json = JSON.parse(text); } catch (e) { json = { text }; }
    return { ok: res.ok, status: res.status, body: json };
  } catch (error) {
    return { ok: false, error: error.message };
  }
}

(async function main() {
  const { requires, mounts } = parseAppJs();
  const host = process.env.SERVER_URL || 'http://localhost:5000';
  console.log('Discovered route requires:', requires);
  console.log('Discovered mounts:', mounts);

  for (const reqVar in requires) {
    const routeRel = requires[reqVar];
    const base = mounts[routeRel] || '/';
    const routeFile = path.basename(routeRel);
    let filePath = path.join(ROUTES_DIR, routeFile);
    if (!fs.existsSync(filePath)) {
      const tryJs = filePath + '.js';
      if (fs.existsSync(tryJs)) filePath = tryJs;
      else continue;
    }
    const routes = parseRouteFile(routeRel);
    for (const r of routes) {
      const fullPath = path.posix.join(base, r.path).replace(/\\/g, '/');
      const url = host + fullPath;
      process.stdout.write(`${r.method} ${fullPath} -> `);
      // For path params like :id, replace with test value
      const testUrl = url.replace(/:([a-zA-Z_]+)/g, 'testid');
      const res = await testEndpoint(r.method, testUrl);
      if (res.ok) console.log(`OK ${res.status}`);
      else if (res.status) console.log(`FAIL ${res.status}`);
      else console.log(`ERROR ${res.error}`);
      OUTPUT.push({ method: r.method, path: fullPath, url: testUrl, result: res });
    }
  }

  const outPath = path.join(SERVER_ROOT, 'tools', 'api_test_results.json');
  fs.writeFileSync(outPath, JSON.stringify(OUTPUT, null, 2));
  console.log('\nResults written to', outPath);
})();
