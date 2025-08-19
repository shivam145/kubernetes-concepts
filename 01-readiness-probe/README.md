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
