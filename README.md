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




# ⚙️ Prerequisites for Running Kubernetes Probe Demos

Before running the scripts, please make sure you’ve set up the following:

---

## 🏗️ 1. Setup a Kind Cluster

We use [Kind](https://kind.sigs.k8s.io/) (Kubernetes in Docker) for these demos.

```bash

# After Installing kind

# Create a cluster
kind create cluster --name demo
```

Confirm cluster is working:

```bash
kubectl cluster-info
```

---

## 📦 2. Build and Load Docker Images

The demos require **two custom images**:

1. **demo-app** → A simple Node.js/Express app with health endpoints (`/`, `/healthz`, `/readyz` etc).
2. **scenario-tester** → A helper tool that generates traffic for “before” and “after” cases.

Build them locally:

```bash
# From repo root
docker build -t k8s-demo-app:latest:latest ./demo-app
docker build -t scenario-tester:latest ./scenario-tester
```

Load them into the kind cluster:

```bash
kind load docker-image k8s-demo-app:latest --name demo
kind load docker-image scenario-tester:latest --name demo
```

---

## 🛠️ 3. Verify Images Inside Cluster

Check that images are available:

```bash
kubectl run test --rm -it --image=demo-app:latest -- bash
```

---

## 🛠️ 4. Deploy the scenario tester

We assume the Scenario Tester runs continuously and you’ll call its API from the demo scripts.

```bash

kubectl apply -f scenario-tester/

```

---

## 🚀 5. Ready to Run

Now you can run any of the scripts in the `scripts/` folder, e.g.:

```bash
./scripts/run-readiness-demo.sh
./scripts/run-liveness-demo.sh
```

Or experiment manually with the manifests inside:

* `01-readiness-probe/before/` & `01-readiness-probe/after/`
* `02-liveness-probe/before/` & `02-liveness-probe/after/`