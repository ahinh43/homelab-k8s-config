#!/usr/bin/env bash

# Hacky script that provisions the cluster with the basics, before letting argoCD take the rest of the job

CERTMANAGERCRDVERSION="v1.13.2"

echo "installing CRDs"

if op whoami; then
  echo "Signed into 1password"
else
  echo "Not signed into 1password or an error happened. Check the logs for more details"
  exit $?
fi

kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.0.0/standard-install.yaml --context kube
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.0.0/standard-install.yaml --context kube2

kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/${CERTMANAGERCRDVERSION}/cert-manager.crds.yaml --context kube
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/${CERTMANAGERCRDVERSION}/cert-manager.crds.yaml --context kube2

echo "Deploying the necessary services to get the cluster rolling..."

helm install -f cert-manager/values.yaml --kube-context kube --namespace cert-manager --create-namespace cert-manager-kube1 cert-manager/
helm install -f cert-manager/values.yaml --kube-context kube2 --namespace cert-manager --create-namespace cert-manager-kube2 cert-manager/

# Cloudflare API token secret needed for cert-manager to auto complete the domain verification
kubectl create secret generic cloudflare-api-token --namespace cert-manager --from-literal=api_token=$(op item get "Cloudflare API Token" --vault Homelab --fields credential) --context kube
kubectl create secret generic cloudflare-api-token --namespace cert-manager --from-literal=api_token=$(op item get "Cloudflare API Token" --vault Homelab --fields credential) --context kube2


kubectl apply -f cert-manager/le-prod-clusterissuer.yaml --context kube
kubectl apply -f cert-manager/le-prod-clusterissuer.yaml --context kube2

kubectl apply -f cert-manager/le-staging-clusterissuer.yaml --context kube
kubectl apply -f cert-manager/le-staging-clusterissuer.yaml --context kube2

helm install --kube-context kube --namespace nginx-gateway --create-namespace nginx-gateway-fabric-kube1 nginx-gateway-fabric/
helm install --kube-context kube2 --namespace nginx-gateway --create-namespace nginx-gateway-fabric-kube2 nginx-gateway-fabric/
kubectl apply -f nginx-gateway-fabric/gateway.yaml --context kube
kubectl apply -f nginx-gateway-fabric/gateway.yaml --context kube2

kubectl --namespace nginx-gateway rollout restart deployment nginx-gateway-fabric-kube1 --context kube
kubectl --namespace nginx-gateway rollout restart deployment nginx-gateway-fabric-kube2 --context kube2

helm install -f argocd/values.yaml --namespace argocd --create-namespace argocd-kube1 argocd/
kubectl apply -f argocd/http-route.yaml --namespace argocd

