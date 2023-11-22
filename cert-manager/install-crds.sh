#!/usr/bin/env bash

CRDVERSION="v1.13.2"

kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/${CRDVERSION}/cert-manager.crds.yaml