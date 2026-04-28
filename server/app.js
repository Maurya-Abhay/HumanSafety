require('dotenv').config();
const express = require('express');
const cors = require('cors');
const jwt = require('jsonwebtoken');
const http = require('http');
const WebSocket = require('ws');
const connectDB = require('./config/db');

const authRoutes = require('./routes/auth.routes');
const userRoutes = require('./routes/user.routes');
const contactRoutes = require('./routes/contact.routes');
const emergencyRoutes = require('./routes/emergency.routes');
const emergencyWorkflowRoutes = require('./routes/emergency_workflow.routes');
const helpRoutes = require('./routes/help.routes');
const hospitalRoutes = require('./routes/hospital.routes');
const accidentRoutes = require('./routes/accident.routes');
const settingsRoutes = require('./routes/settings.routes');
const policeRoutes = require('./routes/police.routes');
const hospitalAdminRoutes = require('./routes/hospital_admin.routes');
const adminRoutes = require('./routes/admin.routes');
const caseRoutes = require('./routes/case.routes');

const { getRealtimeService } = require('./services/realtime_event_service');
const FailureHandlingService = require('./services/failure_handling_service');

const app = express();
connectDB();

// ================= SAFE MIDDLEWARE =================
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));
app.use(cors());

app.use((req, res, next) => {
  req.requestId = `REQ-${Date.now()}-${Math.random().toString(36).slice(2)}`;
  req.ipAddress = req.ip;
  req.timestamp = Date.now();
  next();
});

// ================= ROUTES =================
app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/user', userRoutes);
app.use('/api/v1/contact', contactRoutes);
app.use('/api/v1/emergency', emergencyRoutes);
app.use('/api/v1/emergency-workflow', emergencyWorkflowRoutes);
app.use('/api/v1/help', helpRoutes);
app.use('/api/v1/hospital', hospitalRoutes);
app.use('/api/v1/accident', accidentRoutes);
app.use('/api/v1/settings', settingsRoutes);
app.use('/api/v1/police', policeRoutes);
app.use('/api/v1/hospital-admin', hospitalAdminRoutes);
app.use('/api/v1/admin', adminRoutes);
app.use('/api/v1/case', caseRoutes);

// Legacy routes (safe wrapper)
[
  ['/auth', authRoutes],
  ['/user', userRoutes],
  ['/contact', contactRoutes],
  ['/emergency', emergencyRoutes],
  ['/emergency-workflow', emergencyWorkflowRoutes],
  ['/help', helpRoutes],
  ['/hospital', hospitalRoutes],
  ['/accident', accidentRoutes],
  ['/settings', settingsRoutes],
  ['/police', policeRoutes],
  ['/hospital-admin', hospitalAdminRoutes],
  ['/admin', adminRoutes],
  ['/case', caseRoutes],
].forEach(([path, handler]) => app.use(path, handler));

// ================= HEALTH =================
app.get('/health', (req, res) => {
  res.json({ status: 'ok', service: 'HumanSafety Backend v3' });
});

// ================= ERROR HANDLING =================
app.use((req, res) => {
  res.status(404).json({ error: 'Route not found', path: req.path });
});

app.use((err, req, res, next) => {
  console.error('ERROR:', err.message);
  res.status(err.status || 500).json({
    error: err.message || 'Internal Server Error',
    requestId: req.requestId,
  });
});

// ================= SERVER =================
const PORT = process.env.PORT || 5000;
const server = http.createServer(app);

// ================= JWT SAFE CHECK =================
if (!process.env.JWT_SECRET) {
  console.error('❌ JWT_SECRET missing in environment');
  process.exit(1);
}

// ================= WEBSOCKET =================
const wss = new WebSocket.Server({ server, path: '/ws' });
const realtimeService = getRealtimeService();

wss.on('connection', (ws, req) => {
  try {
    const url = new URL(req.url, `http://${req.headers.host}`);

    const userId = url.searchParams.get('userId');
    const role = url.searchParams.get('role') || 'user';
    const token = url.searchParams.get('token');

    if (!token || !userId) {
      ws.close(1008, 'Missing auth');
      return;
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    if (decoded.userId !== userId) {
      ws.close(1008, 'Invalid token');
      return;
    }

    realtimeService.registerClient(userId, ws, role);

    ws.on('message', (data) => {
      try {
        const msg = JSON.parse(data);
      } catch {}
    });

    ws.on('close', () => realtimeService.unregisterClient(userId, ws));
    ws.on('error', () => realtimeService.unregisterClient(userId, ws));

  } catch (err) {
    console.error('WS error:', err.message);
    ws.close();
  }
});

// ================= BACKGROUND SAFETY =================
setInterval(async () => {
  try {
    await FailureHandlingService.checkTimeouts();
  } catch (e) {
    console.error('Timeout service error:', e.message);
  }
}, 10000);

setInterval(async () => {
  try {
    await FailureHandlingService.systemHealthCheck();
  } catch (e) {
    console.error('Health check error:', e.message);
  }
}, 60000);

// ================= START =================
server.listen(PORT, '0.0.0.0', () => {
  console.error(`Server running on ${PORT}`);
});