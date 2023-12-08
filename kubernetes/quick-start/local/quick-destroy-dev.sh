#!/bin/bash

# Function to safely kill a process with a given PID file
kill_process() {
    local pidfile=$1

    # Check if the PID file exists
    if [[ -f "$pidfile" ]]; then
        # Read the PID from the file and kill the process
        local pid=$(cat "$pidfile")
        echo "Stopping process $pid from $pidfile"
        kill $pid

        # Optionally, remove the PID file after killing the process
        rm -f "$pidfile"
    else
        echo "PID file $pidfile not found, continuing..."
    fi
}

echo "Unsetting context..."
kubectl config unset current-context
sleep 1

echo "Switching to local GroupHQ context..."
kubectl config use-context grouphq

echo "Ensuring minikube tunnel and tilt processes are stopped..."

# Step 1: Kill the minikube tunnel process
kill_process "./processes/minikube-tunnel.pid"

# Step 2: Kill the tilt process
kill_process "./processes/tilt.pid"

# Step 3: Kill the Grafana Console port-forwarding process
kill_process "./processes/grafana-console-port-forward.pid"

# Step 4: Run `tilt down`
echo "Running 'tilt down'..."
cd "../../applications/development" || exit
tilt down

# Step 5: Run the destroy cluster script
echo "Running destroy cluster script..."
cd "../../platform/development" || exit
./destroy-cluster.sh

# Step 6: Done
echo "Cluster destruction process complete."
echo "You may have to set your kubectl context again. Run kubectl config get-contexts to see what contexts are available."
echo "Run kubectl config use-context <context-name> to set the context to the desired context."
