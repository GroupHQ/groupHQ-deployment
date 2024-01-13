_This README is a work in progress. Some steps may be incomplete or missing_

# GroupHQ
_[GroupHQ](https://grouphq.org/) is a demo application created as a training exercise for building and deploying
[reactive](https://en.wikipedia.org/wiki/Reactive_Streams) [cloud-native applications](https://aws.amazon.com/what-is/cloud-native/)
through the use of [Spring Boot](https://www.ibm.com/topics/java-spring-boot), [Project Reactor](https://projectreactor.io/),
[Docker](https://www.docker.com/), and [Kubernetes](https://kubernetes.io/), with an
emphasis on cloud-native principles, particularly based on the [15-factor app methodology](https://developer.ibm.com/articles/15-factor-applications/)_

## Contents
- [Introduction](#introduction)
- [Key Services](#key-services)
- [Observability Stack](#observability-stack)
- [Docker](#docker)
- [Kubernetes](#kubernetes)
  - [Overlays (i.e. configuration patches)](#overlays-ie-configuration-patches)
- [Development Environment Setup](#development-environment-setup)
  - [Local Environment Using Docker](#local-environment-using-docker)
  - [Local Environment Using Kubernetes](#local-environment-using-kubernetes)
- [Production Environment Setup](#production-environment-setup)
  - [Creating the Cluster](#creating-the-cluster)
  - [Creating the Backing Services](#creating-the-backing-services)
    - [PostgreSQL](#postgresql)
    - [Redis](#redis)
    - [RabbitMQ](#rabbitmq)
  - [Deploying the Grafana Observability Stack](#deploying-the-grafana-observability-stack)
  - [Deploying and Syncing the Applications Using Argo CD](#deploying-and-syncing-the-applications-using-argo-cd)
  - [Setting Up TLS/SSL Certificate for HTTPS/WSS Connections](#setting-up-tlsssl-certificate-for-httpswss-connections)
  - [Deleting the Cluster and Backing Services](#deleting-the-cluster-and-backing-services)
    - [Deleting the Cluster](#deleting-the-cluster)
    - [Deleting the Backing Services](#deleting-the-backing-services)

## Introduction

Version: DEMO

The GroupHQ Demo allows users to view, sync, join and leave auto-generated groups. While seemingly simple in nature,
the demo is backed by robust and extensible services for improving and adding onto the feature set. The system is
designed as a set of microservices to enable decoupling of services, independent development and deployment, and
improved scalability compared to traditional monolithic applications.

The following services are currently available:
- Edge Service
- Group Sync
- Group Service
- GroupHQ UI (frontend application)

Each service has been created with [cloud-native](https://developer.ibm.com/articles/15-factor-applications/) principles 
in mind. They are independently deployable, scalable, and resilient in case of downstream errors.

## Architecture Diagrams
You can find the architecture diagrams for the GroupHQ Demo in the `architecture/demo` folder in this repository.
The following diagrams are available:
- GroupHQ Demo Containers (with Observability Stack)
- GroupHQ Demo Containers (without Observability Stack)
- GroupHQ Demo Gateway-Related Containers
- GroupHQ Demo Group-Service-Related Containers
- GroupHQ Demo Observability Related Containers

## Key Services
To view information on key services, see the README.md files in their repositories:
- [Edge Service](https://github.com/GroupHQ/edge-service)
- [Group Sync](https://github.com/GroupHQ/group-sync)
- [Group Service](https://github.com/GroupHQ/group-service)
- [GroupHQ UI](https://github.com/GroupHQ/groupHQ-ui)

The rest of this guide will go into detail about deployment-related topics.

## Observability Stack
The GroupHQ Demo uses a variety of tools to provide observability into the system, all of which are integrated with
Grafana using the Grafana Observability Stack:
- Loki: Aggregates logs from services
- Prometheus: Collects metrics from services
- Tempo: Aggregates traces from services

Tools such as these are essential for monitoring and debugging applications. Without them, developers would have to 
resort to querying information on applications from the console, which is not practical, especially in a distributed 
environment. Tracing is a boon to developers in these environments, as it allows them to see the flow of requests 
through the system. With the Grafana Observability Stack, developers can view traces from logs and critical 
application info at a glance through custom dashboards.

Currently, Edge Service, Group Sync, and Group Service are all observable through the Grafana Observability Stack.
Check out the [Development Environment Setup](#development-environment-setup) section for instructions
on how to access the Grafana dashboard locally.

## Docker
In this repository a `docker` folder is included for local development without using Kubernetes. The most common use 
case here is to run backing services, such as databases, for your applications running on your local machine.
Using containerized backing services provides a more consistent, portable, and production-like environment for 
developing.

## Kubernetes
When an application is ready to be deployed, the `kubernetes` folder is used. 

Notice the `applications/development` folder. It contains a `Tiltfile` to run the `Tiltfile`s in Edge Service, 
Group Sync, and Group Service. Each service's `Tiltfile` has instructions on deploying the application to your current 
Kubernetes context based on the base manifest files located in the repository's `k8s` folder.

The rest of the `applications` folder contains overlays to customize each repositories base manifest files for different
environments. For example, the `applications/*/production` folders contains production overlays for a given service.

The `platform` folder contains all the backing services for the GroupHQ Demo in either development or production
environments. 

In the `development` folder, these include:
- PostgreSQL: A relational database for storing application data
- RabbitMQ: A message broker for sending events between services
- Redis: A key-value store for caching application data

In the `production` folder, these include:
- ArgoCD: A GitOps tool for continuous deployment of applications to Kubernetes
- ingress-nginx: A Kubernetes Ingress Controller for routing requests to services
- RabbitMQ: A message broker for sending events between services using the AMQP protocol
- Grafana: A tool for visualizing metrics and logs
- Loki: A tool for aggregating logs
- Prometheus: A tool for collecting metrics
- Tempo: A tool for aggregating traces

The following is created through a Cloud Provider's managed services. These are services that are managed by the 
Cloud Provider--they are not deployed to the Kubernetes cluster:
- PostgreSQL: A relational database for storing application data
- Redis: A key-value store for caching application data

### Overlays (i.e. configuration patches)
Patches in Kubernetes are created through Kustomize, and are used to apply and/or override configuration for a service. 
The type of patches can vary depending on the environment.

To elaborate, each service repository has a `k8s` (short for Kubernetes) directory that contains the base configuration 
for the service in a local Kubernetes development environment. In the `groupHQ-deployment` repository, there is a 
directory for each service, and for each service, a different environment to run on. 
While there are staging and production overlays defined, there are no staging environments as of now. 
Nevertheless, this strategy allows environment-specific configuration to be injected into the base configuration
with the help of Kustomize.

## Development Environment Setup
There are two ways to set up the GroupHQ development environment: using Docker or using Kubernetes. The Docker setup is
the easiest to get started with, but the Kubernetes setup provides the most production-like environment with TLS 
enabled, and allows for testing of Kubernetes manifests and secure connections.

### Local Environment Using Docker
You can find all Docker related files under the `docker` directory of this project. Container definitions 
are specified in the `docker-compose.yml`, and they include the containers necessary to build the Grafana Observability
Stack. Building any of the following containers: `group-service`, `group-sync`, `edge-service`, will trigger the
Grafana Observability Stack containers to be built as well. Note that the `grouphq-ui` container is not integrated
into the Grafana Observability Stack.

You can run the entire development stack by running: `docker-compose up -d grouphq-ui`. This will transitively build
the backend services and their backing services, as well as the Grafana Observability Stack. The `-d` flag runs the
containers in detached mode, meaning that the containers will run in the background. Make sure to run this command
in the `docker` directory.

If you're interested in running only one service with its dependencies, you can run the following command:
`docker-compose up -d <service-name>`. For example, to run Group Service, you would use the following command:
`docker-compose up -d group-service`. This will build the Group Service container and its backing services, along
with the Grafana Observability Stack.

You can access the Grafana dashboard at http://localhost:3000. The default username is `user` and the default password 
is `password`.

### Local Environment Using Kubernetes
This is the recommended environment for development. It is the most production-like environment and allows for
testing of TLS connections and Kubernetes manifests. Due to the complexity of setting up the environment, it is 
recommended to use the quick-start scripts. See the README.md file in the `kubernetes/quick-start/local` folder
for more details on:
- Programs to have installed on your system before running the scripts
- Details on what the scripts do
- Which scripts to run
- How to access the Grafana dashboard in a Kubernetes environment

## Production Environment Setup
There is no script to perform all the following steps, but one may be created in the future.
The main reason being is that some of these commands are vendor-specific (to Digital Ocean via the `doctl` command), and
a script based on these steps would be limited to Digital Ocean.
Ideally, something like Terraform would be used to create the cluster and backing services to avoid vendor lock-in.

### Creating the Cluster
Create a Digital Ocean Kubernetes cluster in the New York City area with the following command:
```shell
doctl k8s cluster create grouphq-cluster \
--node-pool "name=basicnp;size=s-2vcpu-4gb;count=3;label=type=basic;" \
--region nyc1
```

In the `kubernets/platform/production/ingress-nginx` folder, run the following command to deploy the Digital Ocean 
NGINX controller:
```shell
./deploy.sh
```

### Creating the Backing Services

#### PostgreSQL
Create the PostgreSQL database server with the following command:
```shell
doctl databases create grouphq-db \
--engine pg \
--region nyc1 \
--version 14
```

Wait until the database server is ready. You can view its status by running the following command:
```shell
doctl databases list
```

Then configure a firewall to only allow traffic from the cluster:
```shell
doctl databases firewalls append <postgres_id> --rule k8s:<cluster_id>
```
You can get the `postgres_id` and `cluster_id` by running the following command:
```shell
doctl databases list
```

Create the `grouphq_group` database:
```shell
doctl databases db create <postgres_id> grouphq_group
```

You can then retrieve the connection details by running the following command:
```shell
doctl databases connection <postgres_id> --format Host,Port,User,Password
```

Then create a secret for the database credentials (used by the group-service manifests):
```shell
kubectl create secret generic polar-postgres-catalog-credentials \
--from-literal=spring.datasource.url="spring.flyway.url=jdbc:postgresql://<postgres_host>:<postgres_port>/polardb_order" \
--from-literal="spring.r2dbc.url=r2dbc:postgresql://<postgres_host>:<postgres_port>/polardb_order?ssl=true&sslMode=require" 
--from-literal=spring.r2dbc.username=<postgres_username> \
--from-literal=spring.r2dbc.password=<postgres_password>
```

#### Redis
Create the Redis database server with the following command:
```shell
 doctl databases create grouphq-redis \
 --engine redis \
 --region nyc1 \
 --version 7
```

Wait until the database server is ready. You can view its status by running the following command:
```shell
doctl databases list
```

Then configure a firewall to only allow traffic from the cluster:
```shell
doctl databases firewalls append <redis_id> --rule k8s:<cluster_id>
```

You can then retrieve the connection details by running the following command:
```shell
doctl databases connection <redis_id> --format Host,Port,User,Password
```

Then create a secret for the database credentials (used by the edge-service manifests):
```shell
kubectl create secret generic grouphq-redis-credentials \
 --from-literal=spring.redis.host=<redis_host> \
 --from-literal=spring.redis.port=<redis_port> \
 --from-literal=spring.redis.username=<redis_username> \
 --from-literal=spring.redis.password=<redis_password> \
 --from-literal=spring.redis.ssl=true
```

#### RabbitMQ
Unlike the other backing services which use servers managed by Digital Ocean, RabbitMQ is not offered as a managed
service by Digital Ocean. Instead, the RabbitMQ cluster-operator is used to deploy RabbitMQ to the cluster.

In the `kubernets/platform/production/rabbitmq` folder, run the following command to deploy the RabbitMQ cluster-operator:
```shell
./deploy.sh
```
(script courtesy of Thomas Vitale from their book _[Cloud Native Spring in Action](https://www.manning.com/books/cloud-native-spring-in-action)_)

The script creates a secret for the RabbitMQ credentials which are included by the `group-service` and `group-sync`
manifests.

### Deploying the Grafana Observability Stack
To enable observability in production using the Grafana Observability Stack, navigate to the 
`kubernetes/platform/production/observability` folder. Run the following command to deploy the Grafana Observability Stack:
```shell
./deploy.sh
```
(script courtesy of Thomas Vitale from their book _[Cloud Native Spring in Action](https://www.manning.com/books/cloud-native-spring-in-action)_)

Refer to the README.md file in that directory for more information on how to access the Grafana dashboard.

### Deploying and Syncing the Applications Using Argo CD
To deploy and sync the applications, we'll be using Argo CD, a GitOps tool for continuous deployments of applications in 
Kubernetes. You'll need to have the Argo CD CLI installed on your system. You can find instructions on how to install it
[here](https://argo-cd.readthedocs.io/en/stable/cli_installation/).

In the `kubernets/platform/production/argocd` folder, run the following command to deploy the ArgoCD application:
```shell
./deploy.sh
```
(script courtesy of Thomas Vitale from their book _[Cloud Native Spring in Action](https://www.manning.com/books/cloud-native-spring-in-action)_)

Get the password for logging into the ArgoCD production service by running the following command:
```shell
kubectl -n argocd get secret argocd-initial-admin-secret \
-o jsonpath="{.data.password}" | base64 -d; echo
```

Get the Argo CD production service's external IP address by running the following command:
```shell
kubectl -n argocd get service argocd-server
```

Log in to the Argo CD production service. using the following command (default username is `admin`):
```shell
argocd login <argocd-external-ip>
``` 

Next you'll need to configure Argo CD to sync each application repository.

The following command needs to be run for private repositories in order to give ArgoCD access to the repository:
```shell
argocd repo add <repo-link> \
--username <username> \
--password <password or access token with repo scope>
```
In total, you should be adding the following repositories:
- [Group Service](https://github.com/GroupHQ/group-service)
- [Group Sync](https://github.com/GroupHQ/group-sync)
- [Edge Service](https://github.com/GroupHQ/edge-service)
- [GroupHQ UI](https://github.com/GroupHQ/groupHQ-ui)
- [GroupHQ Deployment](https://github.com/GroupHQ/groupHQ-deployment)

Then, run the following command to instruct ArgoCD on how to sync the application to the cluster:
```shell
argocd app create <application-deployment-name, e.g. group-service> \
--repo <deployment-repo-link> \
--path <manifest-directory-path-to-monitor> \
--dest-server https://kubernetes.default.svc \
--dest-namespace default \
--sync-policy auto \
--auto-prune 
```

For example, to sync the group-service application, you would run the following command:
```shell
argocd app create group-service \
--repo https://github.com/GroupHQ/groupHQ-deployment \
--path kubernetes/applications/group-service/production \
--dest-server https://kubernetes.default.svc \
--dest-namespace default \
--sync-policy auto \
--auto-prune
```

This tells Arg CD that any changes made to the manifests in the `kubernetes/applications/group-service/production` 
folder should trigger a new application of the manifests to the cluster. These manifests are updated whenever a change
is made to the `main` branch of the `group-service` repository. A series of GitHub Actions then run to create the new 
service image, dispatch the updated image information to the GroupHQ Deployment repository, and update the image tags in 
the production manifests, committing the changes to the main branch. These changes are eventually picked up by Argo CD.

### Setting Up TLS/SSL Certificate for HTTPS/WSS Connections
In production, Let's Encrypt is used to automate the process of periodically providing free TLS certificates for the
`grouphq.org` domain.

First, the Let's Encrypt `ClusterIssuer` manifest needs a Digital Ocean API access token with read and write access
to interact with the Digital Ocean DNS API. Put that token in the `secrets/kubernets/production/lets-encrypt-do-dns.yml`
file. If you've never worked with the `secrets` folder, then it's probably named `secrets-checkReadMeInThisFolder`.
Follow the instructions in the README.md file in that folder before continuing.

After applying the secret to the cluster, go to the `kubernetes/platform/production/lets-encrypt` folder.
Run the following command to apply the `ClusterIssuer` manifest:
```shell
kubectl apply -k lets-encrypt-issuer.yml
```

Your NGINX controllers in the cluster should recognize the `ClusterIssuer` and integrate with it automatically.
In the `kubernetes/applications/edge-service/production/patch-ingress.yml` file, the `cert-manager` is specified: 
`cert-manager.io/cluster-issuer: letsencrypt-issuer`. This tells the NGINX controller to specifically use the
`letsencrypt-issuer` to generate a certificate for the `grouphq.org` domain.

### Deleting the Cluster and Backing Services

#### Deleting the Cluster
Delete the cluster with the following command:
```shell
doctl k8s cluster delete grouphq-cluster
```

#### Deleting the Backing Services
Delete the PostgreSQL database server with the following command:
```shell
doctl databases delete <postgres_id>
```

You can get the `postgres_id` by running the following command:
```shell
doctl databases list
```

Delete the Redis database server with the following command:
```shell
doctl databases delete <redis_id>
```

You can get the `redis_id` by running the following command:
```shell
doctl databases list
```