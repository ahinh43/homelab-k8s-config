#!/usr/bin/env bash

# Finds all the ArgoCD defined cluster secrets and adds the label passed in the argument to them
while getopts a:n:l: flag
do
    case "${flag}" in
        a) label=${OPTARG};;
        n) clusterName=${OPTARG};;
        l) clusterLabelFilter=${OPTARG};;
    esac
done

if [[ -n "$clusterName" ]]; then
  secret=$(kubectl -n argocd --context kube get secrets -l 'argocd.argoproj.io/secret-type=cluster' -l "k8s.labs.ahinh.me/cluster-name=$clusterName"  --no-headers -o custom-columns=:metadata.name)
  kubectl -n argocd --context kube label secret $secret $label --overwrite
  echo "Labeling $secret with $label..."
elif [[ -n "$clusterLabelFilter" ]]; then
  secret=$(kubectl -n argocd --context kube get secrets -l 'argocd.argoproj.io/secret-type=cluster' -l "$clusterLabelFilter" --no-headers -o custom-columns=:metadata.name)
  kubectl -n argocd --context kube label secret $secret $label --overwrite
  echo "Labeling $secret with $label..."
else
  for secret in `kubectl -n argocd --context kube get secrets -l 'argocd.argoproj.io/secret-type=cluster'  --no-headers -o custom-columns=:metadata.name`; do
    echo "Labeling $secret with $label..."
    kubectl -n argocd --context kube label secret $secret $label --overwrite
  done
fi


