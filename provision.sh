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

kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.0.0/standard-install.yaml --context kube
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.0.0/standard-install.yaml --context kube2

kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/${CERTMANAGERCRDVERSION}/cert-manager.crds.yaml --context kube
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/${CERTMANAGERCRDVERSION}/cert-manager.crds.yaml --context kube2

helm install --kube-context kube --namespace metallb-system --create-namespace metallb metalLB/
helm install --kube-context kube2 --namespace metallb-system --create-namespace metallb metalLB/

sleep 240

kubectl apply -f metalLB/kube1 --context kube
kubectl apply -f metalLB/kube2 --context kube2

kubectl delete secret cilium-ca --namespace kube-system --context kube2
kubectl --context=kube get secret -n kube-system cilium-ca -o yaml | kubectl --context kube2 create -f -

cilium clustermesh enable --context kube --service-type LoadBalancer
cilium clustermesh enable --context kube2 --service-type LoadBalancer

cilium clustermesh status --wait --context kube
cilium clustermesh status --wait --context kube2

cilium clustermesh connect --context kube --destination-context kube2

cilium clustermesh status --wait --context kube
cilium clustermesh status --wait --context kube2

cilium connectivity test --context kube --multi-cluster kube2

echo "Deploying the necessary services to get the cluster rolling..."

helm install -f cert-manager/values.yaml --kube-context kube --namespace cert-manager --create-namespace cert-manager-kube1 cert-manager/
helm install -f cert-manager/values.yaml --kube-context kube2 --namespace cert-manager --create-namespace cert-manager-kube2 cert-manager/

helm install -f external-dns/values.yaml --kube-context kube --namespace external-dns --create-namespace external-dns external-dns/
helm install -f external-dns/values.yaml --kube-context kube2 --namespace external-dns --create-namespace external-dns external-dns/

# Cloudflare API token secret needed for cert-manager to auto complete the domain verification
kubectl create secret generic cloudflare-api-token --namespace cert-manager --from-literal=cloudflare_api_token=$(op item get "Cloudflare API Token" --vault Homelab --fields credential) --context kube
kubectl create secret generic cloudflare-api-token --namespace cert-manager --from-literal=cloudflare_api_token=$(op item get "Cloudflare API Token" --vault Homelab --fields credential) --context kube2
kubectl create secret generic cloudflare-api-token --namespace external-dns --from-literal=cloudflare_api_token=$(op item get "Cloudflare API Token" --vault Homelab --fields credential) --context kube
kubectl create secret generic cloudflare-api-token --namespace external-dns --from-literal=cloudflare_api_token=$(op item get "Cloudflare API Token" --vault Homelab --fields credential) --context kube2


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


kubectl create namespace ceph-csi-rbd --context kube
kubectl create namespace ceph-csi-rbd --context kube2