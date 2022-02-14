# MWT plan

The MWT (mixed workload test) benchmark is designed to follow these steps:

1. run the Kafka and ZooKeeper operators on an attached cluster

1. run Kafka and ZooKeeper clusters on an attached cluster

1. run a deployment of 100 replicas of [consumer and producer workload](./workload-large/workload.yaml)

1. move to producer intensive workload 199 pods of producer pods and 1 pod of consumer workload

1. move to consumer intensive workload 199 pods of consumer pods and 1 pod of producer workload

## Setting up the MWT

### Prerequisites

- A Kubernetes cluster
- Kommander installed on the cluster
- A Kommander Workspace with the dkp-catalog-applications GitRepository deployed and a Project with one attached cluster

### Creating the Kafka and ZooKeeper clusters

```bash
export ATTACHED_CLUSTER_KUBECONFIG_PATH=<path to attached cluster kubeconfig>
export WORKSPACE_NAMESPACE=<workspace namespace>
export PROJECT_NAMESPACE=<project namespace
./kafka-setup-mwt.sh
```

### Running workloads

The current configuration comes with two workloads types `small` and `large`

`small` is intended to run in a KIND or local cluster. `large` is for a cluster that should be ready for production usage.

```bash
export ATTACHED_CLUSTER_KUBECONFIG_PATH=<path to attached cluster kubeconfig>
export PROJECT_NAMESPACE=<project namespace
./kafka-run-mwt-small.sh
```

Or

```bash
export ATTACHED_CLUSTER_KUBECONFIG_PATH=<path to attached cluster kubeconfig>
export PROJECT_NAMESPACE=<project namespace
./kafka-run-mwt-large.sh
```

These commands can be ran consecutively and won't create a parallel workloads but would just change the size of workload.

### Viewing metrics

Kafka broker metrics can be viewed in Prometheus.

Grafana Dashboard: https://grafana.com/grafana/dashboards/11962

### Tearing down the resources

```bash
export ATTACHED_CLUSTER_KUBECONFIG_PATH=<path to attached cluster kubeconfig>
export WORKSPACE_NAMESPACE=<workspace namespace>
export PROJECT_NAMESPACE=<project namespace
./kafka-teardown-mwt.sh
```
