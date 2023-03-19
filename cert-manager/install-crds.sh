#!/usr/bin/env bash

CRDVERSION="v1.11.0"

kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/${CRDVERSION}/cert-manager.crds.yaml