#!/bin/bash
start=$(date +%s)

# Function to wait for a pod to exist
wait_for_pod_existence() {
    local service_name=$1
    local pod_label=$2
    local timeout=600 # 10 minutes in seconds
    local end_time=$(( $(date +%s) + timeout ))

    echo "Waiting for pod with label $pod_label to exist..."
    while [[ $(date +%s) -lt $end_time ]]; do
        # Get the output of kubectl get pods
        local output=$(kubectl get pods -l "$pod_label" --no-headers 2>/dev/null)

        # Check if the output does not contain "No resources found"
        if [[ $output != "" && ! $output =~ "No resources found" ]]; then
            echo "Pod for $service_name exists."
            return 0
        fi
        sleep 10
    done

    echo "Timeout reached. Pod for $service_name does not exist."
    return 1
}

# Function to wait for pod readiness
wait_for_pod_readiness() {
    local service_name=$1
    local pod_label=$2
    local timeout="5m"

    if kubectl wait --for=condition=ready pod --selector="$pod_label" --timeout=$timeout; then
        echo "Pod for $service_name is ready."
        return 0
    else
        echo "Pod for $service_name did not become ready in time."
        return 2
    fi
}

# Function to handle each service
handle_service() {
    local service_name=$1
    local pod_label=$2

    if wait_for_pod_existence "$service_name" "$pod_label"; then
        wait_for_pod_readiness "$service_name" "$pod_label"
    else
        return 1
    fi
}

# Save current directory
original_dir=$(pwd)

# Ensure a clean start
./quick-destroy-dev.sh

# Create cluster
cd ../../platform/development || exit
./create-cluster.sh

# Create TLS certificate secret
cd ./certificates || exit
./create-tls-secret-localhost.sh

# Switch to Kubernetes Secrets Development Directory
cd ../../../../secrets/kubernetes/development || exit

echo "🔑Creating GitHub Container Registry Secret..."
kubectl apply -f ghcr-container-registry-read.yml

# Run tlt up
cd ../../../kubernetes/applications/development || exit

# Initialize variables to false
TILT_BUILD_EDGE_SERVICE_LOCALLY=false
TILT_BUILD_GROUPHQ_UI_LOCALLY=false
TILT_BUILD_GROUP_SYNC_LOCALLY=false
TILT_BUILD_GROUP_SERVICE_LOCALLY=false

# Iterate over each argument
for arg in "$@"
do
    case $arg in
        build_edge-service_locally)
            TILT_BUILD_EDGE_SERVICE_LOCALLY=true
            ;;
        build_grouphq-ui_locally)
            TILT_BUILD_GROUPHQ_UI_LOCALLY=true
            ;;
        build_group-sync_locally)
            TILT_BUILD_GROUP_SYNC_LOCALLY=true
            ;;
        build_group-service_locally)
            TILT_BUILD_GROUP_SERVICE_LOCALLY=true
            ;;
        *)
            # Ignore any unknown arguments
            ;;
    esac
done

# Export the variables
export TILT_BUILD_EDGE_SERVICE_LOCALLY
export TILT_BUILD_GROUPHQ_UI_LOCALLY
export TILT_BUILD_GROUP_SYNC_LOCALLY
export TILT_BUILD_GROUP_SERVICE_LOCALLY

nohup tlt up &
echo $! > "$original_dir/processes/tilt.pid"

# Run minikube tunnel
nohup minikube tunnel --profile grouphq &
echo $! > "$original_dir/processes/minikube-tunnel.pid"

# Define services and their labels
declare -A services=(
    ["edge-service"]="app=edge-service"
    ["grouphq-ui"]="app=grouphq-ui"
    ["group-sync"]="app=group-sync"
    ["group-service"]="app=group-service"
)

# Initialize PID array
declare -A pids

# Start and track each service
for svc in "${!services[@]}"; do
    handle_service "$svc" "${services[$svc]}" &
    pids["$svc"]=$!
done

# Wait for all services and report status
for svc in "${!pids[@]}"; do
    if wait "${pids[$svc]}"; then
        echo "Success: $svc"
    else
        echo "Failure: $svc"
    fi
done


# Change back to the original directory
cd "$original_dir" || exit
end=$(date +%s)
duration=$((end - start))
printf "Total Duration: %d minutes and %d seconds\n" $(($duration / 60)) $(($duration % 60))