# The terrible, horrible, no good, very bad, terrible Homelab Kubernetes Cluster

This repository contains the configuration of my personal Kubernetes lab Cluster. Manifests are generally deployed using [ArgoCD](https://argo-cd.readthedocs.io/en/stable/) to ensure all changes are properly historied. Also, Argo's UI is nice and has a lot of pretty colors to tell me that my configuration is wrong and has broken something as a consequence.

As with most Homelab code, the code quality can range from "nowhere near real-world production" ready to "a bit more polish and it could be used in a production environment" levels. Rather, this codebase is better served as a reference or guide to read on when building a cluster. After all, what fun is taking someone's code, not understanding it and then straight up applying all the manifests blindly?


### License

The repo is available under the MIT License.


See [LICENSE.md](LICENSE.md) for the full information