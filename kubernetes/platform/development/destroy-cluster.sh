#!/bin/sh

echo "🏴️ Destroying Kubernetes cluster..."

minikube stop --profile grouphq

minikube delete --profile grouphq

echo "🏴️ Cluster destroyed"
