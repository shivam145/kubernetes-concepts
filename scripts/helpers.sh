#!/bin/bash
set -e

NAMESPACE=$1

create_namespace() {
  echo "📌 Ensuring namespace $NAMESPACE exists..."
  kubectl create ns $NAMESPACE 2>/dev/null || true
}

wait_for_rollout() {
  local deploy=$1
  echo "⏳ Waiting for deployment/$deploy in $NAMESPACE..."
  kubectl rollout status -n $NAMESPACE deploy/$deploy --timeout=60s
}

cleanup_resources() {
  local file=$1
  echo "🧹 Cleaning up $file..."
  kubectl delete -n $NAMESPACE -f $file --ignore-not-found
}

run_tester() {
  local scenario=$1
  local label=$2
  local target=$3
  local rps=$4
  local duration=$5
  local outfile="results/${scenario}-${label}.json"
  local scenario_runner_domain=$6

  echo "📡 Running tester against $target ..."
  curl -s -X POST "$scenario_runner_domain/run/$scenario" \
    -H "Content-Type: application/json" \
    -d "{\"target\":\"$target\", \"rps\":$rps, \"duration\":$duration}" \
    | tee $outfile
}
