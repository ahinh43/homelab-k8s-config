#!/usr/bin/env bash

# https://kubevirt.io/user-guide/operations/installation/
# To be replaced with a Helm chart once available
# https://github.com/kubevirt/kubevirt/issues/8347

set -euxo pipefail

# Point at latest release
export RELEASE=$(curl https://storage.googleapis.com/kubevirt-prow/release/kubevirt/kubevirt/stable.txt)
# Deploy the KubeVirt operator
kubectl apply -f https://github.com/kubevirt/kubevirt/releases/download/${RELEASE}/kubevirt-operator.yaml --context kube
# Create the KubeVirt CR (instance deployment request) which triggers the actual installation
kubectl apply -f https://github.com/kubevirt/kubevirt/releases/download/${RELEASE}/kubevirt-cr.yaml --context kube
# wait until all KubeVirt components are up
kubectl -n kubevirt wait kv kubevirt --for condition=Available --context kube