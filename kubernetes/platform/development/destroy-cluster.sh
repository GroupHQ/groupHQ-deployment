#!/bin/sh

echo "\n🏴️ Destroying Kubernetes cluster...\n"

minikube stop --profile grouphq

minikube delete --profile grouphq

echo "\n🏴️ Cluster destroyed\n"
