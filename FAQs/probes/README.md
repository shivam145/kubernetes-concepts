# 📖 FAQ – Probes in Kubernetes

## ❓ Is a **startup probe** required if readiness is in place?

Not always.

* Use a **startup probe** if your app takes a **long time to initialize** (e.g., large DB migrations, cache warm-up).
* It disables liveness/readiness checks until startup succeeds, preventing premature restarts.
* If your app starts quickly → readiness probe alone is usually enough.

---

## ❓ Once a pod is ready, will readiness probe run again?

Yes ✅

* Readiness probe runs **continuously** at the interval you define (`periodSeconds`).
* If the probe later fails, Kubernetes removes the pod from the Service.
* Once it passes again, the pod is put back into rotation.
* This ensures only healthy pods keep receiving traffic.

---

## ❓ Why do we need a **liveness probe** if readiness already exists?

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


## ❓ What happens if none of the pods are ready, but I send traffic to the Service?

* The Service has no healthy endpoints to route to.
* Requests will typically result in **`502 Bad Gateway`** or connection failures (depends on client).
* Kubernetes does **not** “queue” or “hold” requests until pods become ready.

---


## ❓ What is the Execution Order of Probes?

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


## ❓ How should my healthcheck endpoint look like if i have dependencies like mongo, redis, nats , postgres etc

One important point is that you liveness and readiness endpoints usually will be different due to their behaviours


### 🟢 1. **Liveness Probe Endpoint (`/healthz` or `/live`)**

* Purpose: **Am I alive as a process?**
* Should be **very lightweight** (no dependency checks).
* Example: just return `200 OK` if your app is running and able to serve requests at all.
* Why: If dependency goes down (say Redis), killing/restarting your app won’t help → so liveness should not depend on external services.

```js
// Example: Express.js Liveness Check
app.get('/live', (req, res) => {
  res.status(200).send('OK');
});
```

---

### 🟡 2. **Readiness Probe Endpoint (`/ready`)**

* Purpose: **Am I ready to serve traffic?**
* Here you **should** check dependencies your app needs to serve requests.
* Example checks:

  * **Postgres**: can I open a connection & run a lightweight query (`SELECT 1`)?
  * **MongoDB**: is the driver connected and not in reconnect loop?
  * **Redis**: can I `PING` and get `PONG`?
  * **NATS**: is the client connected and subscribed successfully?

```js
// Example: Express.js Readiness Check
app.get('/ready', async (req, res) => {
  try {
    await pg.query('SELECT 1');              // Postgres
    await mongoClient.db('admin').command({ ping: 1 }); // Mongo
    await redis.ping();                      // Redis
    if (!natsConnection.isClosed()) {        // NATS
      return res.status(200).send('READY');
    }
    throw new Error("NATS not connected");
  } catch (err) {
    res.status(503).send(`NOT READY: ${err.message}`);
  }
});
```

---

### 🔎 Best Practices

* **Keep liveness cheap** → just say “yes I’m alive”.
* **Do dependency checks in readiness** → so if DB or cache is down, pod is removed from Service endpoints until healthy again.
* **Timeouts** → make each dependency check **fast (e.g., <200ms)** to avoid blocking.
* **Grace period** → sometimes during startup dependencies aren’t available immediately, so use readiness probe with `initialDelaySeconds`


---

# 🧮 Probe Tuning Decision Table

| Scenario                            | Startup Time (app only) | Dependency Readiness (DB, Redis, etc.) | Liveness Probe (initialDelay / period / timeout / failureThreshold) | Readiness Probe (initialDelay / period / timeout / failureThreshold) |
| ----------------------------------- | ----------------------- | -------------------------------------- | ------------------------------------------------------------------- | -------------------------------------------------------------------- |
| **Fast app, no heavy deps**         | < 5s                    | N/A                                    | 5s / 10s / 2s / 3                                                   | 5s / 10s / 2s / 3                                                    |
| **Medium app, DB/cache needed**     | 5–15s                   | < 10s                                  | 5s / 10s / 2s / 3                                                   | 15s / 10s / 3s / 3                                                   |
| **Slow app, DB takes time**         | 15–30s                  | 10–20s                                 | 10s / 10s / 3s / 3                                                  | 30s / 10s / 5s / 3                                                   |
| **Very slow startup (legacy/Java)** | > 30s                   | > 20s                                  | 20s / 15s / 5s / 5                                                  | 45s / 15s / 5s / 3                                                   |
| **Worker job (not user-facing)**    | < 10s                   | Optional                               | 5s / 30s / 2s / 3                                                   | Optional (skip or set high values if needed)                         |

---

## 🔎 How to Use This Table

1. **Measure** your app’s startup (process) + dependency readiness (DB, cache, MQ).
2. Pick the closest scenario row.
3. Apply the suggested values, then **tune with chaos tests & monitoring**.

---

## 🚦 Quick Rules of Thumb

* **Liveness probes**:

  * Keep simple (check only app, not external deps).
  * Shorter delays & periods → faster recovery.
* **Readiness probes**:

  * Include dependency checks.
  * Longer delays → avoids sending traffic too early.
* **Batch/Worker pods**: often don’t need readiness, only liveness.

---

👉 This way, your team doesn’t have to “guess” — they just classify the app into one of the categories.

Do you want me to also give you a **YAML snippet template per row** so that people can copy-paste the right probe configs quickly?


