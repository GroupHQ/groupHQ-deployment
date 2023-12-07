echo "🔐 Creating TLS secret for localhost..."
kubectl create secret tls edge-service-cert --key="localhost-key.pem" --cert="localhost.pem"
echo "🔐 TLS Secret Created!"