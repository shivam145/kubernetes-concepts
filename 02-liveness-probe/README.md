# 🩺 Liveness Probes in Kubernetes

### 🔎 What is a Liveness Probe?

A **liveness probe** is a health check in Kubernetes that tells **whether a Pod is still alive or stuck**.

* Think of it like a robot toy:

  * 🤖 If the robot is moving → it’s alive.
  * 🛑 If the robot’s light is on but it’s frozen → it looks alive, but it’s really stuck.

When the liveness probe fails:

* Kubernetes will **restart the container automatically**.
* This helps recover apps that are **hanging, deadlocked, or not responding**, even if the process is technically still running.

---

### ✅ Why is it used?

* Detects and fixes apps that are **stuck but not crashed**.
* Ensures your system **self-heals** without manual intervention.
* Protects users from being served by unresponsive pods.

---

### 🛠️ Example Use Case

Imagine a Node.js app that:

* Gets stuck in an **infinite loop** or **memory leak**.
* The process is still alive, but it **never responds to requests**.

Without a liveness probe → the pod will stay frozen forever.
With a liveness probe → Kubernetes will detect the issue and **restart the pod**, bringing it back to a healthy state.

---

# Liveness Probe Demo

## Before
If the app becomes unhealthy, the pod stays running forever without recovery.

## After
Liveness probe checks `/healthz`. If it fails, Kubernetes restarts the container automatically.


## 📂 Structure

* `before/` → Deployment and Service **without liveness probes**.
* `after/` → Deployment and Service **with liveness probes**.

---

## 🚀 How to Run

### Option 1: Use the Script

Run the prebuilt demo script from the `scripts/` folder:

```bash
cd ../../scripts
./run-liveness-demo.sh
```

This will automatically apply both cases, simulate pod failures, generate traffic, and show results.

### Option 2: Run Manually

Apply manifests directly:

```bash
# Run "before" case
kubectl apply -f before/

# Simulate failure (e.g., toggle health endpoint)
kubectl exec -it deploy/liveness-before -- curl localhost:3000/toggle-health

# Run "after" case
kubectl apply -f after/
kubectl exec -it deploy/liveness-after -- curl localhost:3000/toggle-health
```

---

## 🧪 Experiment

You can tweak:

* Liveness probe configuration (`httpGet`, `initialDelaySeconds`, `failureThreshold`, etc.)
* Failure simulation by toggling health or modifying the app code.
* Observe how Kubernetes restarts unhealthy pods **only when liveness probes are enabled**.

This helps visualize how liveness probes protect your workloads from stuck or unresponsive containers.

