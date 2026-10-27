const express = require('express');
const client = require('prom-client');

const app = express();

// Collect default Node.js metrics
client.collectDefaultMetrics();

// Home route
app.get('/', (req, res) => {
  res.json({ app: 'shivom-demo', message: 'Hello from the sample app' });
});

// Health check - used by the load balancer and smoke test
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok' });
});

// Prometheus metrics endpoint
app.get('/metrics', async (req, res) => {
  res.set('Content-Type', client.register.contentType);
  res.end(await client.register.metrics());
});

module.exports = app;