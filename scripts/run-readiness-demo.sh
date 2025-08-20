#!/bin/bash
set -e
source "$(dirname "$0")/helpers.sh"

SCENARIO="readiness"
NAMESPACE="demo-$SCENARIO"
RPS=10
DURATION=20

BEFORE_DEPLOY="../01-readiness-probe/before/deployment.yaml"
BEFORE_SVC="../01-readiness-probe/before/service.yaml"
AFTER_DEPLOY="../01-readiness-probe/after/deployment.yaml"
AFTER_SVC="../01-readiness-probe/after/service.yaml"
SCENARIO_RUNNER_DOMAIN="http://172.18.0.3:32083"

mkdir -p results

create_namespace

echo "🚀 Running BEFORE case..."
kubectl apply -n $NAMESPACE -f $BEFORE_DEPLOY
kubectl apply -n $NAMESPACE -f $BEFORE_SVC
wait_for_rollout "${SCENARIO}-before"

kubectl scale -n $NAMESPACE deploy/${SCENARIO}-before --replicas=5


run_tester $SCENARIO "before" "http://${SCENARIO}-before-svc.${NAMESPACE}.svc.cluster.local:3000" $RPS $DURATION $SCENARIO_RUNNER_DOMAIN
cleanup_resources $BEFORE_DEPLOY
cleanup_resources $BEFORE_SVC

echo "🚀 Running AFTER case..."
kubectl apply -n $NAMESPACE -f $AFTER_DEPLOY
kubectl apply -n $NAMESPACE -f $AFTER_SVC
wait_for_rollout "${SCENARIO}-after"

kubectl scale -n $NAMESPACE deploy/${SCENARIO}-after --replicas=5


run_tester $SCENARIO "after" "http://${SCENARIO}-after-svc.${NAMESPACE}.svc.cluster.local:3000" $RPS $DURATION $SCENARIO_RUNNER_DOMAIN
cleanup_resources $AFTER_DEPLOY
cleanup_resources $AFTER_SVC

echo "📊 Results:"
echo "---- BEFORE ----"
cat results/${SCENARIO}-before.json
echo ""
echo "---- AFTER ----"
cat results/${SCENARIO}-after.json
