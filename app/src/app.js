const express = require('express');
const client = require('prom-client');

const app = express();

// Default Node.js process metrics (CPU, memory, event loop, GC)
client.collectDefaultMetrics();

// Request metrics for error-rate and latency alerts
const httpRequests = new client.Counter({
  name: 'http_requests_total',
  help: 'Total HTTP requests',
  labelNames: ['method', 'route', 'status'],
});

const httpDuration = new client.Histogram({
  name: 'http_request_duration_seconds',
  help: 'HTTP request duration in seconds',
  labelNames: ['method', 'route', 'status'],
  buckets: [0.05, 0.1, 0.25, 0.5, 1, 2, 5],
});

app.use((req, res, next) => {
  const endTimer = httpDuration.startTimer();
  res.on('finish', () => {
    const labels = {
      method: req.method,
      route: req.route ? req.route.path : 'unmatched',
      status: String(res.statusCode),
    };
    httpRequests.inc(labels);
    endTimer(labels);
  });
  next();
});

app.get('/', (req, res) => {
  res.json({ app: 'shivom-demo', message: 'Hello from the sample app' });
});

app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok' });
});

// Deliberately returns a 500 - used to test the error-rate alert
app.get('/simulate-error', (req, res) => {
  res.status(500).json({ error: 'simulated failure' });
});

app.get('/metrics', async (req, res) => {
  res.set('Content-Type', client.register.contentType);
  res.end(await client.register.metrics());
});

module.exports = app;
