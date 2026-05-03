require('dotenv').config();
const express = require('express');
const cors = require('cors');
const jwt = require('jsonwebtoken');
const http = require('http');
const WebSocket = require('ws');
const connectDB = require('./config/db');
const rateLimit = require('express-rate-limit');

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
const ambulanceRoutes = require('./routes/ambulance.routes');

const { getRealtimeService } = require('./services/realtime_event_service');
const FailureHandlingService = require('./services/failure_handling_service');

const app = express();
connectDB();

// ================= RATE LIMITING =================
const limiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS || '900000'), // 15 minutes
  max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS || '100'),
  message: 'Too many requests from this IP, please try again later.',
  standardHeaders: true, // Return rate limit info in `RateLimit-*` headers
  legacyHeaders: false, // Disable `X-RateLimit-*` headers
});

const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 5, // Stricter limit for auth endpoints
  message: 'Too many login attempts, please try again later.',
  skipSuccessfulRequests: false,
});

// ================= SECURITY MIDDLEWARE =================
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));

// CORS: Restrict to known origins in production, but allow local Flutter web ports
const allowedOrigins = (process.env.CORS_ORIGIN || 'http://localhost:3000')
  .split(',')
  .map((origin) => origin.trim())
  .filter(Boolean);

const corsOptions = {
  origin: (origin, callback) => {
    if (!origin) {
      return callback(null, true);
    }

    const isLocalDevOrigin = /^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/.test(origin);
    const isAllowedOrigin = allowedOrigins.includes(origin);

    if (isAllowedOrigin || isLocalDevOrigin) {
      return callback(null, true);
    }

    return callback(new Error(`CORS blocked for origin: ${origin}`));
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
};
app.use(cors(corsOptions));

// Request ID tracking
app.use((req, res, next) => {
  req.requestId = `REQ-${Date.now()}-${Math.random().toString(36).slice(2)}`;
  req.ipAddress = req.ip;
  req.timestamp = Date.now();
  next();
});

// Apply rate limiting globally (except health check)
app.use((req, res, next) => {
  if (req.path === '/health') return next();
  limiter(req, res, next);
});

// ================= ROUTES =================
// Apply stricter rate limiting to auth endpoints
app.use('/api/v1/auth', authLimiter, authRoutes);
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
app.use('/api/v1/ambulance', ambulanceRoutes);


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
        
        // Route message based on type
        switch (msg.type) {
          case 'subscribe':
            // Subscribe to a specific channel/topic
            realtimeService.subscribeToChannel(userId, msg.channel);
            ws.send(JSON.stringify({
              type: 'SUBSCRIPTION_CONFIRMED',
              channel: msg.channel,
              timestamp: new Date().toISOString()
            }));
            break;
            
          case 'unsubscribe':
            // Unsubscribe from a channel
            realtimeService.unsubscribeFromChannel(userId, msg.channel);
            ws.send(JSON.stringify({
              type: 'UNSUBSCRIPTION_CONFIRMED',
              channel: msg.channel,
              timestamp: new Date().toISOString()
            }));
            break;
            
          case 'location_update':
            // User sending real-time location update
            if (msg.latitude && msg.longitude) {
              realtimeService.broadcastByRole('admin', {
                type: 'LOCATION_UPDATE',
                userId,
                location: {
                  latitude: msg.latitude,
                  longitude: msg.longitude,
                  accuracy: msg.accuracy
                },
                timestamp: new Date().toISOString()
              });
            }
            break;

          case 'ambulance_location_update':
            // Ambulance sending real-time GPS location
            if (msg.ambulanceId && msg.latitude && msg.longitude) {
              realtimeService.broadcastByRole('hospital', {
                type: 'AMBULANCE_LOCATION_UPDATE',
                ambulanceId: msg.ambulanceId,
                location: {
                  latitude: msg.latitude,
                  longitude: msg.longitude,
                  accuracy: msg.accuracy
                },
                eta: msg.eta,
                status: msg.status,
                timestamp: new Date().toISOString()
              });
              // Also broadcast to admin
              realtimeService.broadcastByRole('admin', {
                type: 'AMBULANCE_LOCATION_UPDATE',
                ambulanceId: msg.ambulanceId,
                location: {
                  latitude: msg.latitude,
                  longitude: msg.longitude,
                  accuracy: msg.accuracy
                },
                eta: msg.eta,
                status: msg.status,
                timestamp: new Date().toISOString()
              });
            }
            break;
            
          case 'case_status_request':
            // Client requesting case status update
            if (msg.caseId) {
              // In real impl, fetch case from DB and send status
              realtimeService.sendToClient(userId, {
                type: 'CASE_STATUS',
                caseId: msg.caseId,
                // status would be fetched from database
                timestamp: new Date().toISOString()
              });
            }
            break;
            
          case 'ping':
            // Respond to ping (keep-alive)
            ws.send(JSON.stringify({
              type: 'pong',
              timestamp: new Date().toISOString()
            }));
            break;
            
          default:
            // Unknown message type - log but don't error
            console.warn(`Unknown WebSocket message type: ${msg.type} from ${userId}`);
        }
      } catch (parseError) {
        console.error('WebSocket message parse error:', parseError.message);
        ws.send(JSON.stringify({
          type: 'ERROR',
          message: 'Invalid message format',
          timestamp: new Date().toISOString()
        }));
      }
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