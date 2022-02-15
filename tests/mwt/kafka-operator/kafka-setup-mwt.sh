#!/bin/bash
set -e

: "${ATTACHED_CLUSTER_KUBECONFIG_PATH:?"ATTACHED_CLUSTER_KUBECONFIG_PATH environment variable is not set"}"
: "${WORKSPACE_NAMESPACE:?"WORKSPACE_NAMESPACE environment variable is not set"}"
: "${PROJECT_NAMESPACE:?"PROJECT_NAMESPACE environment variable is not set"}"

# Create catalog Git Repo
kubectl apply -f ./manifests/dkp-catalog-applications.yaml -n "$WORKSPACE_NAMESPACE"

# Wait for Git Repo to be ready
kubectl wait -n "$WORKSPACE_NAMESPACE" --timeout=300s GitRepository dkp-catalog-applications \
  --for=condition=Ready

# Create app deployments on management cluster
kubectl apply -f ./manifests/zookeeper-appd.yaml -n "$WORKSPACE_NAMESPACE"
kubectl apply -f ./manifests/kafka-appd.yaml -n "$WORKSPACE_NAMESPACE"

# Validate helm release status for kafka/zk operators on attached cluster
while true; do
  if kubectl wait -n "$WORKSPACE_NAMESPACE" helmreleases --for=condition=Ready kafka-operator-1 zookeeper-operator-1 --kubeconfig "$ATTACHED_CLUSTER_KUBECONFIG_PATH"; then
    break
  fi
  sleep 10
done

# Deploy zookeeper on attached cluster
kubectl apply -f ./manifests/zookeeper.yaml -n "$PROJECT_NAMESPACE" --kubeconfig "$ATTACHED_CLUSTER_KUBECONFIG_PATH"

# wait for the zookeeper cluster to be ready
kubectl wait -n "$PROJECT_NAMESPACE" --timeout=300s Zookeeperclusters zookeeper \
  --for=condition=PodsReady \
  --kubeconfig "$ATTACHED_CLUSTER_KUBECONFIG_PATH"

# Deploy kafka
if [ -z "$RUN_SMALL_KAFKA" ]; then
  sed "s/zookeeper-client.zookeeper:2181/zookeeper-client.${PROJECT_NAMESPACE}:2181/g" ./manifests/kafka-small-brokers.yaml | kubectl apply -n "$PROJECT_NAMESPACE" --kubeconfig "$ATTACHED_CLUSTER_KUBECONFIG_PATH" -f -
else
  # Set RUN_SMALL_KAFKA to run a smaller kafka setup (less brokers/less resources)
  sed "s/zookeeper-client.zookeeper:2181/zookeeper-client.${PROJECT_NAMESPACE}:2181/g" ./manifests/kafka.yaml | kubectl apply -n "$PROJECT_NAMESPACE" --kubeconfig "$ATTACHED_CLUSTER_KUBECONFIG_PATH" -f -
fi

# Wait for the kafka cluster to be ready
while true; do
  if [ "$(kubectl get kafkacluster kafka -n "$PROJECT_NAMESPACE" --kubeconfig "$ATTACHED_CLUSTER_KUBECONFIG_PATH" -o jsonpath='{.status.state}')" = "ClusterRunning" ]; then
    break
  fi
  echo "waiting for kafka cluster to be running"
  sleep 10
done
