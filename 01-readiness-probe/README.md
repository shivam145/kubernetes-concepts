
# 📘 Readiness Probes in Kubernetes

### 🔎 What is a Readiness Probe?

A **readiness probe** is a health check in Kubernetes that tells **when a Pod is ready to serve traffic**.

* Think of it like a restaurant kitchen light:

  * 🔴 Red light = "Not ready yet, don’t send in customers"
  * 🟢 Green light = "We’re ready, start serving!"

When the readiness probe fails:

* The pod **stays running**, but **is removed from the Service endpoints**.
* No traffic is routed to it until the probe succeeds.

This prevents users from hitting pods that are still **starting up** or **temporarily overloaded**.

---

### ✅ Why is it used?

* Ensures traffic only goes to **healthy, ready pods**.
* Avoids serving errors when your app is **booting**, **loading configs**, or **warming caches**.
* Supports smooth **rolling updates** (new pods won’t get traffic until ready).

---

### 🛠️ Example Use Case

Imagine a Node.js app that:

* Takes **20 seconds to connect to a database** after starting.
* If traffic is sent during those 20 seconds, requests will fail.

With a readiness probe, Kubernetes will **wait until the probe passes** before adding the pod to the Service → users always get 200 OK instead of failures.

---

### 📜 Example Readiness Probe Configuration

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
        - name: my-app
          image: my-app:latest
          ports:
            - containerPort: 3000
          readinessProbe:
            httpGet:
              path: /healthz       # endpoint to check
              port: 3000
            initialDelaySeconds: 5 # wait before first check
            periodSeconds: 10      # check interval
            timeoutSeconds: 2      # probe timeout
            successThreshold: 1    # consecutive successes required
            failureThreshold: 3    # consecutive failures before marking unready
```

---

### ⚙️ Readiness Probe Parameters

| Parameter                        | Description                                                        |
| -------------------------------- | ------------------------------------------------------------------ |
| `httpGet` / `tcpSocket` / `exec` | Type of probe (HTTP request, TCP check, or custom command).        |
| `initialDelaySeconds`            | How long to wait **after container starts** before first probe.    |
| `periodSeconds`                  | How often to run the probe.                                        |
| `timeoutSeconds`                 | How long to wait for a probe response before marking it as failed. |
| `successThreshold`               | How many consecutive successes are needed to mark the pod ready.   |
| `failureThreshold`               | How many consecutive failures are needed to mark the pod unready.  |

---



# Readiness Probe Demo

## Before
Pods are marked ready immediately after starting. The service may send traffic before the app is ready, causing failures.

## After
Readiness probe ensures pods only receive traffic when they are truly ready (`/readyz` endpoint).

### Run Demo
```bash
kubectl apply -f before/
# Watch pods & service, note failures when app starts
kubectl delete -f before/

kubectl apply -f after/
# Pods will only be ready when /readyz passes
