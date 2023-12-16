# Quick Start Local Development

## Prerequisites

1. [Docker](https://docs.docker.com/get-docker/)
2. [Minikube](https://minikube.sigs.k8s.io/docs/start/)
3. [Tilt](https://docs.tilt.dev/install.html)*
4. [Pack](https://buildpacks.io/docs/tools/pack/)
5. [Kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
6. [Kustomize](https://kubectl.docs.kubernetes.io/installation/kustomize/)
7. [Helm](https://helm.sh/docs/intro/install/)
8. [Git](https://git-scm.com/downloads) (make sure to install Git Bash if you're on Windows)
9. [mkcert]()**
10. Repositories (should be installed in the same directory as this repository):
    - [Group Service](https://github.com/GroupHQ/group-service)
    - [Group Sync](https://github.com/GroupHQ/group-sync)
    - [Edge Service](https://github.com/GroupHQ/edge-service)
    - [GroupHQ UI](https://github.com/GroupHQ/groupHQ-ui)
11. Setup GitHub Container Registry token in the `secrets` folder (only if you want to run the `quick-start-test.sh` script, see README.md in the `secrets` folder for instructions)

*After installing Tilt, rename the executable to `tlt`. If you use something like `scoop` which has a 'shim' file of tilt, rename that to `tlt` as well. [See here for why](https://docs.tilt.dev/faq.html#q-when-i-run-tilt-version-i-see-template-engine-not-found-for-version-what-do-i-do).
**After installing mkcert, see the README.md file in the `kubernetes/platform/development/certificates` folder for instructions on how to use it.
You need to follow these instructions before running the quick-start scripts.

## Configuring Docker With Minikube
In the Docker Desktop app, go to Settings (or Preferences) and select the Kubernetes tab.
Click on "Enable Kubernetes". You may have to select the "Apply & Restart" option after it finishes loading the changes.

This results in the Docker Desktop app creating a Kubernetes server. To have Minikube create clusters on this server,
run the following commands:

Set the Docker context:
```bash
docker context use default
```

Configure Minikube to use that context:
```bash
minikube config set driver docker
```

Now Minikube is configured to deploy clusters to the Kubernetes server that's running locally within the Docker instance.

## Scripts
There are several scripts scattered throughout the repositories that are used to start a variety of services:
1. The `create-cluster.sh` script in the `kubernetes/platform/development` starts the grouphq minikube cluster
   with essential services (e.g. NGINX, PostgreSQL, Redis, RabbitMQ)
2. The `destroy-cluster.sh` script in the `kubernetes/platform/development` destroys the grouphq minikube cluster
3. The `deploy.sh` script in the `kubernetes/applications/development/observability` folder deploys the Grafana
   Observability Stack to the grouphq minikube cluster
4. The `create-tls-secret-localhost.sh` script in the `kubernetes/platform/development/certificates` folder creates a TLS secret
   to be used by NGINX to serve HTTPS requests to localhost
5. The `Tiltfile` in the `kubernetes/applications/development` folder can be run using `tilt up`
   (performs different actions depending on environment variables set)

To simplify the process of starting up the environment, I've created a few scripts that call these scripts in the correct order.

### `./quick-destory-dev.sh`
Cleans up resources created by the quick-start scripts.
This script is run first in the quick-start scripts to ensure that the environment is clean before starting.
You'll only be calling it directly when you want to clean up the environment without starting a new one.

The script does the following:
1. Kills any background processes recorded in the processes folder 
(background processes started by the quick-start scripts have their process id saved in the 'processes' folder)
2. Shuts down repository services using tilt
3. Destroys the grouphq minikube cluster using the `destroy-cluster.sh` script

### `./quick-start-dev.sh`
Starts up the grouphq minikube cluster and deploys the observability stack to it.
For developing, this is the script you want to run to start up your cluster.
It takes a while to start, but once started, you'll have:
1. Access to the Tilt UI at http://localhost:10350
2. Access to the Grafana UI at http://localhost:3000 (default username is `user` and password is printed by the script)
3. Access to the GroupHQ application at https://localhost (you'll need to follow the instructions in the `kubernetes/platform/development/certificates` folder to set up your browser to trust the certificate)

The script does the following:
1. Calls `quick-destory-dev.sh` to clean up the environment
2. Starts the grouphq minikube cluster using the `create-cluster.sh` script
3. Deploys the observability stack to the grouphq minikube cluster using the `deploy.sh` script
4. Creates a TLS secret for localhost using the `create-tls-secret-localhost.sh` script
5. Starts the repository services using tilt
6. Runs `minikube tunnel --profile grouphq` in the background to allow access to the application at https://localhost
7. Waits for the services to be ready before exiting

On my machine, the script takes about 15 minutes to run. The startup is heavily CPU-bound, my CPU is an 8-year-old  4-core i7-6700. So, if you have a more modern CPU, it should (hopefully) be faster.
### `./quick-start-test.sh`
Similar to `quick-start-dev.sh`, but:
1. Does not deploy the observability stack
2. Accepts any of the following arguments:
   - `build_edge-service_locally`
   - `build_grouphq-ui_locally`
   - `build_group-sync_locally`
   - `build_group-service_locally`
3. Applies a `ghcr-container-registry-read.yml` secret in the `secrets/kubernetes/development` folder to the grouphq minikube cluster
(this secret allows the cluster to pull images from the GitHub container registry, see the README.md in the `secrets` folder for instructions on how to set it up)

Depending on the arguments passed, the script will build the corresponding service locally before starting it with tilt.
This means that it will build the service based on _the currently checked-out code_.
Additionally, it will apply the _observability overlay Kustomization_ to the services, which removes observability environment variables (to prevent the service logs from being cluttered with observability-related failures)
Otherwise, it will use the latest image from the GitHub container registry.

This script is useful for testing changes to the services locally before pushing them to GitHub,
but its real purpose is to allow for the testing of changes as part of our continuous testing strategy.

That is, when a pull request is created, GitHub will send a notification to our Continuous Testing Proxy server.
This server will then run the `quick-start-test.sh` script with the appropriate arguments to set up the testing environment.
Once setup, the service will run BuildWise to run our user-acceptance tests against the service.
The results of the tests will be sent back to GitHub, which will then update the pull request with the results.

With that said, there is still a benefit to running the script locally. It's much faster. 
Without passing any arguments (and thus by default pulling all images from the GHCR), it takes about 5 minutes to run on my machine--66% faster.
Just note that you won't have the Grafana observability stack available, and any changes you make to services that had their image pulled from the GHCR won't be reflected in the running service.