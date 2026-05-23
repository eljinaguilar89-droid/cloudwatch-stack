const express = require('express');
const client = require('prom-client');

const app = express();
const PORT = 3001;

// ─────────────────────────────────────────
// PROMETHEUS SETUP
// ─────────────────────────────────────────

// This one line automatically collects default metrics:
// CPU usage, memory, event loop lag, garbage collection, etc.
// You get these for free without doing anything else.
const collectDefaultMetrics = client.collectDefaultMetrics;
collectDefaultMetrics();

// COUNTER — total number of requests your app has received
// It only ever goes up. Good for tracking traffic over time.
const httpRequestCounter = new client.Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests received',
  labelNames: ['method', 'route', 'status']
  // Labels let you filter — e.g. show only GET requests, or only /hello
});

// GAUGE — how many requests are being processed RIGHT NOW
// Goes up when a request starts, down when it finishes
const activeRequests = new client.Gauge({
  name: 'http_active_requests',
  help: 'Number of requests currently being processed'
});

// HISTOGRAM — how long each request takes in seconds
// Grafana can use this to show average response time
const httpDuration = new client.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route'],
  buckets: [0.01, 0.05, 0.1, 0.3, 0.5, 1, 2]
  // Buckets are the time brackets — was it under 10ms? Under 100ms? etc.
});

// ─────────────────────────────────────────
// MIDDLEWARE
// ─────────────────────────────────────────

// This runs on every request before your routes
// It starts the timer and increments the active requests gauge
app.use((req, res, next) => {
  const end = httpDuration.startTimer({ method: req.method, route: req.path });
  activeRequests.inc();

  // When the response finishes, record the results
  res.on('finish', () => {
    activeRequests.dec();
    end(); // stops the timer and records the duration
    httpRequestCounter.inc({
      method: req.method,
      route: req.path,
      status: res.statusCode
    });
  });

  next();
});

// ─────────────────────────────────────────
// ROUTES
// ─────────────────────────────────────────

// /hello — simple endpoint to prove the app is alive
app.get('/hello', (req, res) => {
  res.json({
    message: 'Hello from CloudWatch Stack!',
    timestamp: new Date().toISOString(),
    status: 'ok'
  });
});

// /metrics — Prometheus scrapes this every 15 seconds
// prom-client formats all your metrics automatically
app.get('/metrics', async (req, res) => {
  res.set('Content-Type', client.register.contentType);
  res.end(await client.register.metrics());
});

// ─────────────────────────────────────────
// START
// ─────────────────────────────────────────

app.listen(PORT, () => {
  console.log(`App running on port ${PORT}`);
  console.log(`Metrics available at http://localhost:${PORT}/metrics`);
});