#!/usr/bin/env bash

# Hacky script that provisions the cluster with the basics, before letting argoCD take the rest of the job

set -exo pipefail

CERTMANAGERCRDVERSION="v1.13.2"

echo "installing CRDs"

if op whoami; then
  echo "Signed into 1password"
else
  echo "Not signed into 1password or an error happened. Check the logs for more details"
  exit $?
fi

installedChartsKube1=$(helm list --all-namespaces)
installedChartsKube2=$(helm list --kube-context kube2 --all-namespaces)

kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.0.0/standard-install.yaml --context kube
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.0.0/standard-install.yaml --context kube2

kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/${CERTMANAGERCRDVERSION}/cert-manager.crds.yaml --context kube
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/${CERTMANAGERCRDVERSION}/cert-manager.crds.yaml --context kube2


if ! grep -q "metallb" <<< "$installedChartsKube1"; then
  exho "MetalLB chart already installed. Moving on.."
else
  helm install --kube-context kube --namespace metallb-system --create-namespace metallb metalLB/
  metallbinstalled="yes"
fi

if ! grep -q "metallb" <<< "$installedChartsKube2"; then
  exho "MetalLB chart already installed. Moving on.."
else
  helm install --kube-context kube2 --namespace metallb-system --create-namespace metallb metalLB/
  metallbinstalled="yes"
fi

if [[ $metallbinstalled = "yes" ]]; then
  sleep 180
fi

if ! kubectl get ipaddresspools.metallb.io --context kube --all-namespaces | grep -q "default-pool"; then
  kubectl apply -f metalLB/kube1 --context kube
fi

if ! kubectl get ipaddresspools.metallb.io --context kube2 --all-namespaces | grep -q "default-pool"; then
  kubectl apply -f metalLB/kube2 --context kube2
fi


echo "Deploying the necessary services to get the cluster rolling..."


if ! grep -q "cert-manager" <<< "$installedChartsKube1"; then
  exho "cert-manager chart already installed. Moving on.."
else
  helm install -f cert-manager/values.yaml --kube-context kube --namespace cert-manager --create-namespace cert-manager-kube1 cert-manager/
fi

if ! grep -q "cert-manager" <<< "$installedChartsKube2"; then
  exho "cert-manager chart already installed. Moving on.."
else
  helm install -f cert-manager/values.yaml --kube-context kube2 --namespace cert-manager --create-namespace cert-manager-kube2 cert-manager/
fi



if ! grep -q "external-dns" <<< "$installedChartsKube1"; then
  exho "external-dns chart already installed. Moving on.."
else
  helm install -f external-dns/values.yaml --kube-context kube --namespace external-dns --create-namespace external-dns external-dns/
fi

if ! grep -q "external-dns" <<< "$installedChartsKube2"; then
  exho "cert-manager chart already installed. Moving on.."
else
  helm install -f external-dns/values.yaml --kube-context kube2 --namespace external-dns --create-namespace external-dns external-dns/
fi

# Cloudflare API token secret needed for cert-manager to auto complete the domain verification
kubectl create secret generic cloudflare-api-token --namespace cert-manager --from-literal=cloudflare_api_token=$(op item get "Cloudflare API Token" --vault Homelab --fields credential) --context kube
kubectl create secret generic cloudflare-api-token --namespace cert-manager --from-literal=cloudflare_api_token=$(op item get "Cloudflare API Token" --vault Homelab --fields credential) --context kube2
kubectl create secret generic cloudflare-api-token --namespace external-dns --from-literal=cloudflare_api_token=$(op item get "Cloudflare API Token" --vault Homelab --fields credential) --context kube
kubectl create secret generic cloudflare-api-token --namespace external-dns --from-literal=cloudflare_api_token=$(op item get "Cloudflare API Token" --vault Homelab --fields credential) --context kube2


kubectl apply -f cert-manager/le-prod-clusterissuer.yaml --context kube
kubectl apply -f cert-manager/le-prod-clusterissuer.yaml --context kube2

kubectl apply -f cert-manager/le-staging-clusterissuer.yaml --context kube
kubectl apply -f cert-manager/le-staging-clusterissuer.yaml --context kube2

if ! grep -q "ingress-nginx" <<< "$installedChartsKube1"; then
  exho "ingress-nginx chart already installed. Moving on.."
else
  helm install --kube-context kube --namespace ingress-nginx --create-namespace ingress-nginx-kube1 nginx-ingress/
fi

if ! grep -q "ingress-nginx" <<< "$installedChartsKube2"; then
  exho "cert-manager chart already installed. Moving on.."
else
  helm install --kube-context kube2 --namespace ingress-nginx --create-namespace ingress-nginx-kube2 nginx-ingress/
fi


if ! grep -q "argocd" <<< "$installedChartsKube2"; then
  exho "argocd chart already installed. Moving on.."
else
  helm install --kube-context kube -f argocd/values.yaml --namespace argocd --create-namespace argocd argocd/
fi

kubectl create namespace ceph-csi-rbd --context kube
kubectl create namespace ceph-csi-rbd --context kube2