
#!/bin/bash
set -e
source "$(dirname "$0")/helpers.sh"

SCENARIO="liveness"
NAMESPACE="demo-$SCENARIO"
RPS=10
DURATION=20

BEFORE_DEPLOY="../02-liveness-probe/before/deployment.yaml"
BEFORE_SVC="../02-liveness-probe/before/service.yaml"
AFTER_DEPLOY="../02-liveness-probe/after/deployment.yaml"
AFTER_SVC="../02-liveness-probe/after/service.yaml"

NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
NODE_PORT=$(kubectl get svc scenario-tester-svc  -o jsonpath='{.spec.ports[0].nodePort}')
SCENARIO_RUNNER_DOMAIN="http://$NODE_IP:$NODE_PORT"

# SCENARIO_RUNNER_DOMAIN="http://172.18.0.3:32083"

mkdir -p results

create_namespace

echo "🚀 Running BEFORE case..."
kubectl apply -n $NAMESPACE -f $BEFORE_DEPLOY
kubectl get svc liveliness-before-svc -n $NAMESPACE >/dev/null 2>&1 \
  || kubectl apply -n $NAMESPACE -f $BEFORE_SVC
wait_for_rollout "${SCENARIO}-before"

SVC_BEFORE_NODE_PORT=$(kubectl -n $NAMESPACE get svc ${SCENARIO}-before-svc -o jsonpath='{.spec.ports[0].nodePort}')
# Simulate failure by toggling health endpoint (no probe to restart it)
echo "⚠️ Simulating failure in BEFORE case..."
curl -s http://${NODE_IP}:${SVC_BEFORE_NODE_PORT}/toggle-health || true

run_tester $SCENARIO "before" "http://${SCENARIO}-before-svc.${NAMESPACE}.svc.cluster.local:3000" $RPS $DURATION $SCENARIO_RUNNER_DOMAIN
cleanup_resources $BEFORE_DEPLOY
cleanup_resources $BEFORE_SVC

echo "🚀 Running AFTER case..."
kubectl apply -n $NAMESPACE -f $AFTER_DEPLOY
kubectl get svc ${SCENARIO}-after-svc -n $NAMESPACE >/dev/null 2>&1 || kubectl apply -n $NAMESPACE -f $AFTER_SVC
wait_for_rollout "${SCENARIO}-after"

SVC_AFTER_NODE_PORT=$(kubectl -n $NAMESPACE get svc ${SCENARIO}-after-svc -o jsonpath='{.spec.ports[0].nodePort}')
# Simulate failure, this time livenessProbe should restart the pod
echo "⚠️ Simulating failure in AFTER case..."
curl -s http://${NODE_IP}:${SVC_AFTER_NODE_PORT}/toggle-health || true

run_tester $SCENARIO "after" "http://${SCENARIO}-after-svc.${NAMESPACE}.svc.cluster.local:3000" $RPS $DURATION $SCENARIO_RUNNER_DOMAIN
cleanup_resources $AFTER_DEPLOY
cleanup_resources $AFTER_SVC

echo "📊 Results:"
echo "---- BEFORE ----"
cat results/${SCENARIO}-before.json
echo ""
echo "---- AFTER ----"
cat results/${SCENARIO}-after.json
