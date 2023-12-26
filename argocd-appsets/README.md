# ArgoCD applicationsets (appsets for short)

The subdirectory contains all of the applicationsets deployed onto the cluster. Applicationsets that are pushed from this directory are then automatically applied in ArgoCD and the project is then created via GitOps. Similarly, to remove an applicationset simply comment or delete the file that contains the appset configuration desired.

Currently appsets are just copied and pasted files with the minimal modifications done onto it. Maybe one day I'll get a helm or kustomize template going for it.

The appset application is split out in 2 categories, Kubevirt VMs and regular microservices.