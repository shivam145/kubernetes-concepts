# Liveness Probe Demo

## Before
If the app becomes unhealthy, the pod stays running forever without recovery.

## After
Liveness probe checks `/healthz`. If it fails, Kubernetes restarts the container automatically.

### Run Demo
```bash
kubectl apply -f after/
kubectl get pods

# Simulate app failure
kubectl exec -it <pod-name> -- curl http://localhost:3000/toggle-health

# Kubernetes will restart the container when /healthz fails
