# ⚖️ Kubernetes Resource Requests & Limits

## 🔎 What Are They?

Kubernetes schedules containers on nodes that have finite **CPU** and **Memory**.
But pods don’t magically tell the cluster “I need X CPU and Y memory” unless you configure it.

That’s where **requests** and **limits** come in:

* **Requests** → the *minimum* amount of CPU/Memory a pod is guaranteed. Scheduler uses this to place pods.
* **Limits** → the *maximum* amount of CPU/Memory a pod can consume. If it goes beyond, K8s throttles (CPU) or kills it (OOM).

---

## 🍽️ Analogy

Imagine Kubernetes nodes as a **buffet hall** with limited plates (resources):

* **Requests = reserved plate size** 🥗
  You book at least this much food ahead of time. The waiter (scheduler) only seats you if enough is available.

* **Limits = maximum allowed food on your plate** 🍔
  You can’t pile on forever. If you try to add more:

  * CPU: waiter makes you wait → throttling.
  * Memory: plate breaks → OOMKill.

---

## 🛠️ How They Work in Practice

### CPU

* Measured in **cores (millicores)**.

  * `500m` = 0.5 CPU core.
  * `1000m` = 1 CPU core.

* Behavior:

  * If usage > limit → throttled (not killed).
  * If usage < request → doesn’t matter, just gets what it needs.

### Memory

* Measured in **bytes (Mi, Gi, etc.)**.

* Behavior:

  * If usage > limit → container is **OOMKilled** (killed and restarted).
  * If usage > request but < limit → allowed, but scheduler didn’t plan for it.

---

## 🧪 Example Without Requests & Limits

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: no-limits
spec:
  containers:
    - name: app
      image: demo-app:latest
      resources: {}
```

❌ Problems:

* Scheduler has no idea how much this pod needs.
* It may get packed tightly with others → risk of OOM kills.
* A single greedy pod may hog CPU/memory, starving others.

---

## 🧪 Example With Requests & Limits

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: with-limits
spec:
  containers:
    - name: app
      image: demo-app:latest
      resources:
        requests:
          cpu: "200m"
          memory: "256Mi"
        limits:
          cpu: "500m"
          memory: "512Mi"
```

✅ Behavior:

* Pod won’t be scheduled unless a node has **200m CPU & 256Mi memory** free.
* Pod can burst up to **500m CPU & 512Mi memory**.
* Beyond this → CPU throttled, Memory OOMKilled.

---

## 📊 How to Choose the Right Numbers

This is where people struggle most, so let’s break it down.

### Step 1: Observe Baseline

* Run your app locally or in a test cluster with **no limits**.
* Send realistic load.
* Record average CPU/memory usage + peak usage.

### Step 2: Set Requests

* Requests ≈ **baseline steady usage**.
* Rule: pick a value just above the *95th percentile* of steady load.

### Step 3: Set Limits

* Limits ≈ **safe upper bound (peak + headroom)**.
* Usually 1.5x – 2x the request for CPU, but **close to request for memory** (to avoid OOMs).

### Step 4: Tune Over Time

* Use **metrics-server**, Prometheus, or `kubectl top pod`.
* Adjust until pod avoids frequent throttling or OOMKills.

---

## 🔬 Before vs After Demo Scenario

We can build a **demo just like readiness/liveness**:

### 1. Before Case: No Requests & Limits

* Deploy app with CPU-hogging `/load` endpoint.
* Run load test → pod hogs CPU, other pods suffer.

### 2. After Case: With Requests & Limits

* Deploy same app with `requests` + `limits`.
* Run load test again →

  * Pod throttled at limit (CPU) or killed at OOM (Memory).
  * Other pods remain stable.

---

## ⚠️ Common Mistakes

1. **Setting requests too high** → Pods can’t schedule, cluster underutilized.
2. **Setting requests too low** → Pod gets starved under load.
3. **Setting no limits** → A noisy neighbor can take down the node.
4. **Too aggressive limits on memory** → Frequent OOMKills.
5. **Equal request = limit always** → removes burst capacity.

---

## 🎯 Key Takeaways

* **Always set requests & limits** for production workloads.
* **CPU** over limit → throttled.
* **Memory** over limit → killed.
* Choose values based on **metrics + headroom**, not guesswork.
* Foundation for **autoscaling (HPA)** and **cluster stability**.

---
