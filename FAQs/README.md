# 📖 FAQ – Probes in Kubernetes

### ❓ Is a **startup probe** required if readiness is in place?

Not always.

* Use a **startup probe** if your app takes a **long time to initialize** (e.g., large DB migrations, cache warm-up).
* It disables liveness/readiness checks until startup succeeds, preventing premature restarts.
* If your app starts quickly → readiness probe alone is usually enough.

---

### ❓ Once a pod is ready, will readiness probe run again?

Yes ✅

* Readiness probe runs **continuously** at the interval you define (`periodSeconds`).
* If the probe later fails, Kubernetes removes the pod from the Service.
* Once it passes again, the pod is put back into rotation.
* This ensures only healthy pods keep receiving traffic.

---

### ❓ Why do we need a **liveness probe** if readiness already exists?

* **Readiness Probe**

  * Answers: *“Can this pod serve traffic right now?”*
  * If it fails → pod is **removed from the Service endpoints** (no new traffic).
  * The pod/container **keeps running** in the background — it’s *not restarted*.
  * Good for **gracefully draining traffic** during temporary unavailability.

* **Liveness Probe**

  * Answers: *“Is this container alive or stuck?”*
  * If it fails → Kubernetes **kills and restarts the container**.
  * Useful when the app gets into a state where it **cannot recover on its own** (deadlock, memory leak, infinite loop).

Because they solve different problems:

| Probe Type    | What it does                     | Effect on Pod                              |
| ------------- | -------------------------------- | ------------------------------------------ |
| **Readiness** | Can I serve traffic *right now*? | Added/removed from Service load-balancer   |
| **Liveness**  | Am I alive or stuck forever?     | Pod/container is restarted if probe fails  |
| **Startup**   | Am I fully initialized yet?      | Blocks other probes until startup finishes |


---

## ❓ What happens if only one of readiness or liveliness is present?

* **Only readiness:**

  * If your app goes into a deadlock or hangs, the pod will stay running but just marked “NotReady”.
  * It won’t receive traffic, but it also won’t heal itself. Someone has to restart it.

* **Only liveness:**

  * If your app temporarily cannot serve traffic (e.g. DB is rebooting), Kubernetes will kill and restart it unnecessarily.
  * That makes things worse because the pod could have recovered naturally once DB was back.

* **Both together:**

  * **Readiness** ensures traffic goes only to healthy pods.
  * **Liveness** ensures stuck pods are restarted automatically.
  * Together they give self-healing + graceful traffic management.

---


### ❓ What happens if none of the pods are ready, but I send traffic to the Service?

* The Service has no healthy endpoints to route to.
* Requests will typically result in **`502 Bad Gateway`** or connection failures (depends on client).
* Kubernetes does **not** “queue” or “hold” requests until pods become ready.

---


### 🔄 What is the Execution Order of Probes?

1. **Startup Probe (if defined)**

   * Runs **first** and has **priority** over the others.
   * While the startup probe is running, **readiness and liveness probes are disabled**.
   * Once it succeeds → startup probe stops, and Kubernetes starts running the other probes.
   * If it fails → the container is killed & restarted.

2. **Readiness Probe**

   * Starts running **after startup probe (if any)** has succeeded.
   * Controls whether the pod is included in Service load balancing.
   * Runs periodically until the pod dies.

3. **Liveness Probe**

   * Also starts after startup probe (if any) has succeeded.
   * Runs in parallel with readiness probe.
   * If it fails, Kubernetes restarts the container (not just marks it unready).


### 📌 Simplified Flow

```
[Startup Probe] --> (succeeds) --> [Readiness + Liveness run in parallel]
                                     |
                                     +--> Readiness decides: serve traffic or not
                                     |
                                     +--> Liveness decides: restart pod or not
```

---


how should my healthcheck endpoint look like if i have depedncies like mongo, redis, nats , postgres etc