#!/usr/bin/env bash

# Script to generate patch manifests to control labels for each cluster

if [[ ! -d "base" ]]; then
  mkdir -p base
fi

if [[ ! -d "overlays" ]]; then
  mkdir -p overlays
fi

if [[ ! -d "components" ]]; then
  mkdir -p components
fi

for secret in $(kubectl -n argocd get secrets -l 'argocd.argoproj.io/secret-type=cluster' --no-headers -o custom-columns=:metadata.name); do
  # TODO: Wrap into a function instead because this is rather repetitive
  if [[ ! -f "base/$secret.yaml" ]]; then
    cat <<EOF | tee "base/$secret.yaml"
apiVersion: v1
kind: Secret
metadata:
  name: $secret
  labels:
    # Don't modify anything here! Modify it in overlays/$secret.yaml instead!
    argocd.argoproj.io/secret-type: cluster
EOF
  fi

  if [[ ! -f "overlays/$secret.yaml" ]]; then
    cat <<EOF | tee "overlays/$secret.yaml"
apiVersion: v1
kind: Secret
metadata:
  name: $secret
  labels:
    # Do not remove the argocd.argoproj label!
    argocd.argoproj.io/secret-type: cluster
    # Your cluster specific labels here...
EOF
  fi
  if [[ ! -f "base/kustomization.yaml" ]]; then
    cat <<EOF | tee "base/kustomization.yaml"
resources:
  - $secret.yaml
EOF
  else
    if ! `cat base/kustomization.yaml | grep -q "$secret"`; then
      echo "Adding $secret to kustomization.yaml..."
      printf "%2s- $secret.yaml\n" >> base/kustomization.yaml
    else
      echo "$secret already exists in base/kustomization.yaml. Not adding to kustomization.yaml"
    fi
  fi

  if [[ ! -f "components/kustomization.yaml" ]]; then
    cat <<EOF | tee "components/kustomization.yaml"
apiVersion: kustomize.config.k8s.io/v1alpha1
kind: Component

# Labels to apply to all cluster secrets
# These will be overwritten by the cluster-specific files in overlays
commonLabels:
  k8s.labs.ahinh.me/cluster-os: linux
EOF
  fi

  if [[ ! -f "overlays/kustomization.yaml" ]]; then
    cat <<EOF | tee "overlays/kustomization.yaml"
resources:
  - ../base

# Components is where the common labels configuration lies
components:
  - ../components

# Map to patch existing secrets. Avoid modifying by hand if possible! Use generate-cluster-manifest.sh to add/remove secrets as needed
patchesStrategicMerge:
  - $secret.yaml
EOF
  else
    if ! `cat overlays/kustomization.yaml | grep -q "$secret"`; then
      echo "Adding $secret to kustomization.yaml..."
      printf "%2s- $secret.yaml\n" >> overlays/kustomization.yaml
    else
      echo "$secret already exists in overlays/kustomization.yaml. Not adding to kustomization.yaml"
    fi
  fi
done