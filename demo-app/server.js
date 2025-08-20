const express = require('express');
const app = express();
const port = process.env.PORT || 3000;

let isHealthy = true;
let isReady = true;
let startUpDelay =  parseInt(process.env.START_UP_DELAY) || 5000;
// Root endpoint
app.get('/', (req, res) => {
    if (!isHealthy) {
        while(true) {}
    }
  res.send('Hello from Kubernetes Demo App 🚀');
});

// Health (for livenessProbe)
app.get('/healthz', (req, res) => {
  if (isHealthy) {
    res.status(200).send('OK - Healthy');
  } else {
    res.status(500).send('NOT Healthy');
  }
});

// Readiness (for readinessProbe)
app.get('/readyz', (req, res) => {
  if (isReady) {
    res.status(200).send('OK - Ready');
  } else {
    res.status(500).send('NOT Ready');
  }
});

// Toggle health (simulate failure)
app.get('/toggle-health', (req, res) => {
  isHealthy = !isHealthy;
  res.send(`Health set to ${isHealthy}`);
});

// Toggle readiness (simulate failure)
app.get('/toggle-ready', (req, res) => {
  isReady = !isReady;
  res.send(`Ready set to ${isReady}`);
});

// Load generator for HPA testing
app.get('/load', (req, res) => {
  const end = Date.now() + 5000; // 5 seconds CPU work
  while (Date.now() < end) {}
  res.send('Did some heavy CPU work 💪');
})

setTimeout(() => {
    app.listen(port, () => {
        console.log(`Demo app running on port ${port}`);
    })
}, startUpDelay);
