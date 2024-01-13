# GroupHQ
[GroupHQ](https://grouphq.org/) is a demo application created as a training exercise for building and deploying 
[reactive](https://en.wikipedia.org/wiki/Reactive_Streams) [cloud-native applications](https://aws.amazon.com/what-is/cloud-native/) 
through the use of [Spring Boot](https://www.ibm.com/topics/java-spring-boot), [Project Reactor](https://projectreactor.io/), 
[Docker](https://www.docker.com/), and [Kubernetes](https://kubernetes.io/), with an 
emphasis on cloud-native principles, particularly based on the [15-factor app methodology](https://developer.ibm.com/articles/15-factor-applications/)

The GroupHQ Demo allows users to view, sync, join and leave auto-generated groups. While seemingly simple in nature,
the demo is backed by robust and extensible services for improving and adding onto the feature set. The system is
designed as a set of microservices to enable decoupling of services, independent development and deployment, and
improved scalability compared to traditional monolithic applications.

## Repositories
The GroupHQ Demo comprises the following repositories:
1. [GroupHQ Deployment](https://github.com/GroupHQ/groupHQ-deployment): Contains deployment manifests
2. [Group Service](https://github.com/GroupHQ/group-service): Manages groups and their members
3. [Group Sync](https://github.com/GroupHQ/group-sync): Synchronizes groups between Group Service and end-users
4. [Edge Service](https://github.com/GroupHQ/edge-service): API gateway for handling cross-cutting concerns
5. [GroupHQ UI](https://github.com/GroupHQ/groupHQ-ui): Frontend application for viewing and joining groups
6. [Continuous Testing Test Suite](https://github.com/GroupHQ/grouphq-continuous-testing-test-suite): Test suite hosting
user-acceptance tests for the GroupHQ Demo
7. [Continuous Testing Proxy Server](https://github.com/GroupHQ/grouphq-continuous-testing-proxy-server): Proxy server
for integrating the GitHub API with [BuildWise](https://agileway.com.au/buildwise), a continuous testing server.