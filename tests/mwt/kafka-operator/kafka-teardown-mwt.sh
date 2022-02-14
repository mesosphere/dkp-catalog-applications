#!/bin/bash
: "${ATTACHED_CLUSTER_KUBECONFIG_PATH:?"ATTACHED_CLUSTER_KUBECONFIG_PATH environment variable is not set"}"
: "${WORKSPACE_NAMESPACE:?"WORKSPACE_NAMESPACE environment variable is not set"}"
: "${PROJECT_NAMESPACE:?"PROJECT_NAMESPACE environment variable is not set"}"

kubectl delete KafkaCluster kafka -n "$PROJECT_NAMESPACE" --kubeconfig "$ATTACHED_CLUSTER_KUBECONFIG_PATH"
kubectl delete ZookeeperCluster zookeeper -n "$PROJECT_NAMESPACE" --kubeconfig "$ATTACHED_CLUSTER_KUBECONFIG_PATH"
kubectl delete deployment kafka-cluster-producer-tests -n "$PROJECT_NAMESPACE" --kubeconfig "$ATTACHED_CLUSTER_KUBECONFIG_PATH"
kubectl delete deployment kafka-cluster-consumer-tests -n "$PROJECT_NAMESPACE" --kubeconfig "$ATTACHED_CLUSTER_KUBECONFIG_PATH"
kubectl delete deployment utils-pod -n "$PROJECT_NAMESPACE" --kubeconfig "$ATTACHED_CLUSTER_KUBECONFIG_PATH"

kubectl delete -n "$WORKSPACE_NAMESPACE" appdeployments kafka-operator-1 zookeeper-operator-1
