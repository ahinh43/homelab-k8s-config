# Unifi

Kubernetes deployment configuration for the Ubiquiti Unifi Controller. While most desired ports are open for the controller to fully function within the network, the controller is still unable to perform certain actions like discovering new access points to adopt by itself, and would need its configuration transferred in from another controller that lives outside of the cluster.
