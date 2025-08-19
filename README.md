# Kubernetes Demo Scenarios

This repository contains Kubernetes demos that showcase **best practices** using simple examples.  
Each demo folder has a **before** (without best practice) and an **after** (with best practice) manifest.

### Demos Included
1. [Readiness Probe](01-readiness-probe/README.md)
2. [Liveness Probe](02-liveness-probe/README.md)

### Base Demo App
All demos use a simple Node.js Express app with endpoints:
- `/` → Root
- `/healthz` → For **livenessProbe**
- `/readyz` → For **readinessProbe**
- `/toggle-health` → Simulate failure
- `/toggle-ready` → Simulate readiness issues
- `/load` → Generate CPU load (for HPA demos later)
