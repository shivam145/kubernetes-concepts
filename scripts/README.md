# Kubernetes Demo Scripts

This repo contains demo scripts to showcase **various reliability and availability configurations** in Kubernetes.
The scripts automatically deploy sample apps, simulate failures, and compare the difference **before** and **after**

---

## 📂 Available Demo Scripts

All demo scripts live under the `scripts/` folder:

* `run-readiness-demo.sh` → Shows how **readiness probes** prevent traffic being sent to unready pods during scaling.
* `run-liveness-demo.sh` → Shows how **liveness probes** automatically restart stuck pods and recover service.

Each script creates a temporary namespace, runs both scenarios, and prints summarized results.

---

## 🚀 How to Run

1. Ensure you have:

   * Access to a running Kubernetes cluster (`kubectl` configured).
   * A running **scenario runner service** (used to generate traffic).

2. Run any demo script:

   ```bash
   cd scripts
   ./run-readiness-demo.sh
   ```

   or

   ```bash
   ./run-liveness-demo.sh
   ```

3. Watch the script:

   * Deploys **before** scenario (without probe).
   * Scales pods and simulates failure.
   * Collects request results.
   * Cleans up.
   * Deploys **after** scenario (with probe).
   * Runs the same test and shows improvements.

---

## 📊 Example Output

```
🚀 Running BEFORE case...
📡 Running tester against http://readiness-before-svc.demo-readiness.svc.cluster.local:3000 ...
---- BEFORE ----
{"message":"Scenario 'readiness' completed","result":{"totalRequests":190,"statusCounts":{"200":90,"NO_RESPONSE":100}}}

🚀 Running AFTER case...
📡 Running tester against http://readiness-after-svc.demo-readiness.svc.cluster.local:3000 ...
---- AFTER ----
{"message":"Scenario 'readiness' completed","result":{"totalRequests":190,"statusCounts":{"200":190}}}
```

---

## 🧪 Create Your Own Scenarios

These scripts provide **base scenarios**
You can also **experiment with your own cases** by:

* Running the `before/` and `after/` manifests manually:

  ```bash
  kubectl apply -f 01-readiness-probe/before/
  kubectl apply -f 01-readiness-probe/after/
  ```
* Modifying probe settings, app behavior, or scaling patterns.
* Using the `helpers.sh` functions to build new scenario scripts.

---

## 🛠 Helpers

All scripts share a `helpers.sh` with utilities:

* `create_namespace` → Create demo namespace.
* `wait_for_rollout` → Wait for deployments to be ready.
* `cleanup_resources` → Delete manifests cleanly.
* `run_tester` → Trigger load test via scenario runner.

You can extend this for new scenarios (e.g., startup probes, custom failure injections).

---

## 🧹 Cleanup

Each script auto-deletes resources after completion.
If you need to force cleanup manually:

```bash
kubectl delete ns demo-readiness --ignore-not-found
kubectl delete ns demo-liveness --ignore-not-found
```

