# Flatcar Linux Update Operator

Local installation fork of the [Flatcar Linux Update Operator](https://github.com/flatcar-linux/flatcar-linux-update-operator)

The K8s nodes that power the cluster all run on Flatcar Linux Update Operator to keep the OS components minimal and simplified for their sole purpose of running Kubelet. This operator allows the Kubernetes cluster to properly coordinate with each other to schedule reboots for Node updates while being more aware of the state of the Kubernetes cluster. See FLUO's documentation for more info.