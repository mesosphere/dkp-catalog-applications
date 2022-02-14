#!/bin/bash
: "${ATTACHED_CLUSTER_KUBECONFIG_PATH:?"ATTACHED_CLUSTER_KUBECONFIG_PATH environment variable is not set"}"
: "${PROJECT_NAMESPACE:?"PROJECT_NAMESPACE environment variable is not set"}"

kubectl apply -f workload-small/workload.yaml -n "$PROJECT_NAMESPACE" --kubeconfig "$ATTACHED_CLUSTER_KUBECONFIG_PATH"

kubectl wait deployment kafka-cluster-producer-tests \
  --for=condition=available \
  -n "$PROJECT_NAMESPACE" --kubeconfig "$ATTACHED_CLUSTER_KUBECONFIG_PATH"

kubectl wait deployment kafka-cluster-consumer-tests \
  --for=condition=available \
  -n "$PROJECT_NAMESPACE" --kubeconfig "$ATTACHED_CLUSTER_KUBECONFIG_PATH"
