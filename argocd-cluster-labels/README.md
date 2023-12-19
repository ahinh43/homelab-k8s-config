# ArgoCD Cluster labeler

This is an ArgoCD application that manages the labels patched on to the cluster secrets that ArgoCD uses to target clusters for deployments. Labels are managed here and deployed via ArgoCD which are then used by ApplicationSets' cluster generators to figure out what clusters to target when creating applications from its templates.

### Getting Started

If you want to target the same cluster ArgoCD is on with this label generator, follow these steps from [ArgoCD's documentation](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/Generators-Cluster/#deploying-to-the-local-cluster) to create the local cluster secret.

1. Ensure all of your clusters are added and the secrets are present in the `argocd` namespace. Ensure your context is the same context ArgoCD is deployed to.
2. Run `generate-cluster-manifests.sh`. The script will build out the entire directory and files that are needed to work.
3. Edit the overlays/`cluster-*` files and add in any custom labels per cluster
4. Edit the `components/kustomization.yaml` `commonLabels` section to apply labels to all clusters
5. Commit your changes to git
6. Apply `argo.yaml` to deploy these changes out via ArgoCD