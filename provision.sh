#!/usr/bin/env bash

# Hacky script that provisions the cluster with the basics, before letting argoCD take the rest of the job
# TODO: Turn into ansible playbook

set -exo pipefail

CERTMANAGERCRDVERSION="v1.13.2"

echo "installing CRDs"

if op whoami; then
  echo "Signed into 1password"
else
  echo "Not signed into 1password or an error happened. Check the logs for more details"
  exit $?
fi

installedChartsKube1=$(helm list --kube-context kube --all-namespaces)
installedChartsKube2=$(helm list --kube-context kube2 --all-namespaces)

# kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.0.0/standard-install.yaml --context kube
# kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.0.0/standard-install.yaml --context kube2

kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/${CERTMANAGERCRDVERSION}/cert-manager.crds.yaml --context kube
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/${CERTMANAGERCRDVERSION}/cert-manager.crds.yaml --context kube2

# Set up BGP peering w/ Cilium
kubectl apply -f cilium/bgp-peering.yaml --context kube
kubectl apply -f cilium/bgp-peering-kube2.yaml --context kube2
kubectl apply -f cilium/ip-pool-kube1.yaml --context kube
kubectl apply -f cilium/ip-pool-kube2.yaml --context kube2

# Label every node with their respective bgp policy

for node in `kubectl get nodes -o json | jq -r '.items[].metadata.name'`; do
  kubectl label node $node bgp-policy=kube
done

for node in `kubectl get nodes --context kube2 -o json | jq -r '.items[].metadata.name'`; do
  kubectl label node $node bgp-policy=kube2 --context kube2
done

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


if grep -q "cert-manager" <<< "$installedChartsKube1"; then
  echo "cert-manager chart already installed. Moving on.."
else
  helm install -f cert-manager/values.yaml --kube-context kube --namespace cert-manager --create-namespace cert-manager cert-manager/
fi

if grep -q "cert-manager" <<< "$installedChartsKube2"; then
  echo "cert-manager chart already installed. Moving on.."
else
  helm install -f cert-manager/values.yaml --kube-context kube2 --namespace cert-manager --create-namespace cert-manager cert-manager/
fi



if grep -q "external-dns" <<< "$installedChartsKube1"; then
  echo "external-dns chart already installed. Moving on.."
else
  helm install -f external-dns/values.yaml --kube-context kube --namespace external-dns --create-namespace external-dns external-dns/
fi

if grep -q "external-dns" <<< "$installedChartsKube2"; then
  echo "cert-manager chart already installed. Moving on.."
else
  helm install -f external-dns/values.yaml --kube-context kube2 --namespace external-dns --create-namespace external-dns external-dns/
fi


# Cloudflare API token secret needed for cert-manager to auto complete the domain verification

if ! kubectl get secret --context kube --namespace cert-manager | grep -q "cloudflare-api-token"; then
  kubectl create secret generic cloudflare-api-token --namespace cert-manager --from-literal=cloudflare_api_token=$(op item get "Cloudflare API Token" --vault Homelab --fields credential) --context kube
fi

if ! kubectl get secret --context kube2 --namespace cert-manager | grep -q "cloudflare-api-token"; then
  kubectl create secret generic cloudflare-api-token --namespace cert-manager --from-literal=cloudflare_api_token=$(op item get "Cloudflare API Token" --vault Homelab --fields credential) --context kube2
fi

if ! kubectl get secret --context kube --namespace external-dns | grep -q "cloudflare-api-token"; then
  kubectl create secret generic cloudflare-api-token --namespace external-dns --from-literal=cloudflare_api_token=$(op item get "Cloudflare API Token" --vault Homelab --fields credential) --context kube
fi

if ! kubectl get secret --context kube2 --namespace external-dns | grep -q "cloudflare-api-token"; then
  kubectl create secret generic cloudflare-api-token --namespace external-dns --from-literal=cloudflare_api_token=$(op item get "Cloudflare API Token" --vault Homelab --fields credential) --context kube2
fi

kubectl apply -f cert-manager/le-prod-clusterissuer.yaml --context kube
kubectl apply -f cert-manager/le-prod-clusterissuer.yaml --context kube2

kubectl apply -f cert-manager/le-staging-clusterissuer.yaml --context kube
kubectl apply -f cert-manager/le-staging-clusterissuer.yaml --context kube2

if grep -q "ingress-nginx" <<< "$installedChartsKube1"; then
  echo "ingress-nginx chart already installed. Moving on.."
else
  helm install --kube-context kube --namespace ingress-nginx --create-namespace ingress-nginx nginx-ingress/
  ingressnginxinstalled="yes"
fi

if grep -q "ingress-nginx" <<< "$installedChartsKube2"; then
  echo "cert-manager chart already installed. Moving on.."
else
  helm install --kube-context kube2 --namespace ingress-nginx --create-namespace ingress-nginx nginx-ingress/
  ingressnginxinstalled="yes"
fi

# Need to sleep 30 seconds to let the ingress controllers start up
if [[ $ingressnginxinstalled = "yes" ]]; then
  sleep 30
fi

if grep -q "argocd" <<< "$installedChartsKube1"; then
  echo "argocd chart already installed. Moving on.."
else
  helm install --kube-context kube -f argocd/values.yaml --namespace argocd --create-namespace argocd argocd/
fi

if ! kubectl get namespace --context kube | grep -q "ceph-csi-rbd"; then
  kubectl create namespace ceph-csi-rbd --context kube
fi

if ! kubectl get namespace --context kube2 | grep -q "ceph-csi-rbd"; then
  kubectl create namespace ceph-csi-rbd --context kube2
fi

# Sets up ArgoCD

argocd login argo.k8s.labs.ahinh.me --insecure --username admin --password $(kubectl get secret -n argocd argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 --decode)
argocd account update-password --current-password $(kubectl get secret -n argocd argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 --decode) --new-password $(op item get "argocd" --vault Homelab --fields password)
argocd cluster add kube2 --yes
argocd repo add git@github.com:ahinh43/homelab-k8s-config.git --ssh-private-key-path ~/.ssh/id_rsa

# Imports the existing services we have into Argo

kubectl apply -f cert-manager/argo.yaml
kubectl apply -f metalLB/argo.yaml
kubectl apply -f external-dns/argo.yaml
kubectl apply -f nginx-ingress/argo.yaml