# GroupHQ
_GroupHQ is a demo application created as a training exercise for building and deploying reactive cloud-native applications
through the use of Spring Boot, Project Reactor, Docker, and Kubernetes, with an emphasis on cloud-native principles,
particularly based on the [15-factor app methodology](https://developer.ibm.com/articles/15-factor-applications/)_

## Table of Contents
- [Introduction](#introduction)
- [Edge Service](#edge-service)
- [Group Sync](#group-sync)
- [Group Service](#group-service)
- [Config Service and Kubernetes Patches](#config-service-and-kubernetes-patches)
- [Observability Stack](#observability-stack)
- [Docker](#docker)
- [Kubernetes](#kubernetes)
- [GroupHQ Architecture Diagram](#grouphq-architecture-diagram)

## Introduction

Version: DEMO

The GroupHQ Demo allows users to view, sync, join and leave auto-generated groups. While seemingly simple in nature,
the demo is backed by robust and extensible services for improving and adding onto the feature set. The system follows
a microservice architecture to decouple services and allows for independent development and deployment. The following
sections will go into detail about the architecture and the services that make up the GroupHQ Demo.

The following services are currently available:
- Edge Service
- Group Sync
- Group Service

Each service has been created with cloud-native principles in mind. They are independently deployable, scalable, and
resilient in case of downstream errors.

## Edge Service

The Edge Service is the entry point for all requests to the GroupHQ Demo. It is responsible for routing requests to
the appropriate service, as well as handling authentication and authorization*. The Edge Service is also responsible for
serving the frontend application (to be created).

Besides routing and authentication concerns, Edge Service also manages user sessions, rate-limiting, and resiliency
concerns through circuit breakers and timeouts. 

One interesting point to talk about is how authentication and authorization are handled in the GroupHQ Demo app.
Implementing a full user authentication and authorization system that is robust and secure is overkill for this demo app.
But we still want _some_ authentication that is good enough to prevent users from requesting members created by other users
to be removed from a group. To accomplish this, a "self-authenticating" strategy is used. The frontend application 
will generate a version 4 UUID (unique universal identifier) that is created using a CSPRNG (cryptographically secure 
pseudo-random number generator). This UUID will be sent with each request to Edge Service.
Any resources a user creates will be associated with this UUID, meaning that users won't be able to alter each other's
resources.

It's safe to say that a UUID is unique enough that another user won't be able to guess it. Of course, it can _technically_
be brute-forced by an attacker. As probability would have it, the more combinations generated, the higher the percent 
chance that you'll guess a valid user's UUID. Let's assume we have 100 million users. To get a 1% chance of guessing just
one of those UUIDs, you need to generate 3.4×10^28 UUIDs. That's a big number, but computers are fast, right?
Assuming we have a computer that can produce 10^12 (one trillion) UUIDs per second--which is a _very_ generous assumption--
how long would it take to just have a 1% chance of generating one UUID that matches one of the 100 million UUIDs?
1.1 billion years. I think it's safe to say it's unguessable (note, these numbers are from a conversation with
ChatGPT, so they may be off. which you can view [here](https://chat.openai.com/share/6a4041f3-9d94-4c38-8d18-1c10edc2dd1e))

However, a UUID is only as unguessable as the algorithm used to create it. If an algorithm is used that is not 
cryptographically secure, then it is possible to guess the UUID given that the user knows the algorithm used to create
it. For this reason, the UUID is created using a pseudo random number generator algorithm that is also cryptographically
secure. Given all this information, it is safe to say that the UUID generated by the client is feasibly unguessable.
The server can also generate the UUID when a user makes their initial request, and the generated UUID could be sent
back to the user. To keep things simple, we've opted for the client generating the UUID to avoid having to send the UUID 
back.

*Note: Authentication for RSocket connections is currently being handled by the Group Sync service. This will be
refactored in the future.

## Group Sync
One of the most important features of the GroupHQ system is to keep users in-sync with available groups and their details.
When a member joins or leaves a group, or when a group is created, deleted, or updated, then the user should receive an
update. To accomplish this, the Group Sync service uses RSocket to establish a persistent connection with the client.
The RSocket protocol is a protocol that integrates well with reactive applications, providing support for streaming
data and backpressure. It is a lightweight "wrapper" protocol that requires an underlying transport protocol, such as
TCP or WebSockets--Group Sync uses RSocket over WebSocket.

To get events, the client must first establish a connection with the Group Sync service through Edge Service. 
The client can then subscribe to RSocket endpoints on Group Sync. Two types of endpoints exist for receiving live events:
- Public updates: Events that are sent to all users containing information they need to keep in-sync with the server.
- User updates: Events sent to a specific user containing information on requests the user made.

Users can send requests to the Group Sync service through Edge Service for joining or leaving a group. On each request,
Group Sync sends the request info to Group Service via an event broker. Once received, Group Service will attempt to 
fulfill the request. Whether successful or not, Group Service will send an event detailing the results of the request
to Group Sync via an event broker. Group Sync takes these events and forwards them to the appropriate update stream:
- Public updates if the event was successful.
- User updates (whether the event was successful or not).

This allows users to receive updates on their requests, as well as updates on other users' requests.
Updates on user requests are more detailed compared to the same updates on public requests. For example, in a user join
event, a public update is sent to all users that a user joined a specific group. However, the user update will contain
additional information, such as the user's member ID.

Group Sync also provides a REST API for querying operations, which the client should send after establishing the update
streams. Requesting groups before establishing the update streams may result in some events being lost from the time
the groups were requested to the time the update streams were established.

## Group Service
The heart of the GroupHQ Demo. Group Service is responsible for managing groups and their members. It provides a REST
API for querying operations and an event-driven API for mutating operations. Using an event broker, Group Service
handles requests for several operations:
- Creating a group
- Updating a group
- Joining a group
- Leaving a group

While the first two operations work in Group Service, they are disabled in Group Sync through the use of feature flags.
Creating and updating groups is currently handled by the Group Demo Loader, a scheduled job that periodically creates
random groups and expires groups after a set time. The last two operations are enabled in Group Sync, allowing Group Service
to receive these request events and process them. For any operation, the request is made through service components that 
handle the request and create an event to publish to the event broker. These events are fanned out to users through Group Sync.

## Config Service and Kubernetes Patches
Config Service is responsible for providing applications with configuration information. It communicates with the configuration
repository to fetch version-controller configuration files. Files exist for each of the other services. While functional,
communicating with Config Service has been disabled in the other services. Instead, we make use of Kubernetes patches through
Kustomize to inject configuration into our services. The type of patches can vary depending on the environment.

To elaborate, each service repository has a `k8s` (short for Kubernetes) directory that contains the base configuration for the service
in a local Kubernetes development environment. In the `groupHQ-deployment` repository, there is a directory for each service,
and for each service, a different environment to run on. While we currently have staging and production defined, staging
still requires some work to be fully functional. Nevertheless, this strategy allows environment-specific configuration,
the same way Config Service would.

## Observability Stack
The GroupHQ Demo uses a variety of tools to provide observability into the system, all of which are integrated with
Grafana following the Grafana Observability Stack:
- Loki: Aggregates logs from services
- Prometheus: Collects metrics from services
- Tempo: Aggregates traces from services

Tools such as these are essential for monitoring and debugging applications. Without them, developers would have to 
resort to querying information on applications from the console, which is not practical, especially in a distributed 
environment. Tracing is a boon to developers, as it allows them to see the flow of requests through the system. This
is especially useful in a microservice architecture, where requests are routed through multiple services. Using the
Grafana Observability Stack, developers can view traces from logs and view critical application info at a glance
through custom dashboards.

Currently, Edge Service, Group Sync, and Group Service are all observable through the Grafana Observability Stack.

## Docker
In this repository a `docker` folder is included for local development without using Kubernetes. The most common use case
here is to run backing services, such as databases, for your applications running on your local machine to communicate with.
Using containerized backing services provides a more consistent, portable, and production-like environment for your applications.

## Kubernetes
When an application is ready to be deployed, the `kubernetes` folder is used. 

Notice the `applications/development` folder. It contains a `Tiltfile` to run the `Tiltfile`s in Edge Service, Group Sync, and 
Group Service. Each service's `Tiltfile` has instructions on deploying the application to your current Kubernetes context
based on the base manifest files located in the repository's `k8s` folder.

The rest of the `applications` folder contains overlays to customize each repositories base manifest files for different
environments. For example, the `applications/*/production` folder contains overlays for the production environment for 
a given service.

The `platform` folder contains all the backing services for the GroupHQ Demo in either development or production
environments. 

In the `development` folder, these include:
- PostgreSQL: A relational database for storing application data
- Redis: A key-value store for caching application data
- RabbitMQ: A message broker for sending events between services

In the `production` folder, these include:
- ArgoCD: A GitOps tool for deploying applications to Kubernetes
- ingress-nginx: A Kubernetes Ingress Controller for routing requests to services
- RabbitMQ: A message broker for sending events between services
- Grafana: A tool for visualizing metrics and logs
- Loki: A tool for aggregating logs
- Prometheus: A tool for collecting metrics
- Tempo: A tool for aggregating traces

The following is created through a Cloud Provider's managed services. These are services that are managed by the Cloud Provider
they are not deployed to Kubernetes:
- PostgreSQL: A relational database for storing application data
- Redis: A key-value store for caching application data

## GroupHQ Architecture Diagram
![structurizr-1-GroupHQ_Demo_Containers Alpha 0 1 1 1](https://github.com/GroupHQ/groupHQ-deployment/assets/88041024/df273f5d-a065-4555-8427-80b226185e6a)
