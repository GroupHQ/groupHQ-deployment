#!/bin/sh

echo "📦 Initializing Kubernetes cluster..."

minikube start --cpus 6 --memory 4g --driver docker --profile grouphq

echo "🔌 Enabling NGINX Ingress Controller..."

minikube addons enable ingress --profile grouphq

sleep 1

echo "📦 Deploying PostgreSQL..."

kubectl apply -f services/postgresql.yml

sleep 1

echo "📦 Deploying Redis..."

kubectl apply -f services/redis.yml

sleep 1

echo "📦 Deploying RabbitMQ..."

kubectl apply -f services/rabbitmq.yml

sleep 1

echo "⌛ Waiting for PostgreSQL to be deployed..."

while [ $(kubectl get pod -l db=grouphq-postgres | wc -l) -eq 0 ] ; do
  sleep 5
done

echo "⌛ Waiting for PostgreSQL to be ready..."

kubectl wait \
  --for=condition=ready pod \
  --selector=db=grouphq-postgres \
  --timeout=180s

echo "⌛ Waiting for Redis to be deployed..."

while [ $(kubectl get pod -l db=grouphq-redis | wc -l) -eq 0 ] ; do
  sleep 5
done

echo "⌛ Waiting for Redis to be ready..."

kubectl wait \
  --for=condition=ready pod \
  --selector=db=grouphq-redis \
  --timeout=180s


echo "⌛ Waiting for RabbitMQ to be deployed..."

while [ $(kubectl get pod -l db=grouphq-rabbitmq | wc -l) -eq 0 ] ; do
  sleep 5
done

echo "⌛ Waiting for RabbitMQ to be ready..."

kubectl wait \
  --for=condition=ready pod \
  --selector=db=grouphq-rabbitmq \
  --timeout=180s

echo "📦 Deploying RabbitMQ..."


echo "⛵ Happy Sailing!"
