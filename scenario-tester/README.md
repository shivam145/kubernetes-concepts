# 🚀 Scenarios Tester (API-based)

This service simulates Kubernetes scenarios like readiness, liveness, scaling, etc., 
via simple REST APIs. It’s containerized so you can run it in Kubernetes alongside your demos.

---

## 🛠 Build & Run Locally
```bash
docker build -t scenarios-tester .
docker run -p 8083:8083 scenarios-tester
